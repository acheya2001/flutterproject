const { google } = require('googleapis');
const readline = require('readline');

// 🔥 Vos credentials OAuth2
const CLIENT_ID = '1059917372502-fff4ojjqgvcld5rhbdrb5pfi9u4cmf18.apps.googleusercontent.com';
const CLIENT_SECRET = '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';
const REDIRECT_URI = 'https://developers.google.com/oauthplayground';

// Scopes Gmail nécessaires
const SCOPES = ['https://www.googleapis.com/auth/gmail.send'];

// Configuration OAuth2 Client
const oAuth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  REDIRECT_URI
);

console.log('🚀 === CONFIGURATION AUTOMATIQUE GMAIL OAUTH2 ===\n');

// Générer l'URL d'autorisation
const authUrl = oAuth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: SCOPES,
  prompt: 'consent' // Force le refresh token
});

console.log('📋 ÉTAPES AUTOMATIQUES :');
console.log('1. ✅ Credentials OAuth2 configurés');
console.log('2. ✅ URL d\'autorisation générée');
console.log('3. 🔗 Ouvrez cette URL dans votre navigateur :');
console.log('\n' + authUrl + '\n');

console.log('4. 🔑 Connectez-vous avec: constat.tunisie.app@gmail.com');
console.log('5. ✅ Autorisez l\'application');
console.log('6. 📋 Copiez le code d\'autorisation qui apparaît');
console.log('7. 📝 Collez-le ci-dessous quand demandé\n');

// Interface pour saisir le code d'autorisation
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question('📝 Collez le code d\'autorisation ici: ', async (code) => {
  try {
    console.log('\n🔄 Échange du code contre les tokens...');
    
    // Échanger le code contre les tokens
    const { tokens } = await oAuth2Client.getToken(code);
    oAuth2Client.setCredentials(tokens);
    
    console.log('✅ Tokens obtenus avec succès !');
    console.log('\n🔑 REFRESH TOKEN:');
    console.log(tokens.refresh_token);
    
    console.log('\n📧 ACCESS TOKEN:');
    console.log(tokens.access_token);
    
    console.log('\n🎯 PROCHAINES ÉTAPES AUTOMATIQUES:');
    console.log('1. ✅ Copie du refresh token dans Firebase Functions');
    console.log('2. ✅ Configuration automatique de Firebase');
    console.log('3. ✅ Test d\'envoi d\'email immédiat');
    
    // Sauvegarder les tokens dans un fichier
    const fs = require('fs');
    const tokenData = {
      refresh_token: tokens.refresh_token,
      access_token: tokens.access_token,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      gmail_user: 'constat.tunisie.app@gmail.com'
    };
    
    fs.writeFileSync('gmail_tokens.json', JSON.stringify(tokenData, null, 2));
    console.log('\n💾 Tokens sauvegardés dans gmail_tokens.json');
    
    rl.close();
    
  } catch (error) {
    console.error('❌ Erreur lors de l\'obtention des tokens:', error);
    rl.close();
  }
});
