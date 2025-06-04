import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:product_list_app/services/product_service.dart';
import 'package:product_list_app/data/models/product.dart';

@GenerateMocks([http.Client])
import 'product_service_test.mocks.dart';

void main() {
  group('Pruebas de ProductService', () {
    late ProductService productService;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      productService = ProductService(client: mockHttpClient);
    });

    group('Obtener todos los productos', () {
      test('debería retornar lista de productos exitosamente', () async {
        final mockProductsJson = [
          {
            'id': 1,
            'name': 'Producto 1',
            'price': 29.99,
            'description': 'Descripción del producto 1',
            'category': 'electronics',
            'image': 'https://example.com/image1.jpg',
            'rating': {'rate': 4.5, 'count': 120},
          },
          {
            'id': 2,
            'name': 'Producto 2',
            'price': 15.50,
            'description': 'Descripción del producto 2',
            'category': 'clothing',
            'image': 'https://example.com/image2.jpg',
            'rating': {'rate': 3.8, 'count': 85},
          },
        ];

        final mockResponse = http.Response(json.encode(mockProductsJson), 200);

        when(
          mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
        ).thenAnswer((_) async => mockResponse);

        final result = await productService.getProducts();

        expect(result, isA<List<Product>>());
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('Producto 1'));
        expect(result[0].price, equals(29.99));
        expect(result[1].id, equals(2));
        expect(result[1].name, equals('Producto 2'));
        expect(result[1].price, equals(15.50));

        verify(
          mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
        ).called(1);
      });

      test('debería retornar lista vacía cuando no hay productos', () async {
        final mockResponse = http.Response(json.encode([]), 200);

        when(
          mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
        ).thenAnswer((_) async => mockResponse);

        final result = await productService.getProducts();

        expect(result, isA<List<Product>>());
        expect(result, isEmpty);
      });

      test(
        'debería lanzar excepción cuando el servidor retorna error 404',
        () async {
          final mockResponse = http.Response('Not Found', 404);

          when(
            mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await productService.getProducts(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al consumir: 404'),
              ),
            ),
          );
        },
      );

      test(
        'debería lanzar excepción cuando el servidor retorna error 500',
        () async {
          final mockResponse = http.Response('Internal Server Error', 500);

          when(
            mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await productService.getProducts(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al consumir: 500'),
              ),
            ),
          );
        },
      );

      test(
        'debería lanzar excepción específica cuando no hay conexión a Internet',
        () async {
          when(
            mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
          ).thenThrow(const SocketException('No Internet'));

          expect(
            () async => await productService.getProducts(),
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

      test('debería manejar JSON malformado', () async {
        final mockResponse = http.Response('JSON malformado {', 200);

        when(
          mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
        ).thenAnswer((_) async => mockResponse);
        expect(
          () async => await productService.getProducts(),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Obtener producto por ID', () {
      test('debería retornar un producto específico exitosamente', () async {
        const productId = 1;
        final mockProductJson = {
          'id': 1,
          'name': 'Producto Específico',
          'price': 99.99,
          'description': 'Descripción detallada del producto',
          'category': 'electronics',
          'image': 'https://example.com/specific-image.jpg',
          'rating': {'rate': 4.8, 'count': 200},
        };

        final mockResponse = http.Response(json.encode(mockProductJson), 200);

        when(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/products/$productId'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await productService.getProductById(productId);

        expect(result, isA<Product>());
        expect(result.id, equals(1));
        expect(result.name, equals('Producto Específico'));
        expect(result.price, equals(99.99));
        expect(
          result.description,
          equals('Descripción detallada del producto'),
        );
        expect(result.description, equals('electronics'));

        verify(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/products/$productId'),
          ),
        ).called(1);
      });

      test('debería usar el ID correcto en la URL', () async {
        const productId = 42;
        final mockProductJson = {
          'id': 42,
          'name': 'Producto 42',
          'price': 25.99,
          'description': 'Descripción',
          'category': 'test',
          'image': 'https://example.com/image.jpg',
          'rating': {'rate': 4.0, 'count': 50},
        };

        final mockResponse = http.Response(json.encode(mockProductJson), 200);

        when(mockHttpClient.get(any)).thenAnswer((_) async => mockResponse);

        await productService.getProductById(productId);

        verify(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/products/$productId'),
          ),
        ).called(1);
      });

      test(
        'debería lanzar excepción cuando el producto no existe (404)',
        () async {
          const productId = 999;
          final mockResponse = http.Response('Product not found', 404);

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/products/$productId'),
            ),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await productService.getProductById(productId),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al obtener el producto: 404'),
              ),
            ),
          );
        },
      );

      test(
        'debería lanzar excepción cuando hay error del servidor (500)',
        () async {
          const productId = 1;
          final mockResponse = http.Response('Internal Server Error', 500);

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/products/$productId'),
            ),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await productService.getProductById(productId),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Error al obtener el producto: 500'),
              ),
            ),
          );
        },
      );

      test(
        'debería lanzar excepción específica cuando no hay conexión a Internet',
        () async {
          const productId = 1;

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/products/$productId'),
            ),
          ).thenThrow(const SocketException('No Internet'));

          expect(
            () async => await productService.getProductById(productId),
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
        'debería manejar JSON malformado para producto específico',
        () async {
          const productId = 1;
          final mockResponse = http.Response('JSON malformado {', 200);

          when(
            mockHttpClient.get(
              Uri.parse('https://fakestoreapi.com/products/$productId'),
            ),
          ).thenAnswer((_) async => mockResponse);

          expect(
            () async => await productService.getProductById(productId),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test('debería manejar IDs negativos', () async {
        const productId = -1;
        final mockResponse = http.Response('Bad Request', 400);

        when(
          mockHttpClient.get(
            Uri.parse('https://fakestoreapi.com/products/$productId'),
          ),
        ).thenAnswer((_) async => mockResponse);
        expect(
          () async => await productService.getProductById(productId),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Error al obtener el producto: 400'),
            ),
          ),
        );
      });
    });
  });

  group('Pruebas de Integración de ProductService', () {
    test(
      'debería obtener todos los productos y luego un producto específico',
      () async {
        final mockHttpClient = MockClient();
        final productService = ProductService(client: mockHttpClient);

        final mockProductsJson = [
          {
            'id': 1,
            'name': 'Producto 1',
            'price': 29.99,
            'description': 'Descripción 1',
            'category': 'electronics',
            'image': 'https://example.com/image1.jpg',
            'rating': {'rate': 4.5, 'count': 120},
          },
          {
            'id': 2,
            'name': 'Producto 2',
            'price': 15.50,
            'description': 'Descripción 2',
            'category': 'clothing',
            'image': 'https://example.com/image2.jpg',
            'rating': {'rate': 3.8, 'count': 85},
          },
        ];

        final mockAllProductsResponse = http.Response(
          json.encode(mockProductsJson),
          200,
        );

        // Mock para obtener producto específico
        final mockSpecificProductResponse = http.Response(
          json.encode(mockProductsJson[0]),
          200,
        );

        when(
          mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products')),
        ).thenAnswer((_) async => mockAllProductsResponse);

        when(
          mockHttpClient.get(Uri.parse('https://fakestoreapi.com/products/1')),
        ).thenAnswer((_) async => mockSpecificProductResponse);

        final allProducts = await productService.getProducts();
        final specificProduct = await productService.getProductById(1);

        expect(allProducts.length, equals(2));
        expect(specificProduct.id, equals(1));
        expect(allProducts[0].id, equals(specificProduct.id));
        expect(allProducts[0].name, equals(specificProduct.name));
        expect(allProducts[0].price, equals(specificProduct.price));
      },
    );

    test(
      'debería manejar correctamente múltiples llamadas concurrentes',
      () async {
        final mockHttpClient = MockClient();
        final productService = ProductService(client: mockHttpClient);

        final mockProductJson = {
          'id': 1,
          'name': 'Producto Concurrente',
          'price': 50.00,
          'description': 'Descripción concurrente',
          'category': 'test',
          'image': 'https://example.com/concurrent.jpg',
          'rating': {'rate': 4.0, 'count': 100},
        };

        final mockResponse = http.Response(json.encode(mockProductJson), 200);

        when(mockHttpClient.get(any)).thenAnswer((_) async => mockResponse);

        final futures = [
          productService.getProductById(1),
          productService.getProductById(1),
          productService.getProductById(1),
        ];

        final results = await Future.wait(futures);

        expect(results.length, equals(3));
        for (final result in results) {
          expect(result.id, equals(1));
          expect(result.name, equals('Producto Concurrente'));
        }

        verify(mockHttpClient.get(any)).called(3);
      },
    );
  });
}

class Rating {
  final double rate;
  final int count;

  Rating({required this.rate, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(rate: (json['rate'] as num).toDouble(), count: json['count']);
  }
}
