"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.signalDrop = signalDrop;
const firebaseAdmin_1 = require("../services/firebaseAdmin");
async function signalDrop(request, context) {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { status: 401, jsonBody: { error: 'Unauthorized' } };
    }
    try {
        const idToken = authHeader.split('Bearer ')[1];
        await firebaseAdmin_1.auth.verifyIdToken(idToken); // Passenger authorization check
        const body = await request.json();
        const { tripId } = body;
        await firebaseAdmin_1.db.runTransaction(async (t) => {
            const tripRef = firebaseAdmin_1.db.collection('trips').doc(tripId);
            const tripSnap = await t.get(tripRef);
            if (!tripSnap.exists) {
                throw new Error('Trip not found');
            }
            const tripData = tripSnap.data();
            if (tripData.status !== 'ONGOING') {
                throw new Error('Trip already completed');
            }
            // Deduct fare logic here (omitted for mock)
            // Example:
            // const cost = 4500;
            // update Passenger Wallet logic
            t.update(tripRef, {
                status: 'COMPLETED',
                dropTime: new Date().toISOString()
            });
            const tokenRef = firebaseAdmin_1.db.collection('tokens').doc(tripData.tokenId);
            t.update(tokenRef, { status: 'COMPLETED' });
        });
        return { status: 200, jsonBody: { success: true } };
    }
    catch (error) {
        context.error(error);
        return { status: 400, jsonBody: { error: error.message || 'Internal server error' } };
    }
}
//# sourceMappingURL=signalDrop.js.map