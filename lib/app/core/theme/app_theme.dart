import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Global Background Colors (Updated)
  static const Color appBackground = Color(0xFFF4F4F6);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE2E2E8);
  static const Color mutedText = Color(0xFFA0A0A5);
  static const Color primaryText = Color(0xFF1C1C1E);

  // Additional colors for compatibility
  static const Color TealColor = Color(0xFF4CC9F0);
  static const Color navBarSelectedDeep = Color(0xFF6A5AE0);

  // AppBar Gradient (Grey with Lavender tint)
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8E8EA), Color(0xFFD8D5E8)],
  );

  // 📚 Subject Card Gradient System

  // Geography (Purple - Primary Style)
  static const LinearGradient geographyGradient = LinearGradient(
    colors: [Color(0xFF8E7CFF), Color(0xFF6A5AE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient geographySoftGradient = LinearGradient(
    colors: [Color(0xFFEDE9FF), Color(0xFFF5F3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Math (Orange)
  static const LinearGradient mathGradient = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mathSoftGradient = LinearGradient(
    colors: [Color(0xFFFFE6D5), Color(0xFFFFF1E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Biology (Green)
  static const LinearGradient biologyGradient = LinearGradient(
    colors: [Color(0xFF8EDB4F), Color(0xFF6FCF97)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient biologySoftGradient = LinearGradient(
    colors: [Color(0xFFE7F9D8), Color(0xFFF2FFF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chemistry (Blue)
  static const LinearGradient chemistryGradient = LinearGradient(
    colors: [Color(0xFF4CC9F0), Color(0xFF3AB0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chemistrySoftGradient = LinearGradient(
    colors: [Color(0xFFE0F7FF), Color(0xFFF0FBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Physics (Purple) - Added for compatibility
  static const LinearGradient physicsGradient = LinearGradient(
    colors: [Color(0xFF8E7CFF), Color(0xFF6A5AE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Teal Gradient - Added for compatibility
  static const LinearGradient TealGradient = LinearGradient(
    colors: [Color(0xFF4CC9F0), Color(0xFF3AB0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🎯 Primary System Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8E7CFF), Color(0xFF6A5AE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🎨 Bottom Navigation Bar Colors
  static const LinearGradient navBarSelectedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E7CFF), Color(0xFF6A5AE0)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF8EDB4F), Color(0xFF6FCF97)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFFCA5A5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 📊 Chart & Statistics Colors
  static const Color lowScore = Color(0xFFEF4444);
  static const Color mediumScore = Color(0xFFFF8A3D);
  static const Color highScore = Color(0xFF8EDB4F);
  static const Color gridLine = Color(0xFFE2E2E8);

  // 🎨 Text Colors on Different Backgrounds
  static const Color titleOnGradient = Color(0xFFFFFFFF);
  static const Color subtitleOnGradient = Color(0xFFEDE9FF);
  static const Color titleOnWhite = Color(0xFF1C1C1E);
  static const Color subtitleOnWhite = Color(0xFF6E6E73);

  // Legacy colors (Updated but preserved)
  static const Color primaryBlue = Color(0xFF8E7CFF);
  static const Color successGreen = Color(0xFF8EDB4F);
  static const Color warningYellow = Color(0xFFFF8A3D);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color mathOrange = Color(0xFFFF8A3D);
  static const Color geographyBlue = Color(0xFF8E7CFF);
  static const Color biologyGreen = Color(0xFF8EDB4F);
  static const Color chemistryYellow = Color(0xFF4CC9F0);
  
  // Legacy gradients
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Color primaryBackground = appBackground;

  static const double radius = 20;
  static const double cardElevation = 2;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: successGreen,
      background: appBackground,
      surface: cardBackground,
      error: errorRed,
      onPrimary: titleOnGradient,
      onBackground: primaryText,
      onSurface: primaryText,
    ),
    scaffoldBackgroundColor: appBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFE8E8EA),
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: primaryText),
      titleTextStyle: const TextStyle(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      shadowColor: const Color(0xFFD8D5E8).withOpacity(0.6),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryText,
      unselectedLabelColor: mutedText,
      indicatorColor: primaryBlue,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: cardElevation,
      shadowColor: Colors.black.withOpacity(0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: titleOnGradient,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: 2,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    dividerColor: dividerColor,
    textTheme: const TextTheme(
      headlineLarge:
          TextStyle(color: titleOnWhite, fontWeight: FontWeight.bold),
      headlineMedium:
          TextStyle(color: titleOnWhite, fontWeight: FontWeight.w600),
      titleLarge:
          TextStyle(color: titleOnWhite, fontWeight: FontWeight.w600),
      titleMedium:
          TextStyle(color: titleOnWhite, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: titleOnWhite),
      bodyMedium: TextStyle(color: subtitleOnWhite),
      bodySmall: TextStyle(color: mutedText),
    ),
  );

  // 🎨 Helper Methods for Subject Colors
  static LinearGradient getSubjectGradient(String subject,
      {bool soft = false}) {
    switch (subject.toLowerCase()) {
      case 'geography':
        return soft ? geographySoftGradient : geographyGradient;
      case 'math':
      case 'mathematics':
        return soft ? mathSoftGradient : mathGradient;
      case 'biology':
        return soft ? biologySoftGradient : biologyGradient;
      case 'chemistry':
        return soft ? chemistrySoftGradient : chemistryGradient;
      default:
        return soft ? biologySoftGradient : primaryGradient;
    }
  }

  static Color getSubjectPrimaryColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'geography':
        return geographyBlue;
      case 'math':
      case 'mathematics':
        return mathOrange;
      case 'biology':
        return biologyGreen;
      case 'chemistry':
        return chemistryYellow;
      default:
        return primaryBlue;
    }
  }

  static Color getScoreColor(double score) {
    if (score >= 80) return highScore;
    if (score >= 60) return mediumScore;
    return lowScore;
  }

  // Responsive breakpoints
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 32;
  }

  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  // 🎨 Gradient AppBar Builder
  static PreferredSizeWidget buildGradientAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: navBarSelectedGradient,
        ),
      ),
    );
  }
}