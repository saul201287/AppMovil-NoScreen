import 'package:flutter/material.dart';
import 'package:product_list_app/data/models/cart.dart';
import 'package:product_list_app/data/models/product.dart';
import 'package:product_list_app/services/cart_service.dart';
import 'package:product_list_app/services/product_service.dart';
import 'package:product_list_app/cart/cart.dart';

class CartScreen extends StatefulWidget {
  final ProductService? productService;
  final CartService? cartService;

  const CartScreen({super.key, this.productService, this.cartService});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final ProductService _productService;
  late final CartService _cartService;
  late Future<Map<String, dynamic>> _futureCart;
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _cartService = widget.cartService ?? CartService();
    _futureCart =
        Cart.cartId != null
            ? _cartService
                .getCart(1)
                .catchError((e) => {'products': []})
            : Future.value({'products': []});
    _futureProducts = _productService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: FutureBuilder(
        future: Future.wait([_futureCart, _futureProducts]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureCart =
                            Cart.cartId != null
                                ? _cartService
                                    .getCart(Cart.cartId!)
                                    .catchError((e) => {'products': []})
                                : Future.value({'products': []});
                        _futureProducts = _productService.getProducts();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data![0] == null) {
            return const Center(child: Text('Carrito no disponible'));
          }

          final cart = snapshot.data![0] as Map<String, dynamic>;
          final products = snapshot.data![1] as List<Product>;
          final cartItems =
              (cart['products'] as List<dynamic>? ?? [])
                  .map((item) => CartItem.fromJson(item))
                  .toList();

          if (cartItems.isEmpty) {
            return const Center(child: Text('El carrito está vacío'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final product = products.firstWhere(
                      (p) => p.id == cartItem.productId,
                      orElse:
                          () => Product(
                            id: cartItem.productId,
                            name: 'Producto desconocido',
                            price: 0,
                            description: '',
                            image: '',
                          ),
                    );
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        'Cantidad: ${cartItem.quantity} | \$${product.price.toStringAsFixed(2)} c/u',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          Cart.remove(product);
                          Cart.syncCart(_cartService);
                          setState(() {
                            _futureCart =
                                Cart.cartId != null
                                    ? _cartService
                                        .getCart(Cart.cartId!)
                                        .catchError((e) => {'products': []})
                                    : Future.value({'products': []});
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} eliminado del carrito',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total: \$${Cart.getTotal(products).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
