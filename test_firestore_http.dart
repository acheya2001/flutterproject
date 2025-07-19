import 'dart:convert';
import 'dart:io';

/// 🧪 Test Firestore via API REST
void main() async {
  print('🧪 === TEST FIRESTORE VIA API REST ===');
  
  const projectId = 'assuranceaccident-2c2fa';
  const baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  
  final client = HttpClient();
  
  try {
    // Test 1: Lister les collections
    print('\n📋 Test 1: Vérification des collections');
    await testCollectionAccess(client, baseUrl, 'users');
    await testCollectionAccess(client, baseUrl, 'compagnies_assurance');
    await testCollectionAccess(client, baseUrl, 'agences');
    await testCollectionAccess(client, baseUrl, 'admin_notifications');
    
    // Test 2: Créer un document de test
    print('\n📝 Test 2: Création document test');
    await createTestDocument(client, baseUrl);
    
    // Test 3: Créer les admins
    print('\n👤 Test 3: Création admins compagnie');
    await createAdminCompagnies(client, baseUrl);
    
  } catch (e) {
    print('❌ Erreur générale: $e');
  } finally {
    client.close();
  }
  
  print('\n✅ === TEST TERMINÉ ===');
}

/// Test d'accès à une collection
Future<void> testCollectionAccess(HttpClient client, String baseUrl, String collection) async {
  try {
    final uri = Uri.parse('$baseUrl/$collection?pageSize=1');
    final request = await client.getUrl(uri);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      final documents = data['documents'] as List? ?? [];
      print('  ✅ $collection: ${documents.length} document(s) accessible(s)');
    } else {
      print('  ❌ $collection: Erreur ${response.statusCode}');
    }
  } catch (e) {
    print('  ❌ $collection: Exception - $e');
  }
}

/// Créer un document de test
Future<void> createTestDocument(HttpClient client, String baseUrl) async {
  try {
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse('$baseUrl/test_creation/$testId');
    
    final testData = {
      'fields': {
        'test': {'booleanValue': true},
        'created_at': {'timestampValue': '${DateTime.now().toUtc().toIso8601String()}Z'},
        'message': {'stringValue': 'Test de création via API REST'},
        'id': {'stringValue': testId},
      }
    };
    
    final request = await client.patchUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(testData));
    
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('  ✅ Document test créé: $testId');
      
      // Vérifier la lecture
      await Future.delayed(const Duration(milliseconds: 500));
      final getRequest = await client.getUrl(uri);
      final getResponse = await getRequest.close();
      
      if (getResponse.statusCode == 200) {
        print('  ✅ Document test lu avec succès');
        
        // Supprimer le document de test
        final deleteRequest = await client.deleteUrl(uri);
        final deleteResponse = await deleteRequest.close();
        
        if (deleteResponse.statusCode == 200) {
          print('  🧹 Document test supprimé');
        }
      } else {
        print('  ❌ Erreur lecture document test: ${getResponse.statusCode}');
      }
    } else {
      final responseBody = await response.transform(utf8.decoder).join();
      print('  ❌ Erreur création document test: ${response.statusCode}');
      print('  📄 Réponse: $responseBody');
    }
  } catch (e) {
    print('  ❌ Exception création document test: $e');
  }
}

/// Créer les admins compagnie
Future<void> createAdminCompagnies(HttpClient client, String baseUrl) async {
  final companies = [
    {'id': 'star-assurance', 'nom': 'STAR Assurance', 'email': 'admin.star@assurance.tn'},
    {'id': 'comar-assurance', 'nom': 'COMAR Assurance', 'email': 'admin.comar@assurance.tn'},
    {'id': 'gat-assurance', 'nom': 'GAT Assurance', 'email': 'admin.gat@assurance.tn'},
    {'id': 'maghrebia-assurance', 'nom': 'Maghrebia Assurance', 'email': 'admin.maghrebia@assurance.tn'},
  ];
  
  int created = 0;
  
  for (final company in companies) {
    try {
      final adminId = 'admin_${company['id']}_${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse('$baseUrl/users/$adminId');
      
      final adminData = {
        'fields': {
          'uid': {'stringValue': adminId},
          'email': {'stringValue': company['email']!},
          'nom': {'stringValue': 'Admin'},
          'prenom': {'stringValue': company['nom']!},
          'role': {'stringValue': 'admin_compagnie'},
          'status': {'stringValue': 'actif'},
          'compagnieId': {'stringValue': company['id']!},
          'compagnieNom': {'stringValue': company['nom']!},
          'created_at': {'timestampValue': '${DateTime.now().toUtc().toIso8601String()}Z'},
          'created_by': {'stringValue': 'test_http_script'},
          'source': {'stringValue': 'http_creation'},
          'isLegitimate': {'booleanValue': true},
        }
      };
      
      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(adminData));
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        print('  ✅ Admin créé: ${company['email']} (ID: $adminId)');
        created++;
      } else {
        final responseBody = await response.transform(utf8.decoder).join();
        print('  ❌ Erreur pour ${company['email']}: ${response.statusCode}');
        print('  📄 Réponse: $responseBody');
      }
      
      // Petite pause entre les créations
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      print('  ❌ Exception pour ${company['email']}: $e');
    }
  }
  
  print('  📊 Total créés: $created admin(s)');
  
  // Vérifier le résultat
  try {
    print('\n📊 Vérification finale:');
    final uri = Uri.parse('$baseUrl/users');
    final request = await client.getUrl(uri);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      final documents = data['documents'] as List? ?? [];
      print('  📋 Total documents dans users: ${documents.length}');
      
      int adminCount = 0;
      for (final doc in documents) {
        final fields = doc['fields'] as Map<String, dynamic>? ?? {};
        final role = fields['role']?['stringValue'] as String?;
        if (role == 'admin_compagnie') {
          adminCount++;
          final email = fields['email']?['stringValue'] as String? ?? 'N/A';
          final compagnie = fields['compagnieNom']?['stringValue'] as String? ?? 'N/A';
          print('    - $email ($compagnie)');
        }
      }
      print('  👥 Total admin_compagnie: $adminCount');
    } else {
      print('  ❌ Erreur vérification: ${response.statusCode}');
    }
  } catch (e) {
    print('  ❌ Exception vérification: $e');
  }
}
