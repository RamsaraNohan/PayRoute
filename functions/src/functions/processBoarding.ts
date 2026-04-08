import { HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { auth, db } from "../services/firebaseAdmin";

export async function processBoarding(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { status: 401, jsonBody: { error: 'Unauthorized' } };
    }

    try {
        const idToken = authHeader.split('Bearer ')[1];
        await auth.verifyIdToken(idToken); // Conductor authorization check

        const body = await request.json() as any;
        const { tokenId, conductorId, busId, boardingLocation } = body;

        // Run within a transaction
        const result = await db.runTransaction(async (t) => {
            const tokenRef = db.collection('tokens').doc(tokenId);
            const tokenSnap = await t.get(tokenRef);
            
            if (!tokenSnap.exists) throw new Error('Token not found');
            const tokenData = tokenSnap.data() as any;
            if (tokenData.status !== 'PENDING') throw new Error('Token already used or expired');

            // 1. Minimum Balance Check (100 LKR = 10000 cents)
            const passengerRef = db.collection('passengers').doc(tokenData.passengerId);
            const passSnap = await t.get(passengerRef);
            if (!passSnap.exists) throw new Error('Passenger profile missing');
            const passData = passSnap.data() as any;
            if (passData.walletBalance < 10000) throw new Error('Insufficient balance. Minimum 100 LKR required for boarding.');

            // 2. Identification of Boarding Stop (Search Route)
            const busSnap = await t.get(db.collection('buses').doc(busId));
            if (!busSnap.exists) throw new Error('Bus not found');
            const busData = busSnap.data() as any;
            const routeSnap = await t.get(db.collection('routes').doc(busData.routeId));
            if (!routeSnap.exists) throw new Error('Route profile missing');
            const routeData = routeSnap.data() as any;

            let boardingStopName = 'Unknown Stop';
            if (boardingLocation && routeData.stops) {
                // Find nearest stop within 500m
                const stops = routeData.stops as any[];
                let minDistance = 0.5 / 111; // Approx conversion for 500m in degrees for rough check
                for (const stop of stops) {
                    const dist = Math.sqrt(
                        Math.pow(stop.location.latitude - boardingLocation.latitude, 2) + 
                        Math.pow(stop.location.longitude - boardingLocation.longitude, 2)
                    );
                    if (dist < minDistance) {
                        boardingStopName = stop.stopName;
                        minDistance = dist;
                    }
                }
            }

            // Mark token as active
            t.update(tokenRef, { status: 'ACTIVE', boardedAt: new Date().toISOString(), busId });

            // Create an active trip
            const tripRef = db.collection('trips').doc();
            t.set(tripRef, {
                id: tripRef.id,
                passengerId: tokenData.passengerId,
                tokenId: tokenId,
                busId: busId,
                conductorId: conductorId,
                status: 'ONGOING',
                boardingTime: new Date().toISOString(),
                boardingStopName: boardingStopName,
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
    } catch (error: any) {
        context.error(error);
        return { status: 400, jsonBody: { error: error.message || 'Internal server error' } };
    }
}
