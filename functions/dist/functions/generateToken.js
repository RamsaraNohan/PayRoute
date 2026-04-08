"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateToken = generateToken;
const firebaseAdmin_1 = require("../services/firebaseAdmin");
async function generateToken(request, context) {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { status: 401, jsonBody: { error: 'Unauthorized' } };
    }
    try {
        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await firebaseAdmin_1.auth.verifyIdToken(idToken);
        const uid = decodedToken.uid;
        const body = await request.json();
        const { destinationStopId, companionCount, passengerId } = body;
        // Create a token document
        const tokenRef = firebaseAdmin_1.db.collection('tokens').doc();
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
    }
    catch (error) {
        context.error(error);
        return { status: 500, jsonBody: { error: 'Internal server error' } };
    }
}
//# sourceMappingURL=generateToken.js.map