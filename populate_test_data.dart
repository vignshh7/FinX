import 'dart:io';
import 'lib/test_data_populator.dart';

/// Script to populate test data for the Finx app
/// Run with: dart run populate_test_data.dart
Future<void> main() async {
  print('🚀 Finx Test Data Populator');
  print('===========================');
  print('This script will populate your account with realistic test data.');
  print('Make sure you are logged in to the app before running this.');
  print('');
  
  // Confirm with user
  stdout.write('Do you want to continue? (y/N): ');
  final input = stdin.readLineSync()?.toLowerCase();
  
  if (input != 'y' && input != 'yes') {
    print('❌ Operation cancelled.');
    exit(0);
  }
  
  print('');
  print('📊 Populating test data...');
  print('This may take a few minutes due to API rate limiting.');
  print('');
  
  try {
    final populator = TestDataPopulator();
    await populator.populateTestData();
    
    print('');
    print('🎉 Test data population completed successfully!');
    print('');
    print('📱 Your account now includes:');
    print('   • 90-150 realistic expenses (last 6 months)');
    print('   • 20+ income records (salary, freelance, investments)');
    print('   • 5 budget categories with spending limits');
    print('   • 6 savings goals (including one completed)');
    print('   • 10 bill reminders (with various statuses)');
    print('');
    print('💡 Tips:');
    print('   • Check the Dashboard to see your financial overview');
    print('   • Explore Budget tracking with realistic spending data');
    print('   • Review Savings Goals progress');
    print('   • Set up notifications for Bill Reminders');
    print('   • Use AI Analytics to get spending insights');
    print('');
    print('✨ Happy testing!');
    
  } catch (e) {
    print('');
    print('❌ Error during data population: $e');
    print('');
    print('💡 Troubleshooting tips:');
    print('   • Make sure you are logged in to the app');
    print('   • Check your internet connection');
    print('   • Verify the backend server is running');
    print('   • Try running the app first, then run this script');
    exit(1);
  }
}