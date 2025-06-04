import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:product_list_app/data/models/cart.dart';

class CartService {
  final String url = 'https://fakestoreapi.com/';
  final http.Client client;

  CartService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> createCart(List<CartItem> items) async {
    try {
      final response = await client.post(
        Uri.parse('${url}carts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': 1,
          'date': DateTime.now().toIso8601String(),
          'products': items.map((item) => item.toJson()).toList(),
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al crear el carrito: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Sin conexión a Internet. Por favor, verifica tu red.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCart(int cartId) async {
    try {
      print(cartId);
      final response = await client.get(Uri.parse('${url}carts/$cartId'));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result is Map<String, dynamic>) {
          return result;
        } else {
          return {'products': []};
        }
      } else {
        throw Exception('Error al obtener el carrito: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Sin conexión a Internet. Por favor, verifica tu red.');
      }
      return {'products': []};
    }
  }
}
