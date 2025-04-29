import 'package:flutter/material.dart';

class AppTheme {
  // Main app colors
  static const Color primaryColor = Color(0xFF009688);    // Teal 500
  static const Color primaryDarkColor = Color(0xFF00796B); // Teal 700
  static const Color primaryLightColor = Color(0xFFB2DFDB); // Teal 100
  static const Color accentColor = Color(0xFFFF5722);     // Deep Orange 500
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color errorColor = Color(0xFFC62828);      // Red 800
  static const Color successColor = Color(0xFF2E7D32);    // Green 800
  static const Color dividerColor = Color(0xFFBDBDBD);    // Grey 400
  static const Color cardColor = Colors.white;
  static const Color disabledColor = Color(0xFFBDBDBD);   // Grey 400
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grey 100
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: 0.5,
  );
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    letterSpacing: 0.15,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    letterSpacing: 0.15,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textPrimaryColor,
    letterSpacing: 0.25,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
    letterSpacing: 0.4,
  );
  
  static const TextStyle buttonStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
  );
  
  // Building the theme
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorDark: primaryDarkColor,
      primaryColorLight: primaryLightColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      disabledColor: disabledColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),
      textTheme: const TextTheme(
        headlineMedium: headingStyle,
        titleLarge: titleStyle,
        titleMedium: subtitleStyle,
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
        labelLarge: buttonStyle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return disabledColor;
              }
              return primaryColor;
            },
          ),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          textStyle: MaterialStateProperty.all<TextStyle>(buttonStyle),
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevation: MaterialStateProperty.all<double>(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(primaryColor),
          textStyle: MaterialStateProperty.all<TextStyle>(buttonStyle),
          side: MaterialStateProperty.all<BorderSide>(
            const BorderSide(color: primaryColor),
          ),
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(primaryColor),
          textStyle: MaterialStateProperty.all<TextStyle>(buttonStyle),
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: errorColor,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardColor,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentTextStyle: const TextStyle(fontSize: 14),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      colorSchemeSeed: primaryColor,
      useMaterial3: true,
    );
  }
}