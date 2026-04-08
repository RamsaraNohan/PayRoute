import { HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { auth, db } from "../services/firebaseAdmin";

export async function generateToken(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { status: 401, jsonBody: { error: 'Unauthorized' } };
    }

    try {
        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await auth.verifyIdToken(idToken);
        const uid = decodedToken.uid;

        const body = await request.json() as any;
        const { destinationStopId, companionCount, passengerId } = body;

        // Create a token document
        const tokenRef = db.collection('tokens').doc();
        const tokenData = {
            id: tokenRef.id,
            passengerId: uid, // Use authenticated user
            destinationStopId: destinationStopId,
            companionCount: companionCount || 0,
            status: 'PENDING',
            createdAt: new Date().toISOString(),
        };

        await tokenRef.set(tokenData);

        return { status: 200, jsonBody: { tokenId: tokenRef.id } };
    } catch (error) {
        context.error(error);
        return { status: 500, jsonBody: { error: 'Internal server error' } };
    }
}
