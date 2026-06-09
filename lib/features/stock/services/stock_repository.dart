import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/shop_session.dart'; // --- IMPORTED THE MEMORY BOX ---
import '../../sales_history/models/sale_invoice_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../../pos/models/cart_item.dart';

class StockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- THE ENTERPRISE UPGRADE ---
  // We no longer use the personal User ID. We use the shared Master Shop ID!
  String? get _shopId => ShopSession.currentShopId;

  // --- SAFETY SHIELD ---
  DocumentReference get _shopDoc {
    if (_shopId == null) {
      throw Exception("CRITICAL: Shop Session is empty. Please log out and log back in.");
    }
    return _firestore.collection('shops').doc(_shopId);
  }

  // --- CATEGORY METHODS ---
  Future<void> addCategory(String categoryName) async {
    if (_shopId == null) return;

    await _shopDoc.collection('categories').doc(categoryName.toLowerCase()).set({
      'name': categoryName,
    });
  }

  Stream<List<CategoryModel>> getCategories() {
    if (_shopId == null) return const Stream.empty();

    return _shopDoc.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<ProductModel>> getProducts() {
    if (_shopId == null) return const Stream.empty();

    return _shopDoc.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // --- PRODUCT METHODS ---
  Future<void> addProduct(ProductModel product) async {
    if (_shopId == null) throw Exception("User not logged in");

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
        'buyingPrice': product.buyingPrice, // Update buying price if it changed
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
        buyingPrice: product.buyingPrice,
        searchKeywords: product.searchKeywords,
        description: product.description,
        imageUrl: product.imageUrl,
      );

      await docRef.set(newProduct.toMap());
    }

    // Auto-create category if it was brand new
    await addCategory(product.categoryName);
  }

  // --- AUTO-SUGGESTION HELPERS ---
  Future<List<String>> getCategoryNames() async {
    if (_shopId == null) return [];

    try {
      final snapshot = await _shopDoc.collection('categories').get();

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
    if (_shopId == null) return {'names': [], 'models': []};

    try {
      final snapshot = await _shopDoc.collection('products').get();

      final Set<String> names = {};
      final Set<String> models = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;

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

  Future<void> deleteProduct(String productId) async {
    if (_shopId == null) throw Exception("User not logged in");

    await _shopDoc.collection('products').doc(productId).delete();
  }

  // --- UPDATE PRODUCT ---
  Future<void> updateProduct(ProductModel product) async {
    if (_shopId == null) throw Exception("User not logged in");

    await _shopDoc.collection('products').doc(product.id).update(product.toMap());
  }

  // --- DASHBOARD ANALYTICS ENGINE ---
  Stream<Map<String, dynamic>> getTodayMetrics() {
    if (_shopId == null) return Stream.value({'revenue': 0.0, 'profit': 0.0, 'itemsSold': 0});

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _shopDoc.collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .snapshots()
        .map((snapshot) {

      double totalRevenue = 0.0;
      double totalProfit = 0.0;
      int totalItemsSold = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // 1. REVENUE: The final, discounted cash handed to you by the customer
        double saleRevenue = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += saleRevenue;

        // 2. COST: How much did this specific cart cost YOU to buy from your supplier?
        double totalCartCost = 0.0;

        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          int qty = (item['quantitySold'] as num?)?.toInt() ?? 0;
          totalItemsSold += qty;

          // We sum up the original buying prices
          double buyPrice = (item['buyingPriceAtSale'] as num?)?.toDouble() ?? 0.0;
          totalCartCost += (buyPrice * qty);
        }

        // 3. PROFIT: The final discounted cash minus your supplier costs!
        totalProfit += (saleRevenue - totalCartCost);
      }

      return {
        'revenue': totalRevenue,
        'profit': totalProfit,
        'itemsSold': totalItemsSold,
        'salesCount': snapshot.docs.length,
      };
    });
  }

  // --- WEEKLY CHART ANALYTICS ---
  Stream<List<double>> getWeeklySales() {
    if (_shopId == null) return Stream.value(List.filled(7, 0.0));

    final today = DateTime.now();
    final weekAgo = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));

    return _shopDoc.collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .snapshots()
        .map((snapshot) {

      List<double> weeklyTotals = List.filled(7, 0.0);
      final startOfToday = DateTime(today.year, today.month, today.day);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] == null) continue;

        final saleDate = (data['date'] as Timestamp).toDate();
        final startOfSaleDay = DateTime(saleDate.year, saleDate.month, saleDate.day);

        final daysAgo = startOfToday.difference(startOfSaleDay).inDays;

        if (daysAgo >= 0 && daysAgo < 7) {
          final index = 6 - daysAgo;
          weeklyTotals[index] += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return weeklyTotals;
    });
  }

  // --- LOW STOCK ALERT ENGINE ---
  Stream<List<ProductModel>> getLowStockProducts() {
    if (_shopId == null) return const Stream.empty();

    return _shopDoc.collection('products')
        .where('quantity', isLessThanOrEqualTo: 3)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // --- UPGRADED CHECKOUT & SALES ENGINE ---
  Future<SaleInvoiceModel> completeSale(List<CartItem> cart, double finalTotal, String customerName, String customerPhone) async {
    if (_shopId == null) throw Exception("User not logged in");

    final batch = _firestore.batch();
    final saleRef = _shopDoc.collection('sales').doc();
    final now = DateTime.now();

    final itemsList = cart.map((item) => {
      'productId': item.product.id,
      'name': item.product.name,
      'category': item.product.categoryName,
      'quantitySold': item.quantity,
      'priceAtSale': item.product.price,
      'buyingPriceAtSale': item.product.buyingPrice,
      'rowTotal': item.total,
    }).toList();

    final saleData = {
      'id': saleRef.id,
      'totalAmount': finalTotal,
      'date': FieldValue.serverTimestamp(),
      'items': itemsList,
      'customerName': customerName,
      'customerPhone': customerPhone,
    };

    batch.set(saleRef, saleData);

    for (var item in cart) {
      final productRef = _shopDoc.collection('products').doc(item.product.id);
      batch.update(productRef, {'quantity': FieldValue.increment(-item.quantity)});
    }

    await batch.commit();

    return SaleInvoiceModel(
      id: saleRef.id,
      totalAmount: finalTotal,
      date: now,
      items: itemsList,
      customerName: customerName.isEmpty ? 'Walk-in Customer' : customerName,
      customerPhone: customerPhone,
    );
  }

  // --- SALES HISTORY FETCH ---
  Stream<List<SaleInvoiceModel>> getSalesHistory() {
    if (_shopId == null) return const Stream.empty();

    return _shopDoc.collection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SaleInvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
}