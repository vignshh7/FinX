import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class OCRResultScreen extends StatefulWidget {
  const OCRResultScreen({super.key});

  @override
  State<OCRResultScreen> createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _storeController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _itemsController;
  
  String _selectedCategory = ExpenseCategory.other;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final ocrResult = expenseProvider.lastOcrResult;
    
    _storeController = TextEditingController(text: ocrResult?.store ?? '');
    _amountController = TextEditingController(
      text: ocrResult?.amount.toStringAsFixed(2) ?? '0.00',
    );
    _dateController = TextEditingController(text: ocrResult?.date ?? '');
    _itemsController = TextEditingController(
      text: ocrResult?.items.join(', ') ?? '',
    );
    _selectedCategory = ocrResult?.predictedCategory ?? ExpenseCategory.other;
  }

  @override
  void dispose() {
    _storeController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final ocrResult = expenseProvider.lastOcrResult;

    final expense = Expense(
      userId: 1, // This will be set from auth in backend
      store: _storeController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: DateTime.parse(_dateController.text),
      items: _itemsController.text.isEmpty
          ? null
          : _itemsController.text.split(',').map((e) => e.trim()).toList(),
      rawOcrText: '${ocrResult?.store ?? ''} ${ocrResult?.items.join(' ') ?? ''}',
    );

    final success = await expenseProvider.addExpense(expense);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      expenseProvider.clearOcrResult();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expenseProvider.error ?? 'Failed to save expense'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ocrResult = expenseProvider.lastOcrResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review OCR Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI Confidence Card
              if (ocrResult != null && ocrResult.confidence > 0)
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Prediction',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Category: $_selectedCategory (${(ocrResult.confidence * 100).toStringAsFixed(1)}% confidence)',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Store Name
              TextFormField(
                controller: _storeController,
                decoration: InputDecoration(
                  labelText: 'Store Name',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter store name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: themeProvider.currency,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(ExpenseCategory.getIcon(_selectedCategory)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ExpenseCategory.all.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          ExpenseCategory.getIcon(category),
                          color: ExpenseCategory.getColor(category),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Items (Optional)
              TextFormField(
                controller: _itemsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Items (comma separated, optional)',
                  prefixIcon: const Icon(Icons.list),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'e.g., Milk, Bread, Eggs',
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
