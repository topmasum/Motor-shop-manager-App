import '../../stock/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Automatically calculates the total for this specific row
  double get total => product.price * quantity;
}