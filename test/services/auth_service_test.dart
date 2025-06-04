import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:product_list_app/services/auth_service.dart';

@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  User,
  UserCredential,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  http.Client,
])
import 'auth_service_test.mocks.dart';

void main() {
  group('Pruebas de AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockGoogleSignInAccount mockGoogleSignInAccount;
    late MockGoogleSignInAuthentication mockGoogleSignInAuthentication;
    late MockClient mockHttpClient;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockGoogleSignInAccount = MockGoogleSignInAccount();
      mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
      mockHttpClient = MockClient();

      SharedPreferences.setMockInitialValues({});

      authService = AuthService(
        auth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
        httpClient: mockHttpClient,
      );
    });

    group('Inicio de sesión con Google', () {
      test(
        'debería retornar el usuario cuando el inicio de sesión con Google es exitoso',
        () async {
          when(
            mockGoogleSignIn.signIn(),
          ).thenAnswer((_) async => mockGoogleSignInAccount);
          when(
            mockGoogleSignInAccount.authentication,
          ).thenAnswer((_) async => mockGoogleSignInAuthentication);
          when(
            mockGoogleSignInAuthentication.accessToken,
          ).thenReturn('access_token_123');
          when(
            mockGoogleSignInAuthentication.idToken,
          ).thenReturn('id_token_123');
          when(
            mockFirebaseAuth.signInWithCredential(any),
          ).thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);

          final result = await authService.signInWithGoogle();

          expect(result, equals(mockUser));
          verify(mockGoogleSignIn.signIn()).called(1);
          verify(mockFirebaseAuth.signInWithCredential(any)).called(1);
        },
      );

      test(
        'debería retornar null cuando el usuario cancela el inicio de sesión con Google',
        () async {
          when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);
          final result = await authService.signInWithGoogle();

          expect(result, isNull);
          verify(mockGoogleSignIn.signIn()).called(1);
          verifyNever(mockFirebaseAuth.signInWithCredential(any));
        },
      );

      test(
        'debería manejar errores durante el proceso de autenticación con Google',
        () async {
          when(
            mockGoogleSignIn.signIn(),
          ).thenAnswer((_) async => mockGoogleSignInAccount);
          when(
            mockGoogleSignInAccount.authentication,
          ).thenThrow(Exception('Error de autenticación'));

          expect(
            () async => await authService.signInWithGoogle(),
            throwsException,
          );
        },
      );
    });

    group('Cerrar sesión', () {
      test('debería llamar signOut en Google y Firebase', () async {
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        await authService.signOut();

        verify(mockGoogleSignIn.signOut()).called(1);
        verify(mockFirebaseAuth.signOut()).called(1);
      });

      test('debería manejar errores al cerrar sesión', () async {
        when(
          mockGoogleSignIn.signOut(),
        ).thenThrow(Exception('Error al cerrar sesión'));
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        expect(() async => await authService.signOut(), throwsException);
      });
    });

    group('Inicio de sesión con FakeStore API', () {
      test(
        'debería retornar token cuando las credenciales son correctas',
        () async {
          const username = 'testuser';
          const password = 'testpass';
          const expectedToken = 'fake_token_123';

          final mockResponse = http.Response(
            jsonEncode({'token': expectedToken}),
            200,
          );

          when(
            mockHttpClient.post(
              Uri.parse('https://fakestoreapi.com/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'username': username, 'password': password}),
            ),
          ).thenAnswer((_) async => mockResponse);

          final result = await authService.signInWithFakeStore(
            username,
            password,
          );

          expect(result, equals(expectedToken));
          verify(
            mockHttpClient.post(
              Uri.parse('https://fakestoreapi.com/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'username': username, 'password': password}),
            ),
          ).called(1);
        },
      );

      test(
        'debería retornar null cuando las credenciales son incorrectas',
        () async {
          const username = 'wronguser';
          const password = 'wrongpass';

          final mockResponse = http.Response(
            jsonEncode({'error': 'Invalid credentials'}),
            401,
          );

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => mockResponse);

          final result = await authService.signInWithFakeStore(
            username,
            password,
          );

          expect(result, isNull);
        },
      );

      test('debería retornar null cuando hay error de conexión', () async {
        const username = 'testuser';
        const password = 'testpass';

        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('Server Error', 500));

        final result = await authService.signInWithFakeStore(
          username,
          password,
        );

        expect(result, isNull);
      });

      test(
        'debería guardar el token en SharedPreferences cuando el login es exitoso',
        () async {
          const username = 'testuser';
          const password = 'testpass';
          const expectedToken = 'fake_token_123';

          final mockResponse = http.Response(
            jsonEncode({'token': expectedToken}),
            200,
          );

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => mockResponse);

          final result = await authService.signInWithFakeStore(
            username,
            password,
          );

          expect(result, equals(expectedToken));

          // Verificar que el token se guardó
          final savedToken = await authService.getStoredToken();
          expect(savedToken, equals(expectedToken));
        },
      );
    });

    group('Obtener token guardado', () {
      test(
        'debería retornar el token cuando existe en el almacenamiento',
        () async {
          const expectedToken = 'stored_token_123';
          SharedPreferences.setMockInitialValues({'auth_token': expectedToken});

          final result = await authService.getStoredToken();

          expect(result, equals(expectedToken));
        },
      );

      test('debería retornar null cuando no hay token guardado', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await authService.getStoredToken();

        expect(result, isNull);
      });

      test('debería retornar null cuando la clave no existe', () async {
        SharedPreferences.setMockInitialValues({'other_key': 'some_value'});

        final result = await authService.getStoredToken();

        expect(result, isNull);
      });
    });
  });

  group('Pruebas de Integración', () {
    test(
      'debería almacenar token después de login exitoso con FakeStore',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockHttpClient = MockClient();
        final authService = AuthService(httpClient: mockHttpClient);

        const username = 'testuser';
        const password = 'testpass';
        const expectedToken = 'integration_token_123';

        final mockResponse = http.Response(
          jsonEncode({'token': expectedToken}),
          200,
        );

        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final initialToken = await authService.getStoredToken();
        expect(initialToken, isNull);
        final loginResult = await authService.signInWithFakeStore(
          username,
          password,
        );
        expect(loginResult, equals(expectedToken));

        final storedToken = await authService.getStoredToken();
        expect(storedToken, equals(expectedToken));
      },
    );

    test('debería mantener el flujo completo de autenticación', () async {
      SharedPreferences.setMockInitialValues({});
      final mockHttpClient = MockClient();
      final mockFirebaseAuth = MockFirebaseAuth();
      final mockGoogleSignIn = MockGoogleSignIn();

      final authService = AuthService(
        auth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
        httpClient: mockHttpClient,
      );

      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      await authService.signOut();
      final token = await authService.getStoredToken();

      expect(token, isNull);
      verify(mockGoogleSignIn.signOut()).called(1);
      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });
}
