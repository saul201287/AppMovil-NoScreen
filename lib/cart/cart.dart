import 'package:product_list_app/models/cart.dart';
import 'package:product_list_app/models/product.dart';
import 'package:product_list_app/service/cart_service.dart';

class Cart {
  static final List<CartItem> _items = [];
  static int? _cartId;

  static List<CartItem> get items => _items;
  static int? get cartId => _cartId;

  static void add(Product product, {int quantity = 1}) {
    final existingItem = _items.firstWhere(
      (item) => item.productId == product.id,
      orElse: () => CartItem(productId: product.id, quantity: 0),
    );
    if (existingItem.quantity > 0) {
      _items[_items.indexOf(existingItem)] = CartItem(
        productId: product.id,
        quantity: existingItem.quantity + quantity,
      );
    } else {
      _items.add(CartItem(productId: product.id, quantity: quantity));
    }
  }

  static void remove(Product product) {
    _items.removeWhere((item) => item.productId == product.id);
  }

  static Future<void> syncCart(CartService service) async {
    if (_items.isNotEmpty) {
      final response = await service.createCart(_items);
      _cartId = response['id'] as int?;
    } else {
      _cartId = null; // Reset cartId when cart is empty
    }
  }

  static double getTotal(List<Product> products) {
    return _items.fold(0, (sum, item) {
      final product = products.firstWhere(
        (p) => p.id == item.productId,
        orElse:
            () => Product(
              id: item.productId,
              name: '',
              price: 0,
              description: '',
              image: '',
            ),
      );
      return sum + (product.price * item.quantity);
    });
  }
}
