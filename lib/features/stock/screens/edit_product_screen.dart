import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../models/product_model.dart';
import '../services/stock_repository.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product; // We pass the existing product into this screen

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final StockRepository _stockRepo = StockRepository();

  late TextEditingController _categoryController;
  late TextEditingController _nameController;
  late TextEditingController _modelController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill all the text boxes with the existing product data!
    _categoryController = TextEditingController(text: widget.product.categoryName);
    _nameController = TextEditingController(text: widget.product.name);
    _modelController = TextEditingController(text: widget.product.productModel);
    _qtyController = TextEditingController(text: widget.product.quantity.toString());
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descController = TextEditingController(text: widget.product.description);
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Create an updated version of the product, keeping the SAME ID
      final updatedProduct = ProductModel(
        id: widget.product.id,
        categoryName: _categoryController.text.trim(),
        name: _nameController.text.trim(),
        productModel: _modelController.text.trim(),
        quantity: int.parse(_qtyController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        description: _descController.text.trim(),
        imageUrl: widget.product.imageUrl,

        // Regenerate search keywords just in case they changed the name
        searchKeywords: _nameController.text.trim().toLowerCase().split(' ')
          ..addAll(_categoryController.text.trim().toLowerCase().split(' '))
          ..add(_modelController.text.trim().toLowerCase()),
      );

      await _stockRepo.updateProduct(updatedProduct);

      if (mounted) {
        CustomSnackbar.showSuccess(context, "Product updated successfully!");
        Navigator.pop(context); // Go back to the dashboard
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, "Failed to update: ${e.toString()}");
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
        title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: "Category", hint: "Category", icon: Icons.category,
                controller: _categoryController,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              CustomTextField(
                label: "Product Name", hint: "Name", icon: Icons.build,
                controller: _nameController,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              CustomTextField(
                label: "Model Name", hint: "Model", icon: Icons.settings,
                controller: _modelController,
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Quantity", hint: "0", icon: Icons.format_list_numbered,
                      controller: _qtyController, keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: "Price (\$)", hint: "0.00", icon: Icons.attach_money,
                      controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              CustomTextField(
                label: "Description", hint: "Notes", icon: Icons.description,
                controller: _descController,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: "Save Changes",
                isLoading: _isSaving,
                onPressed: _updateProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}