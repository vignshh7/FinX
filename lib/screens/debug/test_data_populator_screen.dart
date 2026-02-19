import 'package:flutter/material.dart';
import '../../test_data_populator.dart';

/// Debug panel for populating test data within the app
class TestDataPopulatorWidget extends StatefulWidget {
  const TestDataPopulatorWidget({super.key});

  @override
  State<TestDataPopulatorWidget> createState() => _TestDataPopulatorWidgetState();
}

class _TestDataPopulatorWidgetState extends State<TestDataPopulatorWidget> {
  bool _isLoading = false;
  String _status = '';
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Populator'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test Data Population',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will add realistic test data to your account including:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 90-150 expenses (last 6 months)'),
                    const Text('• 20+ income records'),
                    const Text('• 5 budget categories'),
                    const Text('• 6 savings goals'),
                    const Text('• 10 bill reminders'),
                    const SizedBox(height: 16),
                    const Text(
                      '⚠️ Note: This will add real data to your account. Make sure this is a test account.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_status.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $_status',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _populateTestData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isLoading ? 'Populating Data...' : 'Populate Test Data',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Activity Log:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color? textColor;
                        if (log.contains('✅')) {
                          textColor = Colors.green;
                        } else if (log.contains('❌')) {
                          textColor = Colors.red;
                        } else if (log.contains('💰') || 
                                   log.contains('💵') ||
                                   log.contains('🎯') ||
                                   log.contains('📋')) {
                          textColor = Colors.blue;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _populateTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting data population...';
      _logs.clear();
    });

    try {
      final populator = TestDataPopulator();
      
      // Set up a callback to capture logs
      populator.setLogCallback((String message) {
        setState(() {
          _logs.add(message);
        });
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logs.isNotEmpty) {
            // Auto-scroll to show latest logs
          }
        });
      });
      
      await populator.populateTestData();
      
      setState(() {
        _status = 'Completed successfully! 🎉';
        _isLoading = false;
      });
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success! 🎉'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Test data has been populated successfully!'),
                SizedBox(height: 16),
                Text('You can now:'),
                Text('• Check your Dashboard for overview'),
                Text('• Explore Budget tracking'),
                Text('• Review Savings Goals'),
                Text('• Manage Bill Reminders'),
                Text('• Use AI Analytics'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close this screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _status = 'Error occurred: $e';
        _isLoading = false;
        _logs.add('❌ Error: $e');
      });
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error ❌'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to populate test data: $e'),
                const SizedBox(height: 16),
                const Text('Troubleshooting tips:'),
                const Text('• Make sure you are logged in'),
                const Text('• Check your internet connection'),
                const Text('• Verify backend server is running'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// Extension to easily add test data populator to debug builds
extension TestDataDebugExtension on BuildContext {
  /// Navigate to test data populator (only in debug mode)
  void openTestDataPopulator() {
    assert(() {
      Navigator.of(this).push(
        MaterialPageRoute(
          builder: (context) => const TestDataPopulatorWidget(),
        ),
      );
      return true;
    }());
  }
}