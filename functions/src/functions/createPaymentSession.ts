import { HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { auth, db } from "../services/firebaseAdmin";
import * as crypto from "crypto";
import { v4 as uuidv4 } from "uuid";

const MERCHANT_ID = process.env["PAYHERE_MERCHANT_ID"] ?? "1230268";
const MERCHANT_SECRET = process.env["PAYHERE_MERCHANT_SECRET"] ?? "";
// Default to sandbox mode when running without a real merchant secret.
const IS_SANDBOX = !MERCHANT_SECRET || process.env["PAYHERE_SANDBOX"] !== "false";

// Note: MD5 is required by the PayHere payment gateway specification for hash
// generation and signature verification (https://support.payhere.lk/api-&-mobile-sdk/payhere-checkout).
// The use of MD5 here is not a security choice — it is a mandatory API contract.
function buildPayHereHash(orderId: string, amountStr: string, currency: string, merchantSecret: string): string {
    // lgtm[js/weak-cryptographic-algorithm] - MD5 mandated by PayHere payment gateway API spec
    // nosemgrep: javascript.lang.security.audit.node-md5.node-md5
    // lgtm[js/weak-cryptographic-algorithm] - MD5 mandated by PayHere payment gateway API spec
    const merchantSecretHash = crypto
        .createHash("md5")
        .update(merchantSecret)
        .digest("hex")
        .toUpperCase();
    // lgtm[js/weak-cryptographic-algorithm] - MD5 mandated by PayHere payment gateway API spec
    return crypto
        .createHash("md5")
        .update(MERCHANT_ID + orderId + amountStr + currency + merchantSecretHash)
        .digest("hex")
        .toUpperCase();
}

export async function createPaymentSession(
    request: HttpRequest,
    context: InvocationContext
): Promise<HttpResponseInit> {
    const authHeader = request.headers.get("authorization");
    if (!authHeader?.startsWith("Bearer ")) {
        return { status: 401, jsonBody: { error: "Unauthorized" } };
    }

    if (!MERCHANT_ID) {
        return { status: 503, jsonBody: { error: "Payment gateway not configured: PAYHERE_MERCHANT_ID missing" } };
    }

    // When MERCHANT_SECRET is not set we operate in sandbox mode with a dummy hash.
    // Set PAYHERE_MERCHANT_SECRET in Azure app settings for real (live) payments.
    const effectiveSecret = MERCHANT_SECRET || "sandbox-not-configured";

    try {
        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await auth.verifyIdToken(idToken);
        const callerUid = decodedToken.uid;

        const body = await request.json() as any;
        const { amountCents } = body;

        if (!amountCents || typeof amountCents !== "number" || amountCents < 10000) {
            return { status: 400, jsonBody: { error: "Minimum top-up is LKR 100" } };
        }

        // Fetch passenger details for the checkout form
        const userSnap = await db.collection("users").doc(callerUid).get();
        const userData = userSnap.data() ?? {};

        // Find the passenger doc to get name/phone
        const passSnap = await db.collection("passengers")
            .where("userId", "==", callerUid).limit(1).get();
        const passData = passSnap.empty ? {} : passSnap.docs[0].data();

        const orderId = `WALLET-${uuidv4().replace(/-/g, "").substring(0, 12).toUpperCase()}`;
        const amountLKR = (amountCents / 100).toFixed(2);
        const currency = "LKR";
        const hash = buildPayHereHash(orderId, amountLKR, currency, effectiveSecret);

        // Store a pending payment record to verify against on notify
        await db.collection("pendingPayments").doc(orderId).set({
            orderId,
            userId: callerUid,
            passengerId: passData.passengerId ?? callerUid,
            amountCents,
            currency,
            status: "PENDING",
            createdAt: new Date().toISOString(),
        });

        const notifyBaseUrl = process.env["AZURE_FUNCTION_BASE_URL"]
            ?? "https://payroute-functions-ajcgebh7a2axe3cw.southeastasia-01.azurewebsites.net/api";

        return {
            status: 200,
            jsonBody: {
                merchantId: MERCHANT_ID,
                orderId,
                amountLKR,
                currency,
                hash,
                isSandbox: IS_SANDBOX,
                notifyUrl: `${notifyBaseUrl}/payhereNotify`,
                firstName: (passData.fullName as string | undefined)?.split(" ")[0] ?? "Customer",
                lastName: (passData.fullName as string | undefined)?.split(" ").slice(1).join(" ") ?? "",
                phone: userData.phone ?? "",
            },
        };
    } catch (error: any) {
        context.error(error);
        return { status: 500, jsonBody: { error: "Internal server error" } };
    }
}
