class ProductModel {
  final String id;
  final String categoryName;
  final String name;
  final String productModel;
  final int quantity;
  final double price;
  final List<String> searchKeywords;

  // --- NEW FIELDS ADDED ---
  final String description;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.categoryName,
    required this.name,
    required this.productModel,
    required this.quantity,
    required this.price,
    required this.searchKeywords,
    this.description = '', // Default to empty string if not provided
    this.imageUrl = '',    // Default to empty string if not provided
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'name': name,
      'productModel': productModel,
      'quantity': quantity,
      'price': price,
      'searchKeywords': searchKeywords,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      categoryName: map['categoryName'] ?? '',
      name: map['name'] ?? '',
      productModel: map['productModel'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      // Using 'num' here is safer in case Firebase saves a flat price like "10" as an integer instead of "10.0"
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}