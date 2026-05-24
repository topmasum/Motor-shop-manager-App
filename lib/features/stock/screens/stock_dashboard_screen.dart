import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product_model.dart';
import '../services/stock_repository.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final StockRepository _stockRepo = StockRepository();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await _stockRepo.getCategoryNames();
    if (mounted) {
      setState(() {
        _categories = ['All', ...fetchedCategories];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stock & Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      // --- THE RED FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) {
            // Refresh categories when returning just in case they added a new one!
            _loadCategories();
          });
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by name or model...",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- CATEGORY FILTER CHIPS ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.accent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // --- REAL-TIME INVENTORY LIST ---
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _stockRepo.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading stock: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                final products = snapshot.data ?? [];

                // Apply Search and Category Filters
                final filteredProducts = products.where((product) {
                  final matchesCategory = _selectedCategory == 'All' || product.categoryName == _selectedCategory;
                  final matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
                      product.productModel.toLowerCase().contains(_searchQuery);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text("No products found.", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // Bottom padding for the FAB
                  itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      // Highlight low stock in Red, healthy stock in Green
                      final isLowStock = product.quantity <= 3;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        // --- NAVIGATE TO EDIT SCREEN ON TAP ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(product: product),
                            ),
                          ).then((_) => _loadCategories()); // Refresh categories when coming back
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              // Optional: Image Thumbnail Placeholder
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.build, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 16),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${product.categoryName} • ${product.productModel}",
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity and Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$${product.price.toStringAsFixed(2)}",
                                    style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${product.quantity} in stock",
                                      style: TextStyle(
                                          color: isLowStock ? Colors.redAccent : Colors.greenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // --- NEW EDIT ICON ---
                              const SizedBox(width: 12),
                              const Icon(Icons.edit_note, color: AppColors.textSecondary, size: 28),
                            ],
                          ),
                        ),
                      );
                    },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}