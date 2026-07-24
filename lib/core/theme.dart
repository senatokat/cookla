import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: kPrimary,
    onPrimary: Colors.white,
    primaryContainer: kPrimarySoft,
    onPrimaryContainer: kPrimaryDark,
    secondary: kSecondary,
    onSecondary: Colors.white,
    secondaryContainer: kSecondarySoft,
    onSecondaryContainer: Color(0xFF00695C),
    surface: kSurface,
    onSurface: kTextPrimary,
    error: Color(0xFFD93025),
    onError: Colors.white,
    outline: kBorder,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kSurface,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: kTextPrimary,
      displayColor: kTextPrimary,
    ),
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: kSurface,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: kSurface,
      iconTheme: const IconThemeData(color: kTextPrimary),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
    ),
    cardColor: kCard,
    dividerColor: kBorder,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kTextPrimary,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: const BorderSide(color: kBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary),
      ),
      hintStyle: const TextStyle(color: kHint),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCard,
      selectedItemColor: kPrimary,
      unselectedItemColor: kHint,
      showSelectedLabels: false,
      showUnselectedLabels: false,
    ),
  );
}
