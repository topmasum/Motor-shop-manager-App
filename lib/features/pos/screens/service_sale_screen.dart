import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../stock/services/stock_repository.dart';

class ServiceSaleScreen extends StatefulWidget {
  const ServiceSaleScreen({super.key});

  @override
  State<ServiceSaleScreen> createState() => _ServiceSaleScreenState();
}

class _ServiceSaleScreenState extends State<ServiceSaleScreen> {
  final StockRepository _stockRepo = StockRepository();
  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();

  // A dynamic list to hold our service text controllers
  List<Map<String, TextEditingController>> _services = [
    {'name': TextEditingController(), 'price': TextEditingController()}
  ];

  bool _isLoading = false;

  void _addServiceField() {
    setState(() {
      _services.add({'name': TextEditingController(), 'price': TextEditingController()});
    });
  }

  void _removeServiceField(int index) {
    setState(() {
      _services[index]['name']!.dispose();
      _services[index]['price']!.dispose();
      _services.removeAt(index);
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var service in _services) {
      final priceText = service['price']!.text;
      if (priceText.isNotEmpty) {
        total += double.tryParse(priceText) ?? 0.0;
      }
    }
    return total;
  }

  Future<void> _checkout() async {
    // 1. Validation
    if (_services.isEmpty || _services[0]['name']!.text.trim().isEmpty) {
      CustomSnackbar.showError(context, "Please enter at least one service.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Extract data from controllers
      List<Map<String, dynamic>> finalServices = [];
      for (var service in _services) {
        final name = service['name']!.text.trim();
        final priceText = service['price']!.text.trim();

        if (name.isNotEmpty && priceText.isNotEmpty) {
          finalServices.add({
            'name': name,
            'price': double.tryParse(priceText) ?? 0.0,
          });
        }
      }

      double total = _calculateTotal();

      // 3. Save to database
      await _stockRepo.completeServiceSale(
        finalServices,
        total,
        _customerNameCtrl.text.trim(),
        _customerPhoneCtrl.text.trim(),
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, "Service Sale Completed!");
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, "Checkout failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Custom Service Sale', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CUSTOMER INFO ---
            const Text("Customer Details (Optional)", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _customerNameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: "Customer Name",
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerPhoneCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppColors.textSecondary, thickness: 0.2),
            ),

            // --- SERVICES ---
            const Text("Services Provided", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            ...List.generate(_services.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _services[index]['name'],
                        style: const TextStyle(color: AppColors.textPrimary), // --- ADD THIS LINE ---
                        decoration: const InputDecoration(labelText: "Service Name (e.g. Oil Change)", border: InputBorder.none),
                      ),
                    ),
                    Container(width: 1, height: 50, color: AppColors.background, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _services[index]['price'],
                        style: const TextStyle(color: AppColors.textPrimary), // --- ADD THIS LINE ---
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Price", prefixText: "\$ ", border: InputBorder.none),
                        onChanged: (val) => setState(() {}), // Update total
                      ),
                    ),
                    if (_services.length > 1) // Only show delete if there's more than 1
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () => _removeServiceField(index),
                      )
                  ],
                ),
              );
            }),

            TextButton.icon(
              onPressed: _addServiceField,
              icon: const Icon(Icons.add, color: AppColors.accent),
              label: const Text("Add Another Service", style: TextStyle(color: AppColors.accent)),
            ),

            const SizedBox(height: 40),

            // --- TOTAL & CHECKOUT ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:", style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("\$${_calculateTotal().toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(text: "Complete Sale", onPressed: _checkout),
          ],
        ),
      ),
    );
  }
}