import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../providers/expense_provider.dart';
import 'ocr_result_screen.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;

  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<File> _compressImage(File file) async {
    // Read image
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    // Resize if too large
    if (image.width > 1920 || image.height > 1920) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? 1920 : null,
        height: image.height > image.width ? 1920 : null,
      );
    }

    // Compress
    final compressedBytes = img.encodeJpg(image, quality: 85);

    // Save compressed image
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

  Future<void> _uploadReceipt() async {
    if (_selectedImage == null) return;

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    try {
      // Compress image before upload
      final compressedImage = await _compressImage(_selectedImage!);

      // Upload to backend for OCR processing
      final ocrResult = await expenseProvider.uploadReceipt(compressedImage);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (ocrResult != null) {
        // Navigate to OCR result screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OCRResultScreen(),
          ),
        );
      } else {
        _showError('Failed to process receipt');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      _showError('Error uploading receipt: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearImage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How to scan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('1. Ensure good lighting'),
                    Text('2. Keep receipt flat and clear'),
                    Text('3. Capture all text clearly'),
                    Text('4. Avoid shadows and reflections'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Preview
            if (_selectedImage != null) ...[
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Upload Button
              ElevatedButton(
                onPressed: _isProcessing ? null : _uploadReceipt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing OCR...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload),
                          SizedBox(width: 8),
                          Text('Process Receipt'),
                        ],
                      ),
              ),
            ] else ...[
              // Capture Options
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No receipt selected',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Camera Button
              ElevatedButton.icon(
                onPressed: _captureFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture with Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              
              // Gallery Button
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
