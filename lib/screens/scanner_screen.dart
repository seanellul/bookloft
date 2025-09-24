import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/barcode_scanner_widget.dart';
import 'book_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset processing state when returning to scanner
    if (_isProcessing) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing barcode...'),
                ],
              ),
            )
          : BarcodeScannerWidget(
              title: 'Scan Book Barcode',
              onBarcodeScanned: _handleBarcodeScanned,
            ),
    );
  }

  void _handleBarcodeScanned(String barcode) {
    setState(() {
      _isProcessing = true;
    });

    // Automatically process the barcode
    _processBarcode(barcode);
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      final provider = context.read<InventoryProvider>();
      final book = await provider.getBookByIsbn(barcode);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (book != null) {
          // Book exists, go directly to book details
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: book,
                scannedBarcode: barcode,
              ),
            ),
          );
        } else {
          // Book doesn't exist, go directly to add new book
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: null,
                scannedBarcode: barcode,
                isNewBook: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show error and go back to scanning
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing barcode: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Try Again',
              onPressed: () {
                setState(() {
                  _isProcessing = false;
                });
              },
            ),
          ),
        );
      }
    }
  }
}
