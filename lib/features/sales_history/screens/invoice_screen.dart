import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/sale_invoice_model.dart';
import '../../../core/utils/custom_snackbar.dart'; // Make sure this path matches your project!

class InvoiceScreen extends StatefulWidget {
  final SaleInvoiceModel invoice;

  const InvoiceScreen({super.key, required this.invoice});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // This is the "Camera Controller" that takes the picture
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);

    try {
      // 1. Take a screenshot of the widget
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10), // Small delay ensures UI is fully rendered
        pixelRatio: 2.0, // Makes the image high resolution!
      );

      if (imageBytes != null) {
        // 2. Find a temporary folder on the phone to save the image
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/receipt_${widget.invoice.id}.png').create();

        // 3. Write the image data to that file
        await imagePath.writeAsBytes(imageBytes);

        // 4. Open the native Share menu (WhatsApp, Email, Text, etc.)
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Thank you for your purchase from our shop! Here is your receipt.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, "Failed to share: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
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
            // --- THE CAMERA LENS WRAPPER ---
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    // We keep the shadow subtle so it looks good in the app, but doesn't ruin the image
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