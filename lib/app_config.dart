import 'package:flutter/material.dart';

class AppConfig {
  // Core Settings
  static const String appName = "HackerNews";
  static const String initialUrl = "https://news.ycombinator.com";

  // Branding Theme Colors
  static const Color defaultPrimaryColor = Color(0xFFFF6600);
  static const bool enableDarkMode = true;

  // Feature Toggles
  static const bool enableAuth = false;         // Set false to completely skip Login/Signup
  static const bool enableBiometrics = true;   // Toggle device biometric auth lock
  static const bool showSettingsButton = false; // Set false to lock the app completely to WebView
  
  // Custom Logos & Icons
  static const String logoAssetPath = "images/app_logo.png";
}
