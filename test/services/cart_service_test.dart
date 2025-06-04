import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:product_list_app/services/cart_service.dart';
import 'package:product_list_app/data/models/cart.dart';

@GenerateMocks([http.Client])
import 'cart_service_test.mocks.dart';

void main() {
  group('Pruebas de CartService', () {
    late CartService cartService;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      cartService = CartService(client: mockHttpClient);
    });

    group('Crear carrito', () {
      test(
        'debería crear un carrito exitosamente con productos válidos',
        () async {

          final cartItems = [
            CartItem(productId: 1, quantity: 2),
            CartItem(productId: 2, quantity: 1),
          ];

          final expectedResponse = {
            'id': 1,
            'userId': 1,
            'date': '2023-10-01T00:00:00.000Z',
            'products': [
              {'productId': 1, 'quantity': 2},
              {'productId': 2, 'quantity': 1},
            ],
          };

          final mockResponse = http.Response(
            json.encode(expectedResponse),
            200,
          );

          when(
            mockHttpClient.post(
              Uri.parse('https://fakestoreapi.com/carts'),
              headers: {'Content-Type': 'application/json'},
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => mockResponse);


          final result = await cartService.createCart(cartItems);

          expect(result, equals(expectedResponse));
          verify(
            mockHttpClient.post(
              Uri.parse('https://fakestoreapi.com/carts'),
              headers: {'Content-Type': 'application/json'},
              body: anyNamed('body'),
            ),
          ).called(1);
        },
      );

      test('debería crear un carrito vacío sin productos', () async {
        final cartItems = <CartItem>[];

        final expectedResponse = {
          'id': 2,
          'userId': 1,
          'date': '2023-10-01T00:00:00.000Z',
          'products': [],
        };

        final mockResponse = http.Response(json.encode(expectedResponse), 200);

        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await cartService.createCart(cartItems);

        expect(result, equals(expectedResponse));
        expect(result['products'], isEmpty);
      });

      test(
        'debería lanzar excepción cuando el servidor retorna error 400',
        () async {

          final cartItems = [CartItem(productId: 1, quantity: 1)];

          final mockResponse = http.Response(
            json.encode({'error': 'Bad Request'}),
            400,
          );

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await cartService.createCart(cartItems),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al crear el carrito: 400'),
              ),
            ),
          );
        },
      );

      test(
        'debería lanzar excepción cuando el servidor retorna error 500',
        () async {

          final cartItems = [CartItem(productId: 1, quantity: 1)];

          final mockResponse = http.Response('Internal Server Error', 500);

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await cartService.createCart(cartItems),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al crear el carrito: 500'),
              ),
            ),
          );
        },
      );

      test(
        'debería lanzar excepción específica cuando no hay conexión a Internet',
        () async {

          final cartItems = [CartItem(productId: 1, quantity: 1)];

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenThrow(const SocketException('No Internet'));

          expect(
            () async => await cartService.createCart(cartItems),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains(
                  'Sin conexión a Internet. Por favor, verifica tu red.',
                ),
              ),
            ),
          );
        },
      );

      test(
        'debería enviar el formato correcto en el body de la petición',
        () async {

          final cartItems = [CartItem(productId: 5, quantity: 3)];

          final mockResponse = http.Response(json.encode({'id': 1}), 200);

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => mockResponse);


          await cartService.createCart(cartItems);


          final captured =
              verify(
                mockHttpClient.post(
                  any,
                  headers: anyNamed('headers'),
                  body: captureAnyNamed('body'),
                ),
              ).captured;

          final sentBody = json.decode(captured.first as String);
          expect(sentBody, containsPair('userId', 1));
          expect(sentBody, contains('date'));
          expect(sentBody['products'], isA<List>());
          expect(sentBody['products'][0], containsPair('productId', 5));
          expect(sentBody['products'][0], containsPair('quantity', 3));
        },
      );
    });

    group('Obtener carrito', () {
      test('debería obtener un carrito exitosamente por ID', () async {
        const cartId = 1;
        final expectedCart = {
          'id': 1,
          'userId': 1,
          'date': '2023-10-01T00:00:00.000Z',
          'products': [
            {'productId': 1, 'quantity': 2},
            {'productId': 3, 'quantity': 1},
          ],
        };

        final mockResponse = http.Response(json.encode(expectedCart), 200);

        when(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/carts/$cartId'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await cartService.getCart(cartId);

        expect(result, equals(expectedCart));
        verify(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/carts/$cartId'),
          ),
        ).called(1);
      });

      test(
        'debería retornar carrito vacío cuando el servidor retorna una lista en lugar de objeto',
        () async {

          const cartId = 2;
          final mockResponse = http.Response(
            json.encode([]), 
            200,
          );

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/carts/$cartId'),
            ),
          ).thenAnswer((_) async => mockResponse);


          final result = await cartService.getCart(cartId);


          expect(result, equals({'products': []}));
        },
      );

      test(
        'debería lanzar excepción cuando el carrito no existe (404)',
        () async {

          const cartId = 999;
          final mockResponse = http.Response('Cart not found', 404);

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/carts/$cartId'),
            ),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await cartService.getCart(cartId),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al obtener el carrito: 404'),
              ),
            ),
          );
        },
      );

      test(
        'debería retornar carrito vacío cuando hay error de conexión',
        () async {

          const cartId = 1;

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/carts/$cartId'),
            ),
          ).thenThrow(const SocketException('No Internet'));


          final result = await cartService.getCart(cartId);


          expect(result, equals({'products': []}));
        },
      );

      test(
        'debería retornar carrito vacío cuando hay error genérico',
        () async {

          const cartId = 1;

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/carts/$cartId'),
            ),
          ).thenThrow(Exception('Error genérico'));


          final result = await cartService.getCart(cartId);


          expect(result, equals({'products': []}));
        },
      );

      test('debería usar el ID correcto en la URL', () async {
        const cartId = 42;
        final mockResponse = http.Response(
          json.encode({'id': cartId, 'products': []}),
          200,
        );

        when(mockHttpClient.get(any)).thenAnswer((_) async => mockResponse);

        await cartService.getCart(cartId);

        verify(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/carts/$cartId'),
          ),
        ).called(1);
      });
    });
  });

  group('Pruebas de Integración de CartService', () {
    test('debería crear y luego obtener un carrito correctamente', () async {
      final mockHttpClient = MockClient();
      final cartService = CartService(client: mockHttpClient);

      final cartItems = [CartItem(productId: 1, quantity: 2)];
      const createdCartId = 1;

      final createResponse = http.Response(
        json.encode({
          'id': createdCartId,
          'userId': 1,
          'products': [
            {'productId': 1, 'quantity': 2},
          ],
        }),
        200,
      );

      final getResponse = http.Response(
        json.encode({
          'id': createdCartId,
          'userId': 1,
          'products': [
            {'productId': 1, 'quantity': 2},
          ],
        }),
        200,
      );

      when(
        mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => createResponse);

      when(
        mockHttpClient.get(
          Uri.parse('https://fakestoreapi.com/carts/$createdCartId'),
        ),
      ).thenAnswer((_) async => getResponse);

      final createdCart = await cartService.createCart(cartItems);
      final retrievedCart = await cartService.getCart(createdCartId);

      expect(createdCart['id'], equals(createdCartId));
      expect(retrievedCart['id'], equals(createdCartId));
      expect(createdCart['products'], equals(retrievedCart['products']));
    });
  });
}

