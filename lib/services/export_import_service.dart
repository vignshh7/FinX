import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class ExportImportService {

  /// Export data as JSON file
  Future<void> exportAsJson(Map<String, dynamic> data) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(jsonString);
      final fileName = 'finx_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/json')],
        subject: 'Finx Data Export',
      );
    } catch (e) {
      throw Exception('Failed to export JSON: $e');
    }
  }

  /// Export data as CSV files (separate file for each data type)
  Future<void> exportAsCSV(Map<String, dynamic> data) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final List<XFile> filesToShare = [];

      if (data['expenses'] != null) {
        final csv = _convertExpensesToCsv(data['expenses']);
        filesToShare.add(XFile.fromData(
          utf8.encode(csv),
          name: 'finx_expenses_$timestamp.csv',
          mimeType: 'text/csv',
        ));
      }

      if (data['income'] != null) {
        final csv = _convertIncomeToCsv(data['income']);
        filesToShare.add(XFile.fromData(
          utf8.encode(csv),
          name: 'finx_income_$timestamp.csv',
          mimeType: 'text/csv',
        ));
      }

      if (data['budgets'] != null) {
        final csv = _convertBudgetsToCsv(data['budgets']);
        filesToShare.add(XFile.fromData(
          utf8.encode(csv),
          name: 'finx_budgets_$timestamp.csv',
          mimeType: 'text/csv',
        ));
      }

      if (data['savings'] != null) {
        final csv = _convertSavingsToCsv(data['savings']);
        filesToShare.add(XFile.fromData(
          utf8.encode(csv),
          name: 'finx_savings_$timestamp.csv',
          mimeType: 'text/csv',
        ));
      }

      if (data['bills'] != null) {
        final csv = _convertBillsToCsv(data['bills']);
        filesToShare.add(XFile.fromData(
          utf8.encode(csv),
          name: 'finx_bills_$timestamp.csv',
          mimeType: 'text/csv',
        ));
      }

      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(filesToShare, subject: 'Finx CSV Export');
      } else {
        throw Exception('No data available to export');
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Export a generated report as a formatted PDF
  Future<void> exportFinancialReport(Map<String, dynamic> report) async {
    try {
      final pdf = pw.Document();
      final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
      final dtFmt = DateFormat('dd MMM yyyy, hh:mm a');
      final now = DateTime.now();

      // ── Colour palette ──────────────────────────────────────────────────────
      const primaryColor  = PdfColor.fromInt(0xFF6C63FF);
      const accentColor   = PdfColor.fromInt(0xFF03DAC6);
      const headerBg      = PdfColor.fromInt(0xFF1E1E2E);
      const cardBg        = PdfColor.fromInt(0xFFF5F5F5);
      const positive      = PdfColor.fromInt(0xFF4CAF50);
      const negative      = PdfColor.fromInt(0xFFE53935);
      const textDark      = PdfColor.fromInt(0xFF212121);
      const textLight     = PdfColors.white;

      // ── Helper builders ─────────────────────────────────────────────────────
      pw.Widget sectionHeader(String title, {PdfColor color = primaryColor}) =>
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                color: textLight,
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );

      pw.Widget metricCard(String label, String value, {PdfColor valueColor = textDark}) =>
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: cardBg,
              border: pw.Border(
                left: pw.BorderSide(color: primaryColor, width: 3),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF757575))),
                pw.SizedBox(height: 2),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold, color: valueColor)),
              ],
            ),
          );

      pw.Widget breakdownTable(String col1, String col2, Map<String, dynamic> items) {
        if (items.isEmpty) {
          return pw.Text('No data', style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF757575)));
        }
        return pw.Table(
          border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(col1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(col2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right),
                ),
              ],
            ),
            ...items.entries.map((e) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    e.value is num
                        ? currencyFmt.format((e.value as num).toDouble())
                        : e.value.toString(),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            )),
          ],
        );
      }

      // ── Extract report sections ──────────────────────────────────────────────
      final exp  = (report['expense_summary']  as Map<String, dynamic>?) ?? {};
      final inc  = (report['income_summary']   as Map<String, dynamic>?) ?? {};
      final bud  = (report['budget_summary']   as Map<String, dynamic>?) ?? {};
      final sav  = (report['savings_summary']  as Map<String, dynamic>?) ?? {};
      final bil  = (report['bills_summary']    as Map<String, dynamic>?) ?? {};

      final totalIncome   = (inc['total_income']   as num?)?.toDouble() ?? 0.0;
      final totalExpenses = (exp['total_expenses'] as num?)?.toDouble() ?? 0.0;
      final netBalance    = totalIncome - totalExpenses;
      final savingsRate   = totalIncome > 0 ? (netBalance / totalIncome * 100) : 0.0;

      // ── Build PDF pages ──────────────────────────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            width: double.infinity,
            color: headerBg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FINX',
                        style: pw.TextStyle(
                          color: accentColor,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.Text('Comprehensive Financial Report',
                        style: const pw.TextStyle(color: textLight, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated: ${dtFmt.format(now)}',
                        style: const pw.TextStyle(color: textLight, fontSize: 8)),
                    if (report['report_period'] != null)
                      pw.Text(
                        'Period: ${DateFormat('MMM yyyy').format(DateTime.parse(report['report_period']['start']))} – ${DateFormat('MMM yyyy').format(DateTime.parse(report['report_period']['end']))}',
                        style: const pw.TextStyle(color: textLight, fontSize: 8),
                      ),
                  ],
                ),
              ],
            ),
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Finx – Personal Finance Manager',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E))),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E))),
            ],
          ),
          build: (context) => [
            pw.SizedBox(height: 12),

            // ── Executive Summary ──────────────────────────────────────────────
            sectionHeader('Executive Summary'),
            pw.SizedBox(height: 8),
            pw.GridView(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                metricCard('Total Income', currencyFmt.format(totalIncome), valueColor: positive),
                metricCard('Total Expenses', currencyFmt.format(totalExpenses), valueColor: negative),
                metricCard('Net Balance', currencyFmt.format(netBalance),
                    valueColor: netBalance >= 0 ? positive : negative),
                metricCard('Savings Rate',
                    '${savingsRate.toStringAsFixed(1)}%',
                    valueColor: savingsRate >= 20 ? positive : negative),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Expense Analysis ───────────────────────────────────────────────
            if (exp.isNotEmpty) ...[
              sectionHeader('Expense Analysis'),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.GridView(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          children: [
                            metricCard('Total Expenses',
                                currencyFmt.format((exp['total_expenses'] as num?)?.toDouble() ?? 0)),
                            metricCard('Avg. per Transaction',
                                currencyFmt.format((exp['average_expense'] as num?)?.toDouble() ?? 0)),
                            metricCard('# Transactions',
                                (exp['expense_count'] ?? 0).toString()),
                            metricCard('Top Category',
                                exp['top_category']?.toString() ?? 'N/A'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Category Breakdown',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        breakdownTable('Category', 'Amount',
                            Map<String, dynamic>.from(
                                (exp['category_breakdown'] as Map?)?.cast<String, dynamic>() ?? {})),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Income Analysis ────────────────────────────────────────────────
            if (inc.isNotEmpty) ...[
              sectionHeader('Income Analysis', color: positive),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.GridView(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: [
                        metricCard('Total Income',
                            currencyFmt.format((inc['total_income'] as num?)?.toDouble() ?? 0),
                            valueColor: positive),
                        metricCard('Avg. per Entry',
                            currencyFmt.format((inc['average_income'] as num?)?.toDouble() ?? 0)),
                        metricCard('# Entries',
                            (inc['income_count'] ?? 0).toString()),
                        metricCard('Primary Source',
                            inc['primary_source']?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Source Breakdown',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        breakdownTable('Source', 'Amount',
                            Map<String, dynamic>.from(
                                (inc['source_breakdown'] as Map?)?.cast<String, dynamic>() ?? {})),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Budget Overview ────────────────────────────────────────────────
            if (bud.isNotEmpty) ...[
              sectionHeader('Budget Overview', color: accentColor),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.GridView(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: [
                        metricCard('Total Budget',
                            currencyFmt.format((bud['total_budget'] as num?)?.toDouble() ?? 0)),
                        metricCard('Active Budgets',
                            (bud['active_budgets'] ?? 0).toString()),
                        metricCard('Total Budgets',
                            (bud['budget_count'] ?? 0).toString()),
                        metricCard('Avg. Budget',
                            currencyFmt.format((bud['average_budget'] as num?)?.toDouble() ?? 0)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Category Budgets',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        breakdownTable('Category', 'Budget',
                            Map<String, dynamic>.from(
                                (bud['category_budgets'] as Map?)?.cast<String, dynamic>() ?? {})),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Savings Goals ──────────────────────────────────────────────────
            if (sav.isNotEmpty) ...[
              sectionHeader('Savings Goals', color: const PdfColor.fromInt(0xFFFFA000)),
              pw.SizedBox(height: 8),
              pw.GridView(
                crossAxisCount: 4,
                childAspectRatio: 2.2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  metricCard('Target',
                      currencyFmt.format((sav['total_target'] as num?)?.toDouble() ?? 0)),
                  metricCard('Saved So Far',
                      currencyFmt.format((sav['total_saved'] as num?)?.toDouble() ?? 0),
                      valueColor: positive),
                  metricCard('Completion',
                      '${(((sav['completion_rate'] as num?)?.toDouble() ?? 0) * 100).toStringAsFixed(1)}%'),
                  metricCard('Goals: Done / Active',
                      '${sav['completed_goals'] ?? 0} / ${sav['active_goals'] ?? 0}'),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Bill Reminders ─────────────────────────────────────────────────
            if (bil.isNotEmpty) ...[
              sectionHeader('Bill Reminders', color: negative),
              pw.SizedBox(height: 8),
              pw.GridView(
                crossAxisCount: 4,
                childAspectRatio: 2.2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  metricCard('Total Billed',
                      currencyFmt.format((bil['total_amount'] as num?)?.toDouble() ?? 0)),
                  metricCard('Paid', (bil['paid_bills'] ?? 0).toString(), valueColor: positive),
                  metricCard('Overdue', (bil['overdue_bills'] ?? 0).toString(),
                      valueColor: negative),
                  metricCard('Payment Rate',
                      '${(((bil['payment_rate'] as num?)?.toDouble() ?? 0) * 100).toStringAsFixed(1)}%'),
                ],
              ),
              pw.SizedBox(height: 8),
              breakdownTable('Category', 'Amount',
                  Map<String, dynamic>.from(
                      (bil['category_amounts'] as Map?)?.cast<String, dynamic>() ?? {})),
              pw.SizedBox(height: 16),
            ],

            // ── Disclaimer ────────────────────────────────────────────────────
            pw.Divider(color: const PdfColor.fromInt(0xFFE0E0E0)),
            pw.SizedBox(height: 4),
            pw.Text(
              'This report was auto-generated by Finx on ${dtFmt.format(now)}. '
              'For personal use only.',
              style: const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFF9E9E9E)),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'finx_report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
        subject: 'Finx Comprehensive Financial Report',
      );
    } catch (e) {
      throw Exception('Failed to export PDF report: $e');
    }
  }

  /// Import data from JSON file
  Future<Map<String, dynamic>?> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final pickedFile = result.files.first;
      String content;

      if (pickedFile.bytes != null) {
        content = utf8.decode(pickedFile.bytes!);
      } else {
        throw Exception('Could not read selected file');
      }

      final data = jsonDecode(content) as Map<String, dynamic>;
      _validateImportData(data);
      return data;
    } catch (e) {
      throw Exception('Failed to import JSON: $e');
    }
  }

  /// Convert expenses data to CSV format
  String _convertExpensesToCsv(List<dynamic> expenses) {
    if (expenses.isEmpty) return 'No expense data to export';
    
    final headers = [
      'ID',
      'Amount',
      'Category',
      'Description',
      'Date',
      'Payment Method',
      'Created At',
      'Updated At'
    ];
    
    final rows = <List<String>>[headers];
    
    for (final expense in expenses) {
      final row = [
        expense['id']?.toString() ?? '',
        expense['amount']?.toString() ?? '0',
        expense['category']?.toString() ?? '',
        expense['description']?.toString() ?? '',
        expense['date']?.toString() ?? '',
        expense['payment_method']?.toString() ?? '',
        expense['created_at']?.toString() ?? '',
        expense['updated_at']?.toString() ?? '',
      ];
      rows.add(row);
    }
    
    return _convertRowsToCsv(rows);
  }

  /// Convert income data to CSV format
  String _convertIncomeToCsv(List<dynamic> income) {
    if (income.isEmpty) return 'No income data to export';
    
    final headers = [
      'ID',
      'Amount',
      'Source',
      'Description',
      'Date',
      'Created At',
      'Updated At'
    ];
    
    final rows = <List<String>>[headers];
    
    for (final inc in income) {
      final row = [
        inc['id']?.toString() ?? '',
        inc['amount']?.toString() ?? '0',
        inc['source']?.toString() ?? '',
        inc['description']?.toString() ?? '',
        inc['date']?.toString() ?? '',
        inc['created_at']?.toString() ?? '',
        inc['updated_at']?.toString() ?? '',
      ];
      rows.add(row);
    }
    
    return _convertRowsToCsv(rows);
  }

  /// Convert budgets data to CSV format
  String _convertBudgetsToCsv(List<dynamic> budgets) {
    if (budgets.isEmpty) return 'No budget data to export';
    
    final headers = [
      'ID',
      'Category',
      'Amount',
      'Period',
      'Alert Threshold',
      'Is Active',
      'Notes',
      'Created At',
      'Updated At'
    ];
    
    final rows = <List<String>>[headers];
    
    for (final budget in budgets) {
      final row = [
        budget['id']?.toString() ?? '',
        budget['category']?.toString() ?? '',
        budget['amount']?.toString() ?? '0',
        budget['period']?.toString() ?? '',
        budget['alert_threshold']?.toString() ?? '',
        budget['is_active']?.toString() ?? 'true',
        budget['notes']?.toString() ?? '',
        budget['created_at']?.toString() ?? '',
        budget['updated_at']?.toString() ?? '',
      ];
      rows.add(row);
    }
    
    return _convertRowsToCsv(rows);
  }

  /// Convert savings goals data to CSV format
  String _convertSavingsToCsv(List<dynamic> savings) {
    if (savings.isEmpty) return 'No savings data to export';
    
    final headers = [
      'ID',
      'Title',
      'Description',
      'Target Amount',
      'Current Amount',
      'Target Date',
      'Category',
      'Priority',
      'Is Completed',
      'Created At',
      'Updated At'
    ];
    
    final rows = <List<String>>[headers];
    
    for (final goal in savings) {
      final row = [
        goal['id']?.toString() ?? '',
        goal['title']?.toString() ?? '',
        goal['description']?.toString() ?? '',
        goal['target_amount']?.toString() ?? '0',
        goal['current_amount']?.toString() ?? '0',
        goal['target_date']?.toString() ?? '',
        goal['category']?.toString() ?? '',
        goal['priority']?.toString() ?? '',
        goal['is_completed']?.toString() ?? 'false',
        goal['created_at']?.toString() ?? '',
        goal['updated_at']?.toString() ?? '',
      ];
      rows.add(row);
    }
    
    return _convertRowsToCsv(rows);
  }

  /// Convert bill reminders data to CSV format
  String _convertBillsToCsv(List<dynamic> bills) {
    if (bills.isEmpty) return 'No bills data to export';
    
    final headers = [
      'ID',
      'Title',
      'Description',
      'Amount',
      'Due Date',
      'Category',
      'Frequency',
      'Priority',
      'Is Recurring',
      'Is Paid',
      'Paid Date',
      'Payment Method',
      'Status',
      'Created At',
      'Updated At'
    ];
    
    final rows = <List<String>>[headers];
    
    for (final bill in bills) {
      final row = [
        bill['id']?.toString() ?? '',
        bill['title']?.toString() ?? '',
        bill['description']?.toString() ?? '',
        bill['amount']?.toString() ?? '0',
        bill['due_date']?.toString() ?? '',
        bill['category']?.toString() ?? '',
        bill['frequency']?.toString() ?? '',
        bill['priority']?.toString() ?? '',
        bill['is_recurring']?.toString() ?? 'false',
        bill['is_paid']?.toString() ?? 'false',
        bill['paid_date']?.toString() ?? '',
        bill['payment_method']?.toString() ?? '',
        bill['status']?.toString() ?? '',
        bill['created_at']?.toString() ?? '',
        bill['updated_at']?.toString() ?? '',
      ];
      rows.add(row);
    }
    
    return _convertRowsToCsv(rows);
  }

  /// Convert rows to CSV format with proper escaping
  String _convertRowsToCsv(List<List<String>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        // Escape quotes and wrap in quotes if necessary
        if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
          return '"${cell.replaceAll('"', '""')}"';
        }
        return cell;
      }).join(',');
    }).join('\n');
  }

  /// Validate imported data structure
  void _validateImportData(Map<String, dynamic> data) {
    // Check for required metadata
    if (!data.containsKey('metadata')) {
      throw Exception('Invalid import file: missing metadata');
    }

    final metadata = data['metadata'] as Map<String, dynamic>;
    
    if (!metadata.containsKey('exported_at')) {
      throw Exception('Invalid import file: missing export timestamp');
    }

    if (!metadata.containsKey('format_version')) {
      throw Exception('Invalid import file: missing format version');
    }

    // Validate format version compatibility
    final formatVersion = metadata['format_version'] as String;
    if (formatVersion != '1.0') {
      throw Exception('Unsupported format version: $formatVersion');
    }

    // Validate data types
    final dataTypes = metadata['data_types'] as List<dynamic>?;
    if (dataTypes != null) {
      for (final type in dataTypes) {
        if (!_isValidDataType(type.toString())) {
          throw Exception('Unknown data type: $type');
        }
      }
    }
  }

  /// Check if data type is valid
  bool _isValidDataType(String dataType) {
    const validTypes = ['expenses', 'income', 'budgets', 'savings', 'bills'];
    return validTypes.contains(dataType);
  }

  /// Generate financial summary report
  Map<String, dynamic> generateFinancialReport(Map<String, dynamic> data) {
    final report = <String, dynamic>{};
    final now = DateTime.now();
    
    // Summary metrics
    report['generated_at'] = now.toIso8601String();
    report['report_period'] = {
      'start': DateTime(now.year, now.month - 11, 1).toIso8601String(), // Last 12 months
      'end': now.toIso8601String(),
    };

    // Expense analysis
    if (data['expenses'] != null) {
      final expenses = data['expenses'] as List<dynamic>;
      report['expense_summary'] = _analyzeExpenses(expenses);
    }

    // Income analysis
    if (data['income'] != null) {
      final income = data['income'] as List<dynamic>;
      report['income_summary'] = _analyzeIncome(income);
    }

    // Budget analysis
    if (data['budgets'] != null) {
      final budgets = data['budgets'] as List<dynamic>;
      report['budget_summary'] = _analyzeBudgets(budgets);
    }

    // Savings analysis
    if (data['savings'] != null) {
      final savings = data['savings'] as List<dynamic>;
      report['savings_summary'] = _analyzeSavings(savings);
    }

    // Bills analysis
    if (data['bills'] != null) {
      final bills = data['bills'] as List<dynamic>;
      report['bills_summary'] = _analyzeBills(bills);
    }

    return report;
  }

  Map<String, dynamic> _analyzeExpenses(List<dynamic> expenses) {
    double totalExpenses = 0;
    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCount = {};

    for (final expense in expenses) {
      final amount = (expense['amount'] ?? 0.0).toDouble();
      final category = expense['category']?.toString() ?? 'Other';
      
      totalExpenses += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    return {
      'total_expenses': totalExpenses,
      'average_expense': expenses.isNotEmpty ? totalExpenses / expenses.length : 0,
      'expense_count': expenses.length,
      'category_breakdown': categoryTotals,
      'category_count': categoryCount,
      'top_category': categoryTotals.isNotEmpty
          ? categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  Map<String, dynamic> _analyzeIncome(List<dynamic> income) {
    double totalIncome = 0;
    final Map<String, double> sourceTotals = {};

    for (final inc in income) {
      final amount = (inc['amount'] ?? 0.0).toDouble();
      final source = inc['source']?.toString() ?? 'Other';
      
      totalIncome += amount;
      sourceTotals[source] = (sourceTotals[source] ?? 0.0) + amount;
    }

    return {
      'total_income': totalIncome,
      'average_income': income.isNotEmpty ? totalIncome / income.length : 0,
      'income_count': income.length,
      'source_breakdown': sourceTotals,
      'primary_source': sourceTotals.isNotEmpty
          ? sourceTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  Map<String, dynamic> _analyzeBudgets(List<dynamic> budgets) {
    double totalBudget = 0;
    int activeBudgets = 0;
    final Map<String, double> categoryBudgets = {};

    for (final budget in budgets) {
      final amount = (budget['amount'] ?? 0.0).toDouble();
      final category = budget['category']?.toString() ?? 'Other';
      final isActive = budget['is_active'] ?? true;
      
      totalBudget += amount;
      if (isActive) activeBudgets++;
      categoryBudgets[category] = amount;
    }

    return {
      'total_budget': totalBudget,
      'active_budgets': activeBudgets,
      'budget_count': budgets.length,
      'category_budgets': categoryBudgets,
      'average_budget': budgets.isNotEmpty ? totalBudget / budgets.length : 0,
    };
  }

  Map<String, dynamic> _analyzeSavings(List<dynamic> savings) {
    double totalTarget = 0;
    double totalSaved = 0;
    int completedGoals = 0;
    final Map<String, int> categoryCount = {};

    for (final goal in savings) {
      final target = (goal['target_amount'] ?? 0.0).toDouble();
      final current = (goal['current_amount'] ?? 0.0).toDouble();
      final completed = goal['is_completed'] ?? false;
      final category = goal['category']?.toString() ?? 'Other';
      
      totalTarget += target;
      totalSaved += current;
      if (completed) completedGoals++;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    return {
      'total_target': totalTarget,
      'total_saved': totalSaved,
      'completion_rate': totalTarget > 0 ? totalSaved / totalTarget : 0,
      'completed_goals': completedGoals,
      'active_goals': savings.length - completedGoals,
      'goals_count': savings.length,
      'category_distribution': categoryCount,
    };
  }

  Map<String, dynamic> _analyzeBills(List<dynamic> bills) {
    double totalAmount = 0;
    int paidBills = 0;
    int overdueBills = 0;
    final Map<String, int> categoryCount = {};
    final Map<String, double> categoryAmounts = {};

    for (final bill in bills) {
      final amount = (bill['amount'] ?? 0.0).toDouble();
      final isPaid = bill['is_paid'] ?? false;
      final category = bill['category']?.toString() ?? 'Other';
      final dueDate = bill['due_date'] != null ? DateTime.parse(bill['due_date']) : null;
      
      totalAmount += amount;
      if (isPaid) {
        paidBills++;
      } else if (dueDate != null && dueDate.isBefore(DateTime.now())) {
        overdueBills++;
      }
      
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      categoryAmounts[category] = (categoryAmounts[category] ?? 0.0) + amount;
    }

    return {
      'total_amount': totalAmount,
      'paid_bills': paidBills,
      'overdue_bills': overdueBills,
      'pending_bills': bills.length - paidBills - overdueBills,
      'bills_count': bills.length,
      'payment_rate': bills.isNotEmpty ? paidBills / bills.length : 0,
      'category_count': categoryCount,
      'category_amounts': categoryAmounts,
    };
  }
}