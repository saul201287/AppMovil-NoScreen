class CartItem {
  final int productId;
  final int quantity;

  CartItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
    );
  }
}
