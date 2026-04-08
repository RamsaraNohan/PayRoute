"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.auth = exports.fcm = exports.db = void 0;
const admin = require("firebase-admin");
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.applicationDefault()
    });
}
exports.db = admin.firestore();
exports.fcm = admin.messaging();
exports.auth = admin.auth();
//# sourceMappingURL=firebaseAdmin.js.map