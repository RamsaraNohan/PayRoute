
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'pyaroute'
  });
}

const db = admin.firestore();

async function listAll() {
  const collections = ['users', 'passengers', 'buses'];
  for (const col of collections) {
    console.log(`--- ${col} ---`);
    const snap = await db.collection(col).limit(5).get();
    snap.forEach(doc => {
      console.log(`ID: ${doc.id}`, doc.data());
    });
  }
}

listAll();
