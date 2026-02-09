import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/expense_provider.dart';
import 'ocr_result_screen.dart';

class ModernReceiptScannerScreen extends StatefulWidget {
  const ModernReceiptScannerScreen({super.key});

  @override
  State<ModernReceiptScannerScreen> createState() => _ModernReceiptScannerScreenState();
}

class _ModernReceiptScannerScreenState extends State<ModernReceiptScannerScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  children: [
                    _buildAppBar(theme),
                    Expanded(
                      child: _selectedImage == null 
                          ? _buildScannerInterface()
                          : _buildImagePreview(),
                    ),
                    SizedBox(height: bottomPadding + 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Scan Receipt',
              style: FintechTypography.h4.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_selectedImage != null)
            GestureDetector(
              onTap: _clearImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FintechColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: FintechColors.errorColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerInterface() {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.6);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Main Scanner Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: FintechColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: FintechColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title and Subtitle
          Text(
            'Scan Your Receipt',
            style: FintechTypography.h2.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Take a photo or select from gallery\nOur AI will automatically extract expense details',
            style: FintechTypography.bodyLarge.copyWith(
              color: secondaryTextColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Action Buttons
          _buildActionButtons(),
          
          const SizedBox(height: 32),
          
          // Tips Section
          _buildTipsSection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Camera Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _captureFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              'Take Photo',
              style: FintechTypography.buttonLarge,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FintechColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Gallery Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              'Choose from Gallery',
              style: FintechTypography.buttonLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.6);
    
    final tips = [
      {'icon': Icons.flash_on, 'text': 'Use good lighting'},
      {'icon': Icons.center_focus_strong, 'text': 'Focus on the receipt'},
      {'icon': Icons.straighten, 'text': 'Keep it straight'},
    ];

    return FintechCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: FintechColors.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for best results',
                style: FintechTypography.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  tip['icon'] as IconData,
                  size: 16,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 12),
                Text(
                  tip['text'] as String,
                  style: FintechTypography.bodySmall.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image Preview
          Expanded(
            child: FintechCard(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Process Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processImage,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.psychology),
              label: Text(
                _isProcessing ? 'Processing...' : 'Extract Details',
                style: FintechTypography.buttonLarge,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FintechColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Retake Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton.icon(
              onPressed: _isProcessing ? null : _clearImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                'Take Another Photo',
                style: FintechTypography.buttonLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        final imageFile = File(photo.path);
        
        // Validate image
        if (await _validateImage(imageFile)) {
          setState(() {
            _selectedImage = imageFile;
          });
          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      _showError('Failed to capture image. Please try again.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        final imageFile = File(image.path);
        
        // Validate image
        if (await _validateImage(imageFile)) {
          setState(() {
            _selectedImage = imageFile;
          });
          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      _showError('Failed to select image. Please try again.');
    }
  }

  Future<bool> _validateImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        _showError('Image file not found.');
        return false;
      }

      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      
      if (fileSize > maxSize) {
        _showError('Image too large. Please select an image under 10MB.');
        return false;
      }
      
      if (fileSize == 0) {
        _showError('Invalid image file.');
        return false;
      }

      return true;
    } catch (e) {
      _showError('Failed to validate image.');
      return false;
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final result = await expenseProvider.uploadReceipt(_selectedImage!);

      if (result != null && mounted) {
        // Success - navigate to result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OCRResultScreen(),
          ),
        );
      } else {
        if (mounted) {
          _showErrorWithRetry(
            'Processing Failed',
            'We couldn\'t extract data from this receipt. Please try again or enter details manually.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to process receipt.';
        
        if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
          errorMessage = 'Request timed out. Please check your internet connection.';
        } else if (e.toString().contains('No internet') || e.toString().contains('SocketException')) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e.toString().contains('Not authenticated')) {
          errorMessage = 'Session expired. Please login again.';
        } else if (e.toString().contains('upload')) {
          errorMessage = 'Failed to upload image. Please try again.';
        }
        
        _showErrorWithRetry('Upload Failed', errorMessage);
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _clearImage() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImage = null;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FintechTypography.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: FintechColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorWithRetry(String title, String message) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FintechColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: FintechColors.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: FintechTypography.h5.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: FintechTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearImage();
            },
            child: const Text('Take Another Photo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FintechColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}