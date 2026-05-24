import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class StockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference get _shopDoc => _firestore.collection('shops').doc(_userId);

  // --- CATEGORY METHODS ---
  Future<void> addCategory(String categoryName) async {
    if (_userId == null) return;

    await _shopDoc.collection('categories').doc(categoryName.toLowerCase()).set({
      'name': categoryName,
    });
  }

  Stream<List<CategoryModel>> getCategories() {
    if (_userId == null) return const Stream.empty();

    return _shopDoc.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs
      // FIX 1: Explicit Map casting added here
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<ProductModel>> getProducts() {
    if (_userId == null) return const Stream.empty();

    return _shopDoc.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
      // FIX 2: Explicit Map casting added here
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // --- PRODUCT METHODS ---
  Future<void> addProduct(ProductModel product) async {
    if (_userId == null) throw Exception("User not logged in");

    // SMART CHECK: Does this exact product already exist?
    final querySnapshot = await _shopDoc.collection('products')
        .where('categoryName', isEqualTo: product.categoryName)
        .where('name', isEqualTo: product.name)
        .where('productModel', isEqualTo: product.productModel)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // IT EXISTS: Increment quantity
      final existingDocId = querySnapshot.docs.first.id;
      await _shopDoc.collection('products').doc(existingDocId).update({
        'quantity': FieldValue.increment(product.quantity),
        'price': product.price,
      });
    } else {
      // IT DOES NOT EXIST: Create new
      final docRef = _shopDoc.collection('products').doc();

      final newProduct = ProductModel(
        id: docRef.id,
        categoryName: product.categoryName,
        name: product.name,
        productModel: product.productModel,
        quantity: product.quantity,
        price: product.price,
        searchKeywords: product.searchKeywords,
        description: product.description,
        imageUrl: product.imageUrl,
      );

      await docRef.set(newProduct.toMap());
    }

    // Auto-create category if it was brand new
    await addCategory(product.categoryName);
  }

  // --- AUTO-SUGGESTION HELPERS (CRASH-PROOF VERSION) ---
  Future<List<String>> getCategoryNames() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _shopDoc.collection('categories').get();

      // FIX 3: Null-safe extraction
      return snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  Future<Map<String, List<String>>> getUniqueNamesAndModels() async {
    if (_userId == null) return {'names': [], 'models': []};

    try {
      final snapshot = await _shopDoc.collection('products').get();

      final Set<String> names = {};
      final Set<String> models = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;

        // FIX 4: Null-safe extraction
        final name = data['name']?.toString() ?? '';
        final model = data['productModel']?.toString() ?? '';

        if (name.isNotEmpty) names.add(name);
        if (model.isNotEmpty) models.add(model);
      }

      return {
        'names': names.toList(),
        'models': models.toList()
      };
    } catch (e) {
      print("Error fetching names/models: $e");
      return {'names': [], 'models': []};
    }
  }
  // --- UPDATE PRODUCT ---
  Future<void> updateProduct(ProductModel product) async {
    if (_userId == null) throw Exception("User not logged in");

    // We use the product's unique ID to find exactly which row to update in Firebase
    await _shopDoc.collection('products').doc(product.id).update(product.toMap());
  }
}