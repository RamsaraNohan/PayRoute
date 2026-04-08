
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'pyaroute'
  });
}

const auth = admin.auth();
const db = admin.firestore();

async function setup() {
  try {
    const user = await auth.createUser({
      email: 'admin@payroute.com',
      password: 'adminPassword123',
      displayName: 'System Admin'
    });
    
    await db.collection('users').doc(user.uid).set({
      userId: user.uid,
      email: 'admin@payroute.com',
      fullName: 'System Admin',
      roles: ['admin'],
      profileCompleted: true,
      accountStatus: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Successfully created admin user:', user.uid);
  } catch (e) {
    if (e.code === 'auth/email-already-exists') {
        console.log('Admin user already exists.');
    } else {
        console.error('Error creating admin:', e);
    }
  }
}

setup();
