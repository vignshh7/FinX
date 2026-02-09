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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _buildContent(),
                              SizedBox(height: bottomPadding + 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Custom App Bar
        _buildAppBar(),
        
        // Main Content
        Expanded(
          child: _selectedImage == null 
              ? _buildScannerInterface()
              : _buildImagePreview(),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
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
                color: FintechColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: FintechColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Scan Receipt',
              style: FintechTypography.h4.copyWith(
                color: FintechColors.textPrimary,
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
              color: FintechColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Take a photo or select from gallery\nOur AI will automatically extract expense details',
            style: FintechTypography.bodyLarge.copyWith(
              color: FintechColors.textSecondary,
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
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
              elevation: 0,
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
              style: FintechTypography.buttonLarge,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: FintechColors.textPrimary,
              side: const BorderSide(
                color: FintechColors.borderColor,
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
    final tips = [
      {'icon': Icons.flash_on, 'text': 'Use good lighting'},
      {'icon': Icons.center_focus_strong, 'text': 'Focus on the receipt'},
      {'icon': Icons.straighten, 'text': 'Keep it straight'},
    ];

    return FintechCard(
      backgroundColor: FintechColors.surfaceColor,
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
                  color: FintechColors.textPrimary,
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
                  color: FintechColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  tip['text'] as String,
                  style: FintechTypography.bodySmall.copyWith(
                    color: FintechColors.textSecondary,
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
        setState(() {
          _selectedImage = File(photo.path);
        });
        _animationController.reset();
        _animationController.forward();
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
        setState(() {
          _selectedImage = File(image.path);
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _showError('Failed to select image. Please try again.');
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

      if (result != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OCRResultScreen(),
            ),
          );
        }
      } else {
        _showError('Failed to process receipt. Please try again.');
      }
    } catch (e) {
      _showError('Processing failed: ${e.toString()}');
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
}