
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // I'll check if this exists or use project ID

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'pyaroute'
  });
}

const db = admin.firestore();

async function findUser() {
  const snapshot = await db.collection('users').where('fullName', '>=', 'Jayakodi').where('fullName', '<=', 'Jayakodi\uf8ff').get();
  if (snapshot.empty) {
    console.log('No matching documents.');
    return;
  }
  
  snapshot.forEach(doc => {
    console.log('USER_ID:', doc.id, doc.data());
  });

  const pSnap = await db.collection('passengers').where('fullName', '>=', 'Jayakodi').where('fullName', '<=', 'Jayakodi\uf8ff').get();
  pSnap.forEach(doc => {
    console.log('PASSENGER_ID:', doc.id, doc.data());
  });
}

findUser();
