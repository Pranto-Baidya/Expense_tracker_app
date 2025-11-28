import 'dart:ui';

import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light Theme
ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: AppColors.mainColor, // Teal (#14B8A6)
    secondary: AppColors.lightAccent, // Soft Blue (#3B82F6)
    surface: AppColors.lightSurface, // Light Gray (#E5E7EB)
    background: AppColors.lightBackground, // Off-White (#F9FAFB)
    error: AppColors.lightError, // Coral (#F87171)
    onPrimary: Colors.white,
    onSecondary: AppColors.lightTextPrimary, // Dark Gray (#1F2A44)
    onSurface: AppColors.lightTextPrimary, // Dark Gray (#1F2A44)
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.lightBackground,
  textTheme: GoogleFonts.interTextTheme().copyWith(
    labelSmall: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 11, fontWeight: FontWeight.w700),
    labelMedium: GoogleFonts.inter(
        color: AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w700),
    labelLarge: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    titleSmall: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
    titleLarge: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 22, fontWeight: FontWeight.w700),
    displaySmall: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 36, fontWeight: FontWeight.w700),
    displayMedium: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 45, fontWeight: FontWeight.w700),
    displayLarge: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 57, fontWeight: FontWeight.w700),
    headlineSmall: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
    headlineLarge: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
    bodySmall: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 12, fontWeight: FontWeight.w700),
    bodyMedium: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    bodyLarge: GoogleFonts.inter(
        color: AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
  ),
  checkboxTheme: CheckboxThemeData(
    side: BorderSide(color: AppColors.lightTextPrimary, width: 2.w),
  ),
  listTileTheme: ListTileThemeData(
    tileColor: AppColors.lightSurface,
    iconColor: AppColors.lightTextPrimary,
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.mainColor),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightBackground,
    selectedItemColor: AppColors.mainColor,
    unselectedItemColor: AppColors.lightTextSecondary,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.lightSurface,
    iconColor: AppColors.lightTextPrimary,
    textStyle: TextStyle(
        color: AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
  ),
  iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
  cardColor: AppColors.lightBackground,
  dialogTheme: DialogThemeData(
    titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
    contentTextStyle: TextStyle(
        color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    backgroundColor: AppColors.lightBackground,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.lightBackground,
    indicatorColor: AppColors.mainColor,
    surfaceTintColor: Colors.transparent,
  ),
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStatePropertyAll(AppColors.lightSurface),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.lightBackground,
    filled: true,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.lightTextPrimary.withOpacity(0.3))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.lightTextPrimary.withOpacity(0.3))),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: AppColors.lightTextPrimary.withOpacity(0.3)),
    ),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.lightTextPrimary.withOpacity(0.3))),
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: AppColors.lightBackground,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    scrolledUnderElevation: 0,
  ),
);

/// Dark Theme
ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: AppColors.mainColor, // Teal (#14B8A6)
    secondary: AppColors.darkAccent, // Sky Blue (#60A5FA)
    surface: AppColors.darkSurface, // Medium Gray (#4B5563)
    background: AppColors.darkBackground, // Dark Slate (#1E293B)
    error: AppColors.darkError, // Peach (#FBBF24)
    onPrimary: Colors.white,
    onSecondary: AppColors.darkTextPrimary, // Light Gray (#D1D5DB)
    onSurface: AppColors.darkTextPrimary, // Light Gray (#D1D5DB)
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    scrolledUnderElevation: 0,
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    labelSmall: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 11, fontWeight: FontWeight.w700),
    labelMedium: GoogleFonts.inter(
        color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w700),
    labelLarge: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    titleSmall: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
    titleLarge: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700),
    displaySmall: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 36, fontWeight: FontWeight.w700),
    displayMedium: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 45, fontWeight: FontWeight.w700),
    displayLarge: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 57, fontWeight: FontWeight.w700),
    headlineSmall: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
    headlineLarge: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
    bodySmall: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w700),
    bodyMedium: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
    bodyLarge: GoogleFonts.inter(
        color: AppColors.darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: AppColors.darkBackground,
  ),
  checkboxTheme: CheckboxThemeData(
    side: BorderSide(color: AppColors.darkTextPrimary, width: 2.w),
  ),
  listTileTheme: ListTileThemeData(
    tileColor: AppColors.darkSurface,
    iconColor: AppColors.darkTextPrimary,
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.mainColor),
  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.darkSurface,
    iconColor: AppColors.darkTextPrimary,
    textStyle: TextStyle(
        color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
  ),
  iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
  cardColor: AppColors.darkBackground,
  dialogTheme: DialogThemeData(
    titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
    contentTextStyle: TextStyle(
        color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
    backgroundColor: AppColors.darkSurface,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.mainColor,
    unselectedItemColor: AppColors.darkTextSecondary,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.darkBackground,
    indicatorColor: AppColors.mainColor,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
  ),
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStatePropertyAll(AppColors.darkSurface),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.darkBackground,
    filled: true,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.darkTextPrimary.withOpacity(0.3))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.darkTextPrimary.withOpacity(0.3))),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: AppColors.darkTextPrimary.withOpacity(0.3)),
    ),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.darkTextPrimary.withOpacity(0.3))),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.darkSurface),
    ),
  ),
);