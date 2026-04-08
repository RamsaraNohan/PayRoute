"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processBoarding = processBoarding;
const firebaseAdmin_1 = require("../services/firebaseAdmin");
async function processBoarding(request, context) {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { status: 401, jsonBody: { error: 'Unauthorized' } };
    }
    try {
        const idToken = authHeader.split('Bearer ')[1];
        await firebaseAdmin_1.auth.verifyIdToken(idToken); // Conductor authorization check
        const body = await request.json();
        const { tokenId, conductorId, busId } = body;
        // Run within a transaction
        const result = await firebaseAdmin_1.db.runTransaction(async (t) => {
            const tokenRef = firebaseAdmin_1.db.collection('tokens').doc(tokenId);
            const tokenSnap = await t.get(tokenRef);
            if (!tokenSnap.exists) {
                throw new Error('Token not found');
            }
            const data = tokenSnap.data();
            if (data.status !== 'PENDING') {
                throw new Error('Token already used or expired');
            }
            // Mark token as active
            t.update(tokenRef, { status: 'ACTIVE', boardedAt: new Date().toISOString(), busId });
            // Create an active trip
            const tripRef = firebaseAdmin_1.db.collection('trips').doc();
            t.set(tripRef, {
                id: tripRef.id,
                passengerId: data.passengerId,
                tokenId: tokenId,
                busId: busId,
                conductorId: conductorId,
                status: 'ONGOING',
                boardingTime: new Date().toISOString(),
                destinationStopId: data.destinationStopId,
                companionCount: data.companionCount
            });
            return {
                seatNumber: Math.floor(Math.random() * 40) + 1, // Mock seat assignment
                fareCents: 4500, // Mock fare base
                boardingStopName: 'Unknown Stop',
                tripId: tripRef.id
            };
        });
        return { status: 200, jsonBody: { success: true, ...result } };
    }
    catch (error) {
        context.error(error);
        return { status: 400, jsonBody: { error: error.message || 'Internal server error' } };
    }
}
//# sourceMappingURL=processBoarding.js.map