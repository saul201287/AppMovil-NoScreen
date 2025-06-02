import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:product_list_app/models/product.dart';

class ProductService {
  final String url = 'https://fakestoreapi.com/';
  final http.Client client;

  ProductService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Product>> getProducts() async {
    try {
      final response = await client.get(Uri.parse('${url}products'));
      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Error al consumir: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Sin conexión a Internet. Por favor, verifica tu red.');
      }
      rethrow;
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await client.get(Uri.parse('${url}products/$id'));
      if (response.statusCode == 200) {
        final jso = json.decode(response.body);
        return Product.fromJson(jso);
      } else {
        throw Exception('Error al obtener el producto: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Sin conexión a Internet. Por favor, verifica tu red.');
      }
      rethrow;
    }
  }
}
