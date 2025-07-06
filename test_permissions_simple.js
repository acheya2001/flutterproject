// Test simple des permissions Firestore
const admin = require('firebase-admin');

// Initialiser Firebase Admin
const serviceAccount = require('./path/to/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testPermissions() {
  console.log('🧪 Test des permissions Firestore...');
  
  try {
    // Test 1: Créer une demande de compte professionnel
    console.log('\n📝 Test 1: Création demande...');
    const requestRef = await db.collection('professional_account_requests').add({
      userId: 'test_user_id',
      email: 'test@example.com',
      nom: 'Test',
      prenom: 'User',
      telephone: '12345678',
      userType: 'assureur',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('✅ Demande créée:', requestRef.id);
    
    // Test 2: Lire les statistiques
    console.log('\n📊 Test 2: Lecture statistiques...');
    
    const usersCount = await db.collection('users').get();
    console.log('✅ Users count:', usersCount.size);
    
    const requestsCount = await db.collection('professional_account_requests').get();
    console.log('✅ Requests count:', requestsCount.size);
    
    // Test 3: Nettoyer
    console.log('\n🧹 Test 3: Nettoyage...');
    await requestRef.delete();
    console.log('✅ Demande supprimée');
    
    console.log('\n🎯 Tous les tests réussis !');
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  }
  
  process.exit(0);
}

testPermissions();
