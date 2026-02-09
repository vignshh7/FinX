import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fintech_colors.dart';
import '../../core/theme/fintech_typography.dart';
import 'modern_dashboard_screen.dart';
import '../expense_history_screen.dart';
import '../modern_receipt_scanner_screen.dart';
import '../modern_ai_insights_screen.dart';
import '../settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ModernDashboardScreen(),
    const ExpenseHistoryScreen(),
    const ModernReceiptScannerScreen(),
    const ModernAIInsightsScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Transactions',
    ),
    NavigationItem(
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
      label: 'Scan',
      isSpecial: true,
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Insights',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final navBackground = cs.surface;
    final navBorder = cs.outlineVariant.withOpacity(isDark ? 0.6 : 1.0);
    final navShadow = Colors.black.withOpacity(isDark ? 0.35 : 0.10);

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: navBackground,
          border: Border(
            top: BorderSide(
              color: navBorder,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: navShadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 8 + bottomInset,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedIndex == index;
            return _buildNavItem(item, index, isSelected);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isSelected) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final color = isSelected
        ? (item.isSpecial ? cs.onPrimary : cs.primary)
        : cs.onSurface.withOpacity(0.6);
    
    Widget iconWidget = Icon(
      isSelected ? item.activeIcon : item.icon,
      size: item.isSpecial ? 28 : 24,
      color: color,
    );

    if (item.isSpecial) {
      final isDark = theme.brightness == Brightness.dark;

      iconWidget = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: isSelected 
              ? FintechColors.primaryGradient 
              : LinearGradient(
                  colors: [
                    isDark ? FintechColors.surfaceColor : cs.surfaceVariant,
                    isDark ? FintechColors.borderColor : cs.outlineVariant,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
              item.label,
              style: FintechTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      // Haptic feedback for better UX
      HapticFeedback.lightImpact();
      
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSpecial;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isSpecial = false,
  });
}
