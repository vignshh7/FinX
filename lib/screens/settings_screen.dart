import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CNY'];

  Future<void> _showBackendUrlDialog() async {
    final controller = TextEditingController(text: ApiService.baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Base URL',
            hintText: 'http://10.0.2.2:5000/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final nextUrl = controller.text.trim();
      if (nextUrl.isEmpty) return;
      await ApiService.setBaseUrl(nextUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend URL set to ${ApiService.baseUrl}')),
      );
      setState(() {});
    }
  }

  void _showBudgetDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final budgetController = TextEditingController(
      text: themeProvider.monthlyBudget.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monthly Budget',
            prefixText: '${themeProvider.currency} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(budgetController.text);
              if (budget != null) {
                themeProvider.setMonthlyBudget(budget);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User Info
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(authProvider.user?.name ?? 'User'),
                          subtitle: Text(authProvider.user?.email ?? ''),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Budget Settings
                      Text(
                        'Budget',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet),
                          title: const Text('Monthly Budget'),
                          subtitle: Text(
                            themeProvider.monthlyBudget > 0
                                ? '${themeProvider.currency} ${themeProvider.monthlyBudget.toStringAsFixed(2)}'
                                : 'Not set',
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: _showBudgetDialog,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Appearance
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: Icon(
                                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              ),
                              title: const Text('Dark Mode'),
                              subtitle: const Text('Toggle dark theme'),
                              value: themeProvider.isDarkMode,
                              onChanged: (value) {
                                themeProvider.toggleTheme();
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.attach_money),
                              title: const Text('Currency'),
                              subtitle: Text(themeProvider.currency),
                              trailing: const Icon(Icons.arrow_drop_down),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => SimpleDialog(
                                    title: const Text('Select Currency'),
                                    children: _currencies.map((currency) {
                                      return SimpleDialogOption(
                                        onPressed: () {
                                          themeProvider.setCurrency(currency);
                                          Navigator.of(context).pop();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            currency,
                                            style: TextStyle(
                                              fontWeight: currency == themeProvider.currency
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: currency == themeProvider.currency
                                                  ? Theme.of(context).primaryColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // About
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.cloud_outlined),
                              title: const Text('Backend URL'),
                              subtitle: Text(ApiService.baseUrl),
                              trailing: const Icon(Icons.edit),
                              onTap: _showBackendUrlDialog,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.info),
                              title: const Text('App Version'),
                              subtitle: const Text('1.0.0'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.bug_report),
                              title: const Text('Report a Bug'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // TODO: Implement bug report
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout
                      ElevatedButton.icon(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                      SizedBox(height: bottomPadding + 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
