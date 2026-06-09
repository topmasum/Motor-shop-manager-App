import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../sales_history/screens/invoice_screen.dart';
import '../../stock/models/product_model.dart';
import '../../stock/services/stock_repository.dart';
import '../models/cart_item.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final StockRepository _stockRepo = StockRepository();
  String _searchQuery = '';

  List<CartItem> _cart = [];

  // --- NEW: DISCOUNT STATE ---
  double _discountAmount = 0.0;
  double? _customTotal;

  // --- CART LOGIC ---
  void _addToCart(ProductModel product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);

      if (existingIndex >= 0) {
        if (_cart[existingIndex].quantity < product.quantity) {
          _cart[existingIndex].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Not enough stock!"), backgroundColor: Colors.redAccent, duration: Duration(milliseconds: 800)),
          );
        }
      } else {
        if (product.quantity > 0) {
          _cart.add(CartItem(product: product));
        }
      }

      // Clear custom override if they add a new item
      _customTotal = null;
    });
  }

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

  // --- UPGRADED PRICING MATH ---
  double get _originalTotal => _cart.fold(0, (sum, item) => sum + item.total);

  // Final total subtracts discount FIRST. If an absolute override is typed, it ignores the discount.
  double get _finalTotal {
    if (_customTotal != null) return _customTotal!;
    double calculated = _originalTotal - _discountAmount;
    return calculated < 0 ? 0 : calculated; // Prevent negative totals
  }

  // --- THE CART BOTTOM SHEET ---
  void _showCartSheet() {
    bool isCheckingOut = false;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    // Discount Controller
    final TextEditingController discountController = TextEditingController(
        text: _discountAmount > 0 ? _discountAmount.toStringAsFixed(2) : ''
    );

    // Override Controller
    final TextEditingController overrideController = TextEditingController(
        text: _customTotal != null ? _customTotal.toString() : _finalTotal.toStringAsFixed(2)
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparent so we can add custom rounded corners
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
            builder: (BuildContext modalContext, StateSetter setModalState) {

              // THE FIX: We give the modal a specific height (85% of screen)
              // so the list isn't restricted to being "tiny" anymore!
              return Container(
                height: MediaQuery.of(modalContext).size.height * 0.85,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom, // Pushes up when keyboard opens
                  left: 20, right: 20, top: 20,
                ),
                decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Sale", style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(color: AppColors.textSecondary),

                    // --- THE SHOPPING CART LIST ---
                    // By using Expanded, it takes up all available space naturally without squishing!
                    if (_cart.isEmpty)
                      const Expanded(child: Center(child: Text("Cart is empty", style: TextStyle(color: AppColors.textSecondary))))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.product.name, style: const TextStyle(color: AppColors.textPrimary)),
                              subtitle: Text("\$${item.product.price} each", style: const TextStyle(color: AppColors.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.accent),
                                    onPressed: () {
                                      setModalState(() {
                                        setState(() {
                                          if (item.quantity > 1) item.quantity--;
                                          else _cart.removeAt(index);
                                          _customTotal = null; // Clear override
                                        });
                                        overrideController.text = _finalTotal.toStringAsFixed(2);
                                      });
                                    },
                                  ),
                                  SizedBox(width: 24, child: Text("${item.quantity}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                                    onPressed: () {
                                      setModalState(() {
                                        setState(() {
                                          if (item.quantity < item.product.quantity) {
                                            item.quantity++;
                                            _customTotal = null;
                                          }
                                        });
                                        overrideController.text = _finalTotal.toStringAsFixed(2);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 65, child: Text("\$${item.total.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // --- THE CHECKOUT PANEL (Scrollable for keyboard safety) ---
                    SizedBox(
                      height: 250, // Fixed height for the bottom panel so it doesn't get crushed
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: nameController,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                    decoration: const InputDecoration(hintText: "Customer Name (Optional)", hintStyle: TextStyle(color: AppColors.textSecondary), border: InputBorder.none, icon: Icon(Icons.person, color: AppColors.textSecondary)),
                                  ),
                                  const Divider(color: AppColors.textSecondary, height: 1),
                                  TextField(
                                    controller: phoneController,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(hintText: "Customer Phone (Optional)", hintStyle: TextStyle(color: AppColors.textSecondary), border: InputBorder.none, icon: Icon(Icons.phone, color: AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- DISCOUNT & OVERRIDE PANEL ---
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  // DISCOUNT ROW
                                  Row(
                                    children: [
                                      const Expanded(child: Text("Discount Amount:", style: TextStyle(color: AppColors.textSecondary))),
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: discountController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                          textAlign: TextAlign.right,
                                          decoration: const InputDecoration(prefixText: "- \$ ", prefixStyle: TextStyle(color: Colors.orangeAccent), isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                                          onChanged: (val) {
                                            setModalState(() {
                                              setState(() {
                                                _discountAmount = double.tryParse(val) ?? 0.0;
                                                _customTotal = null; // Typing a discount removes the manual override
                                              });
                                              overrideController.text = _finalTotal.toStringAsFixed(2);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(color: AppColors.textSecondary, height: 1)),

                                  // OVERRIDE ROW
                                  Row(
                                    children: [
                                      const Expanded(child: Text("Final Price Override:", style: TextStyle(color: AppColors.textSecondary))),
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: overrideController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
                                          textAlign: TextAlign.right,
                                          decoration: const InputDecoration(prefixText: "\$ ", prefixStyle: TextStyle(color: Colors.greenAccent), isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                                          onChanged: (val) {
                                            setModalState(() {
                                              setState(() => _customTotal = double.tryParse(val));
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            PrimaryButton(
                              text: "Checkout • \$${_finalTotal.toStringAsFixed(2)}",
                              isLoading: isCheckingOut,
                              onPressed: _cart.isEmpty || isCheckingOut ? () {} : () async {
                                setModalState(() => isCheckingOut = true);

                                try {
                                  final generatedInvoice = await _stockRepo.completeSale(
                                      _cart,
                                      _finalTotal,
                                      nameController.text.trim(),
                                      phoneController.text.trim()
                                  );

                                  if (mounted) {
                                    Navigator.pop(modalContext);
                                    setState(() {
                                      _cart.clear();
                                      _customTotal = null;
                                      _discountAmount = 0.0; // Reset discount
                                      _searchQuery = '';
                                    });
                                    CustomSnackbar.showSuccess(this.context, "Sale completed!");

                                    Navigator.push(this.context, MaterialPageRoute(
                                      builder: (context) => InvoiceScreen(invoice: generatedInvoice),
                                    ));
                                  }
                                } catch (e) {
                                  setModalState(() => isCheckingOut = false);
                                  if (mounted) CustomSnackbar.showError(this.context, "Checkout failed: $e");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Make a Sale', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _showCartSheet,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: Text("${_cart.length} Items • \$${_finalTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search stock to add...",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _stockRepo.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final products = snapshot.data ?? [];

                final filteredProducts = products.where((p) =>
                p.name.toLowerCase().contains(_searchQuery) ||
                    p.productModel.toLowerCase().contains(_searchQuery) ||
                    p.categoryName.toLowerCase().contains(_searchQuery)
                ).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isOutOfStock = product.quantity == 0;

                    return InkWell(
                      onTap: isOutOfStock ? null : () => _addToCart(product),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isOutOfStock ? Colors.redAccent.withOpacity(0.5) : Colors.transparent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(product.categoryName),
                                  size: 40,
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(product.productModel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("\$${product.price}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                Text(isOutOfStock ? "SOLD OUT" : "Qty: ${product.quantity}",
                                    style: TextStyle(color: isOutOfStock ? Colors.redAccent : AppColors.textSecondary, fontSize: 12, fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal)
                                ),
                              ],
                            )
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