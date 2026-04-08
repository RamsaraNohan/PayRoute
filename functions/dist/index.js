"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const functions_1 = require("@azure/functions");
const generateToken_1 = require("./functions/generateToken");
const processBoarding_1 = require("./functions/processBoarding");
const signalDrop_1 = require("./functions/signalDrop");
functions_1.app.http('generateToken', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: generateToken_1.generateToken
});
functions_1.app.http('processBoarding', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: processBoarding_1.processBoarding
});
functions_1.app.http('signalDrop', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: signalDrop_1.signalDrop
});
//# sourceMappingURL=index.js.map