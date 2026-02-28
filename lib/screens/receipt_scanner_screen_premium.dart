import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/premium_buttons.dart';
import '../core/widgets/premium_dialogs.dart';
import '../providers/expense_provider.dart';
import 'ocr_result_screen_premium.dart';

/// Premium OCR Receipt Scanner with instant camera launch and framing guide
class ReceiptScannerScreenPremium extends StatefulWidget {
  const ReceiptScannerScreenPremium({super.key});

  @override
  State<ReceiptScannerScreenPremium> createState() => _ReceiptScannerScreenPremiumState();
}

class _ReceiptScannerScreenPremiumState extends State<ReceiptScannerScreenPremium>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Instant camera launch with haptic feedback
  Future<void> _captureFromCamera() async {
    try {
      HapticFeedback.mediumImpact();
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        _animationController.forward();
        _showImagePreview();
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackBar.showError(context, 'Failed to capture image');
      }
    }
  }

  /// Gallery picker
  Future<void> _pickFromGallery() async {
    try {
      HapticFeedback.lightImpact();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _animationController.forward();
        _showImagePreview();
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackBar.showError(context, 'Failed to pick image');
      }
    }
  }

  /// Show image preview with smooth animation
  void _showImagePreview() {
    PremiumBottomSheet.show(
      context: context,
      title: 'Preview Receipt',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusMd,
            child: Image.file(
              _selectedImage!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          AppSpacing.vSpaceXl,
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: PremiumOutlinedButton(
                  text: 'Retake',
                  icon: Icons.refresh,
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                    _captureFromCamera();
                  },
                ),
              ),
              AppSpacing.hSpaceMd,
              Expanded(
                child: PremiumButton(
                  text: 'Process',
                  icon: Icons.auto_awesome,
                  onPressed: () {
                    Navigator.pop(context);
                    _processReceipt();
                  },
                  isLoading: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compress image with quality preservation
  Future<File> _compressImage(File file) async {
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

    // Compress with high quality
    final compressedBytes = img.encodeJpg(image, quality: 90);

    // Save compressed image
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File(
      '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

  /// Process receipt with animated progress
  Future<void> _processReceipt() async {
    if (_selectedImage == null) return;

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
    });

    try {
      // Show processing dialog
      _showProcessingDialog();

      // Simulate progressive steps
      await _updateProgress(0.2, 'Preparing image...');
      final compressedImage = await _compressImage(_selectedImage!);

      await _updateProgress(0.4, 'Uploading to server...');

      await _updateProgress(0.6, 'Extracting text...');
      await expenseProvider.uploadReceipt(compressedImage);

      await _updateProgress(0.8, 'Analyzing data...');
      await Future.delayed(const Duration(milliseconds: 500));

      await _updateProgress(1.0, 'Complete!');
      HapticFeedback.mediumImpact();

      if (!mounted) return;

      // Close processing dialog
      Navigator.pop(context);

      // Navigate to OCR result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OCRResultScreenPremium(),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close processing dialog
        PremiumSnackBar.showError(context, 'Failed to process receipt');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
          _selectedImage = null;
        });
      }
    }
  }

  Future<void> _updateProgress(double progress, String message) async {
    setState(() {
      _processingProgress = progress;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Padding(
            padding: AppSpacing.allPadding(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                
                AppSpacing.vSpaceXl,
                
                Text(
                  'Processing Receipt',
                  style: AppTypography.headlineSmall,
                ),
                
                AppSpacing.vSpaceSm,
                
                Text(
                  'AI is analyzing your receipt...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                AppSpacing.vSpaceXl,
                
                // Progress bar
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: _processingProgress,
                    backgroundColor: AppColors.dividerLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryIndigo,
                    ),
                    minHeight: 6,
                  ),
                ),
                
                AppSpacing.vSpaceSm,
                
                Text(
                  '${(_processingProgress * 100).toInt()}%',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primaryIndigo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Receipt', style: AppTypography.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              PremiumDialog.show(
                context: context,
                title: 'How to Scan',
                message: '1. Place receipt on flat surface\n'
                  '2. Ensure good lighting\n'
                  '3. Keep camera steady\n'
                  '4. Capture entire receipt\n\n'
                  'AI will automatically extract all details!',
                confirmText: 'Got it',
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.backgroundLight, AppColors.surfaceLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.screenEdgePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryIndigo.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  
                  AppSpacing.vSpaceXxl,
                  
                  Text(
                    'Scan Your Receipt',
                    style: AppTypography.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  
                  AppSpacing.vSpaceMd,
                  
                  Text(
                    'AI will automatically extract all details\nfrom your receipt in seconds',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(),
                  
                  // Camera button - primary action
                  PremiumButton(
                    text: 'Open Camera',
                    icon: Icons.camera_alt,
                    onPressed: _captureFromCamera,
                    isLoading: _isProcessing,
                    height: AppSpacing.buttonHeightLg,
                  ),
                  
                  AppSpacing.vSpaceMd,
                  
                  // Gallery button - secondary action
                  PremiumOutlinedButton(
                    text: 'Choose from Gallery',
                    icon: Icons.photo_library,
                    onPressed: _pickFromGallery,
                  ),
                  
                  AppSpacing.vSpaceXl,
                  
                  // Features list
                  Container(
                    padding: AppSpacing.cardInnerPadding,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withOpacity(0.5)
                          : AppColors.surfaceLight.withOpacity(0.5),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeature(Icons.flash_on, 'Fast'),
                        _buildFeature(Icons.auto_awesome, 'AI Powered'),
                        _buildFeature(Icons.check_circle, 'Accurate'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isDark
              ? AppColors.primaryIndigoLight
              : AppColors.primaryIndigo,
        ),
        AppSpacing.vSpaceXs,
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
