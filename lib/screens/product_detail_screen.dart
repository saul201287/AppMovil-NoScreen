import 'package:flutter/material.dart';
import 'package:product_list_app/models/product.dart';
import 'package:product_list_app/service/cart_service.dart';
import 'package:product_list_app/service/product_service.dart';
import 'package:product_list_app/cart/cart.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final ProductService? productService;
  final CartService? cartService;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productService,
    this.cartService,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductService _productService;
  late final CartService _cartService;
  late Future<Product> _futureProduct;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _cartService = widget.cartService ?? CartService();
    _futureProduct = _productService.getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Producto')),
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Producto no encontrado'));
          }

          final product = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (product.image.isNotEmpty)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      product.image,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.error, size: 100),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(product.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Text(
                  'Precio: \$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Cart.add(product);
                    await Cart.syncCart(_cartService);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} agregado al carrito'),
                      ),
                    );
                  },
                  child: const Text('Agregar al carrito'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
