import 'package:flutter/material.dart';

/// Premium spacing system - consistent, scalable spacing
/// Based on 4px base unit (following Material Design)
class AppSpacing {
  // Private constructor
  AppSpacing._();

  // ============ BASE UNIT ============
  
  static const double baseUnit = 4.0;
  
  // ============ SPACING SCALE ============
  
  /// 4px - Minimal spacing
  static const double xs = baseUnit * 1; // 4px
  
  /// 8px - Tight spacing
  static const double sm = baseUnit * 2; // 8px
  
  /// 12px - Small spacing
  static const double md = baseUnit * 3; // 12px
  
  /// 16px - Standard spacing (most common)
  static const double lg = baseUnit * 4; // 16px
  
  /// 20px - Medium-large spacing
  static const double xl = baseUnit * 5; // 20px
  
  /// 24px - Large spacing
  static const double xxl = baseUnit * 6; // 24px
  
  /// 32px - Extra large spacing
  static const double xxxl = baseUnit * 8; // 32px
  
  /// 48px - Huge spacing (sections)
  static const double huge = baseUnit * 12; // 48px
  
  /// 64px - Massive spacing (hero sections)
  static const double massive = baseUnit * 16; // 64px
  
  // ============ SPECIFIC SPACING ============
  
  /// Padding inside cards
  static const double cardPadding = lg; // 16px
  
  /// Padding inside containers
  static const double containerPadding = lg; // 16px
  
  /// Screen edge padding
  static const double screenPadding = lg; // 16px
  
  /// Spacing between list items
  static const double listItemSpacing = md; // 12px
  
  /// Spacing between sections
  static const double sectionSpacing = xxl; // 24px
  
  /// Icon size - small
  static const double iconSm = 16.0;
  
  /// Icon size - medium
  static const double iconMd = 24.0;
  
  /// Icon size - large
  static const double iconLg = 32.0;
  
  /// Icon size - extra large
  static const double iconXl = 48.0;
  
  /// Button height - small
  static const double buttonHeightSm = 36.0;
  
  /// Button height - medium
  static const double buttonHeightMd = 48.0;
  
  /// Button height - large
  static const double buttonHeightLg = 56.0;
  
  /// Input field height
  static const double inputHeight = 56.0;
  
  /// App bar height
  static const double appBarHeight = 56.0;
  
  /// Bottom navigation bar height
  static const double bottomNavHeight = 64.0;
  
  // ============ BORDER RADIUS ============
  
  /// No radius
  static const double radiusNone = 0.0;
  
  /// Subtle radius
  static const double radiusXs = 4.0;
  
  /// Small radius
  static const double radiusSm = 8.0;
  
  /// Medium radius (cards, buttons)
  static const double radiusMd = 12.0;
  
  /// Large radius
  static const double radiusLg = 16.0;
  
  /// Extra large radius
  static const double radiusXl = 20.0;
  
  /// Huge radius (bottom sheets)
  static const double radiusXxl = 24.0;
  
  /// Full radius (circular)
  static const double radiusFull = 9999.0;
  
  // ============ ELEVATION ============
  
  /// No elevation
  static const double elevationNone = 0.0;
  
  /// Subtle elevation
  static const double elevationXs = 1.0;
  
  /// Small elevation (cards at rest)
  static const double elevationSm = 2.0;
  
  /// Medium elevation (cards on hover)
  static const double elevationMd = 4.0;
  
  /// Large elevation (dialogs)
  static const double elevationLg = 8.0;
  
  /// Extra large elevation (bottom sheets)
  static const double elevationXl = 12.0;
  
  /// Huge elevation (modals)
  static const double elevationXxl = 16.0;
  
  // ============ HELPER WIDGETS ============
  
  /// Vertical spacing widget
  static Widget verticalSpace(double height) => SizedBox(height: height);
  
  /// Horizontal spacing widget
  static Widget horizontalSpace(double width) => SizedBox(width: width);
  
  /// Vertical spacing - XS
  static Widget get vSpaceXs => SizedBox(height: xs);
  
  /// Vertical spacing - SM
  static Widget get vSpaceSm => SizedBox(height: sm);
  
  /// Vertical spacing - MD
  static Widget get vSpaceMd => SizedBox(height: md);
  
  /// Vertical spacing - LG
  static Widget get vSpaceLg => SizedBox(height: lg);
  
  /// Vertical spacing - XL
  static Widget get vSpaceXl => SizedBox(height: xl);
  
  /// Vertical spacing - XXL
  static Widget get vSpaceXxl => SizedBox(height: xxl);
  
  /// Vertical spacing - XXXL
  static Widget get vSpaceXxxl => SizedBox(height: xxxl);
  
  /// Horizontal spacing - XS
  static Widget get hSpaceXs => SizedBox(width: xs);
  
  /// Horizontal spacing - SM
  static Widget get hSpaceSm => SizedBox(width: sm);
  
  /// Horizontal spacing - MD
  static Widget get hSpaceMd => SizedBox(width: md);
  
  /// Horizontal spacing - LG
  static Widget get hSpaceLg => SizedBox(width: lg);
  
  /// Horizontal spacing - XL
  static Widget get hSpaceXl => SizedBox(width: xl);
  
  /// Horizontal spacing - XXL
  static Widget get hSpaceXxl => SizedBox(width: xxl);
  
  // ============ PADDING WIDGETS ============
  
  /// Horizontal padding
  static EdgeInsets horizontalPadding(double value) => 
    EdgeInsets.symmetric(horizontal: value);
  
  /// Vertical padding
  static EdgeInsets verticalPadding(double value) => 
    EdgeInsets.symmetric(vertical: value);
  
  /// Symmetric padding
  static EdgeInsets symmetricPadding({double? horizontal, double? vertical}) => 
    EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  
  /// All sides padding
  static EdgeInsets allPadding(double value) => EdgeInsets.all(value);
  
  /// Screen edge padding
  static EdgeInsets get screenEdgePadding => 
    const EdgeInsets.all(screenPadding);
  
  /// Card padding
  static EdgeInsets get cardInnerPadding => 
    const EdgeInsets.all(cardPadding);
  
  // ============ BORDER RADIUS WIDGETS ============
  
  /// Border radius - small
  static BorderRadius get borderRadiusSm => 
    BorderRadius.circular(radiusSm);
  
  /// Border radius - medium
  static BorderRadius get borderRadiusMd => 
    BorderRadius.circular(radiusMd);
  
  /// Border radius - large
  static BorderRadius get borderRadiusLg => 
    BorderRadius.circular(radiusLg);
  
  /// Border radius - extra large
  static BorderRadius get borderRadiusXl => 
    BorderRadius.circular(radiusXl);
  
  /// Border radius - top only (for bottom sheets)
  static BorderRadius get borderRadiusTop => 
    const BorderRadius.only(
      topLeft: Radius.circular(radiusXxl),
      topRight: Radius.circular(radiusXxl),
    );
  
  /// Border radius - custom
  static BorderRadius borderRadius(double radius) => 
    BorderRadius.circular(radius);
}
