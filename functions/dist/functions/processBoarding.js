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
        const decodedToken = await firebaseAdmin_1.auth.verifyIdToken(idToken);
        const callerUid = decodedToken.uid;
        const body = await request.json();
        const { tokenId, conductorId, busId, boardingLocation } = body;
        // Verify the authenticated user is the conductor making this request
        if (callerUid !== conductorId) {
            return { status: 403, jsonBody: { error: 'Forbidden: unauthorized access' } };
        }
        // Run within a transaction
        const result = await firebaseAdmin_1.db.runTransaction(async (t) => {
            const tokenRef = firebaseAdmin_1.db.collection('tokens').doc(tokenId);
            const tokenSnap = await t.get(tokenRef);
            if (!tokenSnap.exists)
                throw new Error('Token not found');
            const tokenData = tokenSnap.data();
            if (tokenData.status !== 'PENDING')
                throw new Error('Token already used or expired');
            // 1. Minimum Balance Check (100 LKR = 10000 cents)
            const passengerRef = firebaseAdmin_1.db.collection('passengers').doc(tokenData.passengerId);
            const passSnap = await t.get(passengerRef);
            if (!passSnap.exists)
                throw new Error('Passenger profile missing');
            const passData = passSnap.data();
            if (passData.walletBalance < 10000)
                throw new Error('Insufficient balance. Minimum 100 LKR required for boarding.');
            // 2. Identification of Boarding Stop (Search Route)
            const busSnap = await t.get(firebaseAdmin_1.db.collection('buses').doc(busId));
            if (!busSnap.exists)
                throw new Error('Bus not found');
            const busData = busSnap.data();
            const routeSnap = await t.get(firebaseAdmin_1.db.collection('routes').doc(busData.routeId));
            if (!routeSnap.exists)
                throw new Error('Route profile missing');
            const routeData = routeSnap.data();
            let boardingStopName = 'Unknown Stop';
            if (boardingLocation && routeData.stops) {
                // Find nearest stop within 500m using Haversine distance
                const stops = routeData.stops;
                let minDistanceKm = 0.5; // 500m threshold
                for (const stop of stops) {
                    const lat1 = boardingLocation.latitude * Math.PI / 180;
                    const lat2 = stop.location.latitude * Math.PI / 180;
                    const dLat = (stop.location.latitude - boardingLocation.latitude) * Math.PI / 180;
                    const dLon = (stop.location.longitude - boardingLocation.longitude) * Math.PI / 180;
                    const a = Math.sin(dLat / 2) ** 2 +
                        Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
                    const distKm = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                    if (distKm < minDistanceKm) {
                        boardingStopName = stop.stopName;
                        minDistanceKm = distKm;
                    }
                }
            }
            // Mark token as active
            t.update(tokenRef, { status: 'ACTIVE', boardedAt: new Date().toISOString(), busId });
            // Create an active trip
            const tripRef = firebaseAdmin_1.db.collection('trips').doc();
            t.set(tripRef, {
                id: tripRef.id,
                passengerId: tokenData.passengerId,
                tokenId: tokenId,
                busId: busId,
                conductorId: conductorId,
                status: 'ONGOING',
                boardingTime: new Date().toISOString(),
                boardingStopName: boardingStopName,
                boardingLocation: boardingLocation || null,
                destinationStopId: tokenData.destinationStopId,
                companionCount: tokenData.companionCount || 1,
                fareBase: routeData.baseFareCents || 4500
            });
            return {
                seatNumber: Math.floor(Math.random() * 40) + 1,
                fareBaseCents: routeData.baseFareCents || 4500,
                boardingStopName: boardingStopName,
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