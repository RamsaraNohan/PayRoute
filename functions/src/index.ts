import { app } from '@azure/functions';
import { generateToken } from './functions/generateToken';
import { processBoarding } from './functions/processBoarding';
import { signalDrop } from './functions/signalDrop';

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
