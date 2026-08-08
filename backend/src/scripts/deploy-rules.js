const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '../../serviceAccountKey.json'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

async function deployRules() {
  try {
    const rulesPath = path.join(__dirname, '../../../firestore.rules');
    const rulesContent = fs.readFileSync(rulesPath, 'utf8');

    const rules = admin.securityRules();
    const ruleSet = await rules.createRuleset({
      name: 'projects/odevtakipsistemi-b93b2',
      source: {
        files: [{
          name: 'firestore.rules',
          content: rulesContent
        }]
      }
    });

    await rules.releaseFirestoreRuleset(ruleSet.name);
    console.log(`✅ Firestore Güvenlik Kuralları başarıyla Firebase sunucusuna canlı dağıtıldı! (Ruleset: ${ruleSet.name})`);
    process.exit(0);
  } catch (err) {
    console.error('⚠️ Kurallar dağıtılırken hata:', err);
    process.exit(1);
  }
}

deployRules();
