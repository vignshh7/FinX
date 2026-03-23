import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/premium_buttons.dart';
import '../core/widgets/premium_cards.dart';
import '../core/widgets/premium_inputs.dart';
import '../core/widgets/premium_indicators.dart';
import '../core/widgets/premium_dialogs.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import 'home/home_screen.dart';

/// Premium OCR Result Screen with editable fields, confidence indicators, and AI explanations
class OCRResultScreenPremium extends StatefulWidget {
  const OCRResultScreenPremium({super.key});

  @override
  State<OCRResultScreenPremium> createState() => _OCRResultScreenPremiumState();
}

class _OCRResultScreenPremiumState extends State<OCRResultScreenPremium>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _storeController;
  late TextEditingController _amountController;
  late TextEditingController _itemsController;
  
  String _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
    
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final ocrResult = expenseProvider.lastOcrResult;
    
    _storeController = TextEditingController(text: ocrResult?.store ?? '');
    _amountController = TextEditingController(
      text: ocrResult?.amount.toStringAsFixed(2) ?? '0.00',
    );
    _itemsController = TextEditingController(
      text: ocrResult?.items.join(', ') ?? '',
    );
    _selectedCategory = ocrResult?.predictedCategory ?? ExpenseCategory.other;
    
    // Parse date if available
    if (ocrResult?.date != null && ocrResult!.date.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(ocrResult.date);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _storeController.dispose();
    _amountController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      PremiumSnackBar.showError(context, 'Please fill all required fields');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    HapticFeedback.mediumImpact();

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final ocrResult = expenseProvider.lastOcrResult;

    final expense = Expense(
      userId: 1,
      store: _storeController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: _selectedDate,
      items: _itemsController.text.isEmpty
          ? null
          : _itemsController.text.split(',').map((e) => e.trim()).toList(),
      rawOcrText: ocrResult?.rawText ?? '',
    );

    final success = await expenseProvider.addExpense(expense);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      expenseProvider.clearOcrResult();
      HapticFeedback.heavyImpact();
      PremiumSnackBar.showSuccess(context, 'Expense saved successfully!');
      
      // Navigate to home screen and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      PremiumSnackBar.showError(context, 'Failed to save expense');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final ocrResult = expenseProvider.lastOcrResult;
    final confidence = ocrResult?.confidence ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review & Save', style: AppTypography.headlineSmall),
        actions: [
          PremiumIconButton(
            icon: Icons.info_outline,
            onPressed: () {
              _showAIExplanation();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screenEdgePadding,
            children: [
              // AI Confidence Card
              GradientCard(
                gradientColors: AppColors.getConfidenceColor(confidence) == AppColors.success
                    ? AppColors.successGradient
                    : AppColors.warningGradient,
                child: Row(
                  children: [
                    Icon(
                      confidence >= 0.7
                          ? Icons.verified
                          : Icons.info_outline,
                      color: Colors.white,
                      size: AppSpacing.iconLg,
                    ),
                    AppSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            confidence >= 0.7
                                ? 'High Confidence'
                                : confidence >= 0.4
                                    ? 'Medium Confidence'
                                    : 'Low Confidence',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          AppSpacing.vSpaceXs,
                          Text(
                            'AI extracted data with ${(confidence * 100).toInt()}% confidence',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConfidenceIndicator(
                      confidence: confidence,
                      showPercentage: true,
                    ),
                  ],
                ),
              ),

              AppSpacing.vSpaceXl,

              // Editable Fields Section
              Text(
                'Expense Details',
                style: AppTypography.titleLarge,
              ),
              
              AppSpacing.vSpaceMd,
              
              // Store name
              PremiumTextField(
                controller: _storeController,
                label: 'Store / Merchant',
                prefixIcon: Icons.store,
                onChanged: (_) => setState(() {}),
              ),
              
              AppSpacing.vSpaceMd,
              
              // Amount
              AmountTextField(
                controller: _amountController,
                label: 'Amount',
                onChanged: (_) => setState(() {}),
              ),
              
              AppSpacing.vSpaceMd,
              
              // Date
              DatePickerField(
                selectedDate: _selectedDate,
                label: 'Date',
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              
              AppSpacing.vSpaceMd,
              
              // Items
              PremiumTextField(
                controller: _itemsController,
                label: 'Items (comma separated)',
                prefixIcon: Icons.shopping_cart,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              
              AppSpacing.vSpaceXl,
              
              // Category Selection
              Text(
                'Category',
                style: AppTypography.titleLarge,
              ),
              
              AppSpacing.vSpaceSm,
              
              // AI Suggested Category
              if (ocrResult?.predictedCategory != null)
                Container(
                  padding: AppSpacing.cardInnerPadding,
                  decoration: BoxDecoration(
                    color: AppColors.accentEmerald.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(
                      color: AppColors.accentEmerald.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.accentEmerald,
                        size: AppSpacing.iconSm,
                      ),
                      AppSpacing.hSpaceSm,
                      Text(
                        'AI Suggested: ${ocrResult!.predictedCategory}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              AppSpacing.vSpaceMd,
              
              // Category chips
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: ExpenseCategory.allCategories.map((category) {
                  return CategoryChip(
                    category: category,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                }).toList(),
              ),
              
              AppSpacing.vSpaceXxl,
              
              // Save button
              PremiumButton(
                text: 'Save Expense',
                icon: Icons.check_circle,
                onPressed: _saveExpense,
                isLoading: _isSaving,
                height: AppSpacing.buttonHeightLg,
              ),
              
              AppSpacing.vSpaceLg,
            ],
          ),
        ),
      ),
    );
  }

  void _showAIExplanation() {
    PremiumBottomSheet.show(
      context: context,
      title: 'AI Extraction Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // How it works
          InfoCard(
            icon: Icons.auto_awesome,
            title: 'How AI Extracted Data',
            subtitle: 'Our AI analyzed your receipt using advanced OCR and NLP algorithms',
            iconColor: AppColors.primaryIndigo,
          ),
          
          AppSpacing.vSpaceMd,
          
          // Extraction details
          InfoCard(
            icon: Icons.receipt_long,
            title: 'Store Name',
            subtitle: 'Detected from header section',
            iconColor: AppColors.accentEmerald,
          ),
          
          AppSpacing.vSpaceMd,
          
          InfoCard(
            icon: Icons.attach_money,
            title: 'Amount',
            subtitle: 'Extracted from total field',
            iconColor: AppColors.accentEmerald,
          ),
          
          AppSpacing.vSpaceMd,
          
          InfoCard(
            icon: Icons.calendar_today,
            title: 'Date',
            subtitle: 'Parsed from timestamp',
            iconColor: AppColors.accentEmerald,
          ),
          
          AppSpacing.vSpaceMd,
          
          // Category prediction
          InfoCard(
            icon: Icons.category,
            title: 'Category Prediction',
            subtitle: 'ML model analyzed store name and items to suggest category',
            iconColor: AppColors.info,
          ),
          
          AppSpacing.vSpaceXl,
          
          // Confidence explanation
          Container(
            padding: AppSpacing.cardInnerPadding,
            decoration: BoxDecoration(
              color: AppColors.infoLight.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.info,
                    ),
                    AppSpacing.hSpaceSm,
                    Text(
                      'Tip',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpaceSm,
                Text(
                  'You can edit any field before saving. The AI is here to help, but you have full control!',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
