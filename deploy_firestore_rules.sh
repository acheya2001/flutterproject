#!/bin/bash

echo "========================================"
echo "   DÉPLOIEMENT DES RÈGLES FIRESTORE"
echo "========================================"
echo

echo "🔥 Déploiement des nouvelles règles Firestore..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo
    echo "✅ SUCCÈS: Les règles Firestore ont été déployées avec succès !"
    echo
    echo "📋 Nouvelles collections supportées:"
    echo "   - professional_account_requests"
    echo "   - notifications"
    echo "   - users (avec nouveaux champs)"
    echo
    echo "🔐 Nouvelles fonctionnalités de sécurité:"
    echo "   - Validation des statuts de compte"
    echo "   - Permissions granulaires"
    echo "   - Contrôle d'accès basé sur les rôles"
    echo
    echo "🚀 Votre application peut maintenant:"
    echo "   - Créer des demandes de comptes professionnels"
    echo "   - Gérer les notifications"
    echo "   - Valider les comptes par les admins"
    echo
else
    echo
    echo "❌ ERREUR: Échec du déploiement des règles Firestore"
    echo
    echo "🔧 Solutions possibles:"
    echo "   1. Vérifiez que Firebase CLI est installé"
    echo "   2. Connectez-vous avec: firebase login"
    echo "   3. Initialisez le projet avec: firebase init"
    echo "   4. Vérifiez la syntaxe du fichier firestore.rules"
    echo
fi

echo
read -p "Appuyez sur Entrée pour continuer..."
