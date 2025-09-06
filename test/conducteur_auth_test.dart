import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/services/conducteur_auth_service.dart';

// Mocks pour Firebase Auth et Firestore
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  // Initialisation de Firebase pour les tests
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('ConducteurAuthService Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnapshot;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockDocRef = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();

      // Configuration des mocks
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');

      when(mockFirestore.collection('conducteurs')).thenReturn(mockDocRef);
      when(mockDocRef.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async => Future.value());
    });

    test('registerConducteur should return success on valid input', () async {
      // Arrange
      final authService = ConducteurAuthService();

      // Act
      final result = await authService.registerConducteur(
        nom: 'Test',
        prenom: 'User',
        cin: '12345678',
        telephone: '+21612345678',
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result['success'], true);
      expect(result['userId'], 'test_user_id');
    });

    test('loginConducteur should return success on valid credentials', () async {
      // Arrange
      final authService = ConducteurAuthService();

      // Mock de la connexion réussie
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock du document conducteur existant
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn({
        'status': 'active',
        'nom': 'Test',
        'prenom': 'User',
      });

      // Act
      final result = await authService.loginConducteur(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result['success'], true);
      expect(result['userId'], 'test_user_id');
    });

    test('loginConducteur should fail on pending account', () async {
      // Arrange
      final authService = ConducteurAuthService();

      // Mock de la connexion réussie
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock du document conducteur en attente
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn({
        'status': 'pending',
        'nom': 'Test',
        'prenom': 'User',
      });

      // Act
      final result = await authService.loginConducteur(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result['success'], false);
      expect(result['error'], contains('en attente de validation'));
    });

    test('getConducteurData should return null for non-existent user', () async {
      // Arrange
      final authService = ConducteurAuthService();

      // Mock du document non existant
      when(mockDocSnapshot.exists).thenReturn(false);

      // Act
      final result = await authService.getConducteurData('non_existent_user');

      // Assert
      expect(result, isNull);
    });
  });
}
