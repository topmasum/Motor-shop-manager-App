import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
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
  // --- DYNAMIC ICON ENGINE ---
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('helmet') || name.contains('gear')) return Icons.sports_motorsports;
    if (name.contains('oil') || name.contains('fluid') || name.contains('lube')) return Icons.water_drop;
    if (name.contains('tire') || name.contains('tyre') || name.contains('wheel')) return Icons.tire_repair;
    if (name.contains('brake') || name.contains('pad')) return Icons.stop_circle;
    if (name.contains('battery') || name.contains('power')) return Icons.battery_charging_full;
    if (name.contains('light') || name.contains('bulb')) return Icons.lightbulb;
    if (name.contains('filter')) return Icons.filter_alt;
    if (name.contains('engine') || name.contains('motor')) return Icons.engineering;
    if (name.contains('chain') || name.contains('sprocket')) return Icons.link;

    return Icons.build;
  }

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
        backgroundColor: AppColors.primary,
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
                      final isLowStock = product.quantity <= 3;

                      // --- NEW DISMISSIBLE WRAPPER ---
                      return Dismissible(
                        // A unique key is required so Flutter knows exactly which item is swiped
                        key: Key(product.id),
                        direction: DismissDirection.endToStart, // Only allow right-to-left swiping

                        // The red background that reveals underneath while swiping
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                        ),

                        // The safety confirmation popup
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text("Delete Product?", style: TextStyle(color: AppColors.textPrimary)),
                                content: Text(
                                    "Are you sure you want to permanently delete '${product.name}' from your inventory?",
                                    style: const TextStyle(color: AppColors.textSecondary)
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false), // Cancel swipe
                                    child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true), // Confirm swipe
                                    child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          );
                        },

                        // What actually happens when they click "Delete" on the popup
                        onDismissed: (direction) async {
                          try {
                            await _stockRepo.deleteProduct(product.id);
                            if (mounted) {
                              CustomSnackbar.showSuccess(context, "${product.name} deleted");
                              // We don't need setState here because the StreamBuilder automatically refreshes the list!
                            }
                          } catch (e) {
                            if (mounted) {
                              CustomSnackbar.showError(context, "Failed to delete: $e");
                            }
                          }
                        },

                        // --- YOUR EXISTING INKWELL & CARD ---
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProductScreen(product: product),
                              ),
                            ).then((_) => _loadCategories());
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
// NEW CODE
                              Container(
                              height: 50, width: 50,
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                              child: Icon(
                                _getCategoryIcon(product.categoryName), // Calling the smart icon engine!
                                color: AppColors.textSecondary,
                              ),
                            ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text("${product.categoryName} • ${product.productModel}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("\$${product.price.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isLowStock ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                      child: Text("${product.quantity} in stock", style: TextStyle(color: isLowStock ? Colors.redAccent : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.edit_note, color: AppColors.textSecondary, size: 28),
                              ],
                            ),
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