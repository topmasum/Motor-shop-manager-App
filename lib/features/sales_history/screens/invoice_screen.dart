import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // --- ADDED FOR DELETE ---
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/shop_session.dart'; // --- ADDED FOR ROLE CHECK ---
import '../../../core/utils/custom_snackbar.dart';
import '../models/sale_invoice_model.dart';

class InvoiceScreen extends StatefulWidget {
  final SaleInvoiceModel invoice;

  const InvoiceScreen({super.key, required this.invoice});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  // --- THE NEW SOFT-DELETE FUNCTION ---
  Future<void> _hideInvoice() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Remove Record?", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            "Are you sure you want to remove this receipt? Your total revenue and analytics will not be affected.",
            style: TextStyle(color: AppColors.textSecondary)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // --- THE FIX: ADDED THE SHOP ID PATH ---
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(ShopSession.currentShopId) // Go to your shop first!
            .collection('sales')
            .doc(widget.invoice.id)
            .update({'isHidden': true});

        if (mounted) {
          CustomSnackbar.showSuccess(context, "Receipt removed.");
          Navigator.pop(context); // Go back to the History list!
        }
      } catch (e) {
        if (mounted) CustomSnackbar.showError(context, "Error removing record: $e");
      }
    }
  }

  // --- THE INVISIBLE SCREENSHOT GENERATOR ---
  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);

    try {
      final dateString = "${widget.invoice.date.day}/${widget.invoice.date.month}/${widget.invoice.date.year} at ${widget.invoice.date.hour}:${widget.invoice.date.minute.toString().padLeft(2, '0')}";

      // Build an invisible, full-length widget in the background so nothing gets cut off!
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wraps tightly around all content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text("CASH RECEIPT", style: TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2))),
                const SizedBox(height: 24),

                Text("Date: $dateString", style: const TextStyle(color: Colors.black87, fontSize: 16)),
                Text("Memo ID: ${widget.invoice.id.substring(0, 8).toUpperCase()}", style: const TextStyle(color: Colors.black87, fontSize: 16)),
                const SizedBox(height: 16),

                const Text("BILLED TO:", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(widget.invoice.customerName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                if (widget.invoice.customerPhone.isNotEmpty)
                  Text(widget.invoice.customerPhone, style: const TextStyle(color: Colors.black87, fontSize: 16)),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.grey, thickness: 1),
                ),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ITEM", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("TOTAL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),

                // We use a Column and map the items instead of a ListView
                // This forces the widget to stretch to its full height for the image!
                Column(
                  children: widget.invoice.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("${item['quantitySold']} x \$${item['priceAtSale']}", style: const TextStyle(color: Colors.black54, fontSize: 14)),
                              ],
                            ),
                          ),
                          Text("\$${item['rowTotal'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const Divider(color: Colors.black, thickness: 2),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("GRAND TOTAL", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("\$${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),
                const Center(child: Text("Thank you for your business!", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 16))),
              ],
            ),
          ),
        ),
        delay: const Duration(milliseconds: 200), // Give it time to render off-screen
        pixelRatio: 2.5, // High resolution for a crisp PDF-like image
      );

      // Save and share as normal
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/receipt_${widget.invoice.id}.png').create();
      await imagePath.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Thank you for your purchase from our shop! Here is your receipt.',
      );

    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, "Failed to share: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = "${widget.invoice.date.day}/${widget.invoice.date.month}/${widget.invoice.date.year} at ${widget.invoice.date.hour}:${widget.invoice.date.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sale Memo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [

          // --- ADDED: SECURE DELETE BUTTON ---
          // Safe Role Check ignoring case and spaces
          if (['owner', 'co-owner', 'manager'].contains(ShopSession.currentUserRole?.trim().toLowerCase()))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _hideInvoice,
            ),

          // Share Button & Loading Spinner
          _isSharing
              ? const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))),
          )
              : IconButton(
            icon: const Icon(Icons.share, color: AppColors.accent),
            onPressed: _shareReceipt,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // The user's on-screen view remains perfectly scrollable and unaffected!
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text("CASH RECEIPT", style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2))),
                    const SizedBox(height: 24),

                    Text("Date: $dateString", style: const TextStyle(color: Colors.black87)),
                    Text("Memo ID: ${widget.invoice.id.substring(0, 8).toUpperCase()}", style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 16),

                    const Text("BILLED TO:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(widget.invoice.customerName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (widget.invoice.customerPhone.isNotEmpty)
                      Text(widget.invoice.customerPhone, style: const TextStyle(color: Colors.black87)),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.grey, thickness: 1),
                    ),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ITEM", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text("TOTAL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // On-screen we keep the ListView so the user can scroll!
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.invoice.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.invoice.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                      Text("${item['quantitySold']} x \$${item['priceAtSale']}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text("\$${item['rowTotal'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(color: Colors.black, thickness: 2),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("GRAND TOTAL", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("\$${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Center(child: Text("Thank you for your business!", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              text: "Done",
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}