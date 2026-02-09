import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../models/subscription_model.dart';

class SubscriptionTrackerScreen extends StatefulWidget {
  const SubscriptionTrackerScreen({super.key});

  @override
  State<SubscriptionTrackerScreen> createState() => _SubscriptionTrackerScreenState();
}

class _SubscriptionTrackerScreenState extends State<SubscriptionTrackerScreen> {
  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.fetchSubscriptions();
  }

  void _showAddSubscriptionDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String frequency = 'monthly';
    DateTime renewalDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    hintText: 'e.g., Netflix, Spotify',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      frequency = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Renewal Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(renewalDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: renewalDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        renewalDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || amountController.text.isEmpty) {
                  return;
                }

                final subscription = Subscription(
                  userId: 1,
                  name: nameController.text,
                  amount: double.parse(amountController.text),
                  frequency: frequency,
                  renewalDate: renewalDate,
                );

                final provider = Provider.of<SubscriptionProvider>(
                  context,
                  listen: false,
                );
                final success = await provider.addSubscription(subscription);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Subscription added' : 'Failed to add'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubscription(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: const Text('Are you sure you want to delete this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      await provider.deleteSubscription(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubscriptionDialog,
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total Monthly Cost
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      const Text(
                        'Total Monthly Cost',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(provider.totalMonthlyCost),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Subscription List
                Expanded(
                  child: provider.subscriptions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.subscriptions,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No subscriptions yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showAddSubscriptionDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Subscription'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSubscriptions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.subscriptions.length,
                            itemBuilder: (context, index) {
                              final subscription = provider.subscriptions[index];
                              final daysUntilRenewal = subscription.renewalDate
                                  .difference(DateTime.now())
                                  .inDays;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      subscription.name[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    subscription.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${currencyFormat.format(subscription.amount)} / ${subscription.frequency}',
                                      ),
                                      Text(
                                        'Renews in $daysUntilRenewal days',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: daysUntilRenewal <= 7
                                              ? Colors.red
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteSubscription(subscription.id!),
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
