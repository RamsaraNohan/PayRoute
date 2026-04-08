import { app } from '@azure/functions';
import { generateToken } from './functions/generateToken';
import { processBoarding } from './functions/processBoarding';
import { signalDrop } from './functions/signalDrop';
import { createPaymentSession } from './functions/createPaymentSession';
import { payhereNotify } from './functions/payhereNotify';

app.http('generateToken', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: generateToken
});

app.http('processBoarding', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: processBoarding
});

app.http('signalDrop', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: signalDrop
});

app.http('createPaymentSession', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: createPaymentSession
});

app.http('payhereNotify', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: payhereNotify
});
