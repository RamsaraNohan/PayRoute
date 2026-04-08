import { HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { db, fcm } from "../services/firebaseAdmin";
import * as crypto from "crypto";

const MERCHANT_ID = process.env["PAYHERE_MERCHANT_ID"] ?? "";
const MERCHANT_SECRET = process.env["PAYHERE_MERCHANT_SECRET"] ?? "";

// Note: MD5 is required by the PayHere payment gateway specification for HMAC verification
// (https://support.payhere.lk/api-&-mobile-sdk/payhere-checkout). This is a mandatory API contract.
function verifyPayHereNotify(params: Record<string, string>): boolean {
    const { merchant_id, order_id, payhere_amount, payhere_currency, status_code, md5sig } = params;
    if (!merchant_id || !order_id || !payhere_amount || !payhere_currency || !status_code || !md5sig) {
        return false;
    }
    // nosemgrep: javascript.lang.security.audit.node-md5.node-md5
    const secretHash = crypto.createHash("md5").update(MERCHANT_SECRET).digest("hex").toUpperCase();
    const localSig = crypto
        .createHash("md5")
        .update(merchant_id + order_id + payhere_amount + payhere_currency + status_code + secretHash)
        .digest("hex")
        .toUpperCase();
    return localSig === md5sig.toUpperCase();
}

export async function payhereNotify(
    request: HttpRequest,
    context: InvocationContext
): Promise<HttpResponseInit> {
    if (!MERCHANT_ID || !MERCHANT_SECRET) {
        return { status: 503 };
    }

    try {
        // PayHere sends URL-encoded form data — use URLSearchParams for robust parsing
        const bodyText = await request.text();
        const urlParams = new URLSearchParams(bodyText);
        const params: Record<string, string> = {};
        urlParams.forEach((value, key) => { params[key] = value; });

        context.log("PayHere notify params:", JSON.stringify(params));

        // Verify HMAC signature
        if (!verifyPayHereNotify(params)) {
            context.warn("PayHere notify: invalid signature");
            return { status: 400, body: "Invalid signature" };
        }

        const { order_id, status_code, merchant_id } = params;

        if (merchant_id !== MERCHANT_ID) {
            context.warn("PayHere notify: merchant ID mismatch");
            return { status: 400, body: "Invalid merchant" };
        }

        // Fetch the pending payment record
        const paymentRef = db.collection("pendingPayments").doc(order_id);
        const paymentSnap = await paymentRef.get();
        if (!paymentSnap.exists) {
            context.warn(`PayHere notify: order ${order_id} not found`);
            return { status: 200 }; // Return 200 so PayHere doesn't retry
        }

        const paymentData = paymentSnap.data()!;

        // status_code 2 = success, 0 = pending, -1 = cancelled, -2 = failed, -3 = chargedback
        if (status_code === "2" && paymentData.status === "PENDING") {
            // Credit the wallet atomically
            await db.runTransaction(async (t) => {
                const passRef = db.collection("passengers").doc(paymentData.passengerId as string);
                const passSnap = await t.get(passRef);
                if (!passSnap.exists) throw new Error("Passenger not found");
                const currentBalance = (passSnap.data()?.walletBalance as number) ?? 0;
                t.update(passRef, { walletBalance: currentBalance + (paymentData.amountCents as number) });
                t.update(paymentRef, {
                    status: "COMPLETED",
                    completedAt: new Date().toISOString(),
                    payhereOrderId: order_id,
                });
            });

            // Log audit entry
            await db.collection("auditLogs").add({
                userId: paymentData.userId,
                action: "TOP_UP",
                data: { amountCents: paymentData.amountCents, orderId: order_id, gateway: "PayHere" },
                timestamp: new Date(),
            });

            // Send FCM notification (non-blocking)
            _sendTopUpNotification(paymentData.userId as string, paymentData.amountCents as number).catch(() => {});
        } else {
            await paymentRef.update({
                status: status_code === "2" ? "COMPLETED" : "FAILED",
                statusCode: status_code,
                updatedAt: new Date().toISOString(),
            });
        }

        return { status: 200, body: "OK" };
    } catch (error: any) {
        context.error(error);
        // Return 200 anyway to prevent PayHere from retrying with a broken order
        return { status: 200, body: "Error handled" };
    }
}

async function _sendTopUpNotification(userId: string, amountCents: number): Promise<void> {
    const userSnap = await db.collection("users").doc(userId).get();
    const fcmToken = userSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return;
    await fcm.send({
        token: fcmToken,
        notification: {
            title: "💳 Wallet Topped Up",
            body: `LKR ${(amountCents / 100).toFixed(2)} has been added to your PayRoute wallet.`,
        },
        data: { type: "TOP_UP", amount: String(amountCents) },
    });
}
