import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/product_model.dart';
import '../services/stock_repository.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final StockRepository _stockRepo = StockRepository();

  // Form Controllers
  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  // The list of items waiting to be saved to Firebase
  List<ProductModel> _pendingProducts = [];

  // Dummy data for Category Auto-Suggest (We will fetch this from Firebase later)
  // Remove the dummy data and replace with these:
  List<String> _availableCategories = [];
  List<String> _availableNames = [];
  List<String> _availableModels = [];
  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final categories = await _stockRepo.getCategoryNames();
    final namesAndModels = await _stockRepo.getUniqueNamesAndModels();

    if (mounted) {
      setState(() {
        _availableCategories = categories;
        _availableNames = namesAndModels['names'] ?? [];
        _availableModels = namesAndModels['models'] ?? [];
      });
    }
  }

  bool _isSaving = false;

  void _addToList() {
    if (_formKey.currentState!.validate()) {
      final newProduct = ProductModel(
        id: '',
        categoryName: _categoryController.text.trim(),
        name: _nameController.text.trim(),
        productModel: _modelController.text.trim(),
        quantity: int.parse(_qtyController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        searchKeywords: [],
        description: _descController.text.trim(),
        imageUrl: '',
      );

      setState(() {
        // SMART BATCHING: Check if it's already in the pending list
        int existingIndex = _pendingProducts.indexWhere(
          (p) =>
              p.categoryName == newProduct.categoryName &&
              p.name == newProduct.name &&
              p.productModel == newProduct.productModel,
        );

        if (existingIndex >= 0) {
          // If it's already in the list, just increase the quantity
          final existing = _pendingProducts[existingIndex];
          _pendingProducts[existingIndex] = ProductModel(
            id: existing.id,
            categoryName: existing.categoryName,
            name: existing.name,
            productModel: existing.productModel,
            quantity:
                existing.quantity + newProduct.quantity, // Add quantities!
            price: newProduct.price, // Use latest price
            searchKeywords: existing.searchKeywords,
            description: existing.description,
            imageUrl: existing.imageUrl,
          );
        } else {
          // Otherwise, add it as a new row
          _pendingProducts.add(newProduct);
        }
        if (!_availableCategories.contains(newProduct.categoryName))
          _availableCategories.add(newProduct.categoryName);
        if (!_availableNames.contains(newProduct.name))
          _availableNames.add(newProduct.name);
        if (newProduct.productModel.isNotEmpty &&
            !_availableModels.contains(newProduct.productModel))
          _availableModels.add(newProduct.productModel);
      });

      // Clear only the fields that usually change
      _qtyController.clear();
      _priceController.clear();
      _descController.clear();

      CustomSnackbar.showSuccess(context, "Added to batch!");
    }
  }

  Future<void> _saveAllToDatabase() async {
    if (_pendingProducts.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      for (var product in _pendingProducts) {
        // Here we generate search keywords (e.g. "Oil", "Engine Oil", "Castrol")
        final keywords = product.name.toLowerCase().split(' ')
          ..addAll(product.categoryName.toLowerCase().split(' '))
          ..add(product.productModel.toLowerCase());

        final productToSave = ProductModel(
          id: product.id,
          categoryName: product.categoryName,
          name: product.name,
          productModel: product.productModel,
          quantity: product.quantity,
          price: product.price,
          searchKeywords: keywords,
        );

        await _stockRepo.addProduct(productToSave);
      }

      if (mounted) {
        CustomSnackbar.showSuccess(context, "All products saved successfully!");
        Navigator.pop(context); // Go back to the dashboard or stock list
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, "Error: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // THE FORM SECTION
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Placeholder
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: AppColors.textSecondary,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add Image",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auto-suggest Category Field
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _availableCategories.where((String option) {
                          return option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      },
                      onSelected: (String selection) {
                        // Triggers if they tap a suggestion
                        _categoryController.text = selection;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            return CustomTextField(
                              label: "Category",
                              hint: "e.g. Engine Oil",
                              icon: Icons.category,

                              // 1. We use the controller provided by Autocomplete
                              controller: controller,

                              // 2. CRITICAL: This connects the text field to the dropdown menu!
                              focusNode: focusNode,

                              validator: (value) {
                                // 3. Memory-Safe Sync: We capture custom typed words right before saving
                                _categoryController.text = value ?? '';
                                return value == null || value.isEmpty
                                    ? "Category required"
                                    : null;
                              },
                            );
                          },
                    ),

                    // --- AUTOCOMPLETE FOR NAME ---
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty)
                          return const Iterable<String>.empty();
                        return _availableNames.where(
                          (option) => option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (String selection) =>
                          _nameController.text = selection,
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            return CustomTextField(
                              label: "Product Name",
                              hint: "e.g. Castrol GTX",
                              icon: Icons.build,
                              controller: controller,
                              focusNode: focusNode,
                              validator: (value) {
                                _nameController.text = value ?? '';
                                return value == null || value.isEmpty
                                    ? "Name required"
                                    : null;
                              },
                            );
                          },
                    ),

                    // --- AUTOCOMPLETE FOR MODEL ---
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty)
                          return const Iterable<String>.empty();
                        return _availableModels.where(
                          (option) => option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (String selection) =>
                          _modelController.text = selection,
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            return CustomTextField(
                              label: "Model Name",
                              hint: "e.g. 20W-50",
                              icon: Icons.settings,
                              controller: controller,
                              focusNode: focusNode,
                              validator: (value) {
                                _modelController.text = value ?? '';
                                return null; // Model is usually optional, so no error if empty
                              },
                            );
                          },
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: "Quantity",
                            hint: "0",
                            icon: Icons.format_list_numbered,
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: "Price (\$)",
                            hint: "0.00",
                            icon: Icons.attach_money,
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) =>
                                value!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),

                    CustomTextField(
                      label: "Description (Optional)",
                      hint: "Add notes...",
                      icon: Icons.description,
                      controller: _descController,
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _addToList,
                        icon: const Icon(Icons.add, color: AppColors.accent),
                        label: const Text(
                          "Add to Batch",
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // THE PENDING LIST SECTION
          if (_pendingProducts.isNotEmpty)
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pending Items (${_pendingProducts.length})",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pendingProducts.length,
                        itemBuilder: (context, index) {
                          final product = _pendingProducts[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              "${product.categoryName} • Qty: ${product.quantity}",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              "\$${product.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            leading: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  _pendingProducts.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: "Save All to Inventory",
                      isLoading: _isSaving,
                      onPressed: _saveAllToDatabase,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
