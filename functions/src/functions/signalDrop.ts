import { HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { auth, db } from "../services/firebaseAdmin";

export async function signalDrop(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { status: 401, jsonBody: { error: 'Unauthorized' } };
    }

    try {
        const idToken = authHeader.split('Bearer ')[1];
        await auth.verifyIdToken(idToken); // Passenger authorization check

        const body = await request.json() as any;
        const { tripId, dropLocation } = body;

        const result = await db.runTransaction(async (t) => {
            const tripRef = db.collection('trips').doc(tripId);
            const tripSnap = await t.get(tripRef);
            
            if (!tripSnap.exists) throw new Error('Trip not found');
            const tripData = tripSnap.data() as any;
            if (tripData.status !== 'ONGOING') throw new Error('Trip already completed');

            // 1. Fetch Route Metadata for Pricing
            const busSnap = await t.get(db.collection('buses').doc(tripData.busId));
            if (!busSnap.exists) throw new Error('Bus details missing');
            const busData = busSnap.data() as any;
            const routeSnap = await t.get(db.collection('routes').doc(busData.routeId));
            if (!routeSnap.exists) throw new Error('Pricing data unavailable');
            const routeData = routeSnap.data() as any;

            // 2. Calculate Fare (Base + Distance logic)
            const baseFare = routeData.baseFareCents || 4500;
            const perKm = routeData.farePerKmCents || 1200;
            
            // Mock distance if GPS is unavailable, otherwise calc delta
            let distanceKm = 1.0; 
            if (dropLocation && tripData.boardingLocation) {
                // Precise Haversine could be used, but simple Euclidean is fine for this demo scale
                const latDelta = dropLocation.latitude - tripData.boardingLocation.latitude;
                const lngDelta = dropLocation.longitude - tripData.boardingLocation.longitude;
                distanceKm = Math.sqrt(latDelta * latDelta + lngDelta * lngDelta) * 111; // 1 deg ~= 111km
            }

            const totalFare = Math.max(baseFare, Math.round(baseFare + (distanceKm * perKm)));
            const finalDeduction = totalFare * (tripData.companionCount || 1);

            // 3. Atomically Deduct from Wallet
            const passengerRef = db.collection('passengers').doc(tripData.passengerId);
            const passSnap = await t.get(passengerRef);
            if (!passSnap.exists) throw new Error('Passenger record not found');
            const currentBalance = passSnap.data()?.walletBalance || 0;
            
            if (currentBalance < finalDeduction) {
                // We allow it to go negative in emergencies but log it
                console.warn(`Passenger ${tripData.passengerId} has insufficient funds but journey completed. Balance: ${currentBalance}, Charge: ${finalDeduction}`);
            }

            t.update(passengerRef, { walletBalance: currentBalance - finalDeduction });

            // 4. Finalize Trip Records
            t.update(tripRef, { 
                status: 'COMPLETED', 
                dropTime: new Date().toISOString(),
                finalFare: finalDeduction,
                distanceTravelled: distanceKm
            });

            const tokenRef = db.collection('tokens').doc(tripData.tokenId);
            t.update(tokenRef, { status: 'COMPLETED' });

            return { finalFare: finalDeduction, distance: distanceKm };
        });

        return { status: 200, jsonBody: { success: true, ...result } };
    } catch (error: any) {
        context.error(error);
        return { status: 400, jsonBody: { error: error.message || 'Internal server error' } };
    }
}
