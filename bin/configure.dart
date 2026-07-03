// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.contains('--help') || arguments.contains('-h')) {
    printUsage();
    return;
  }

  String? url;
  String? name;
  String? colorHex;
  String? bundleId;
  String? logoPath;
  bool? enableAuth;
  bool? showSettings;

  for (int i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--url' && i + 1 < arguments.length) {
      url = arguments[i + 1];
    } else if (arguments[i] == '--name' && i + 1 < arguments.length) {
      name = arguments[i + 1];
    } else if (arguments[i] == '--color' && i + 1 < arguments.length) {
      colorHex = arguments[i + 1];
    } else if (arguments[i] == '--bundle-id' && i + 1 < arguments.length) {
      bundleId = arguments[i + 1];
    } else if (arguments[i] == '--logo' && i + 1 < arguments.length) {
      logoPath = arguments[i + 1];
    } else if (arguments[i] == '--enable-auth' && i + 1 < arguments.length) {
      enableAuth = arguments[i + 1].toLowerCase() == 'true';
    } else if (arguments[i] == '--show-settings' && i + 1 < arguments.length) {
      showSettings = arguments[i + 1].toLowerCase() == 'true';
    }
  }

  // Fallbacks if not provided
  url ??= "https://flutter.dev";
  name ??= "Website Wrapper";
  colorHex ??= "0xFF448AFF"; // blueAccent
  bundleId ??= "com.example.app";
  enableAuth ??= false;
  showSettings ??= false;

  // Format hex color if needed (e.g. #FF5733 -> 0xFFFF5733)
  if (colorHex.startsWith('#')) {
    colorHex = colorHex.replaceFirst('#', '');
    if (colorHex.length == 6) {
      colorHex = "0xFF$colorHex";
    } else if (colorHex.length == 8) {
      colorHex = "0x$colorHex";
    }
  }
  if (!colorHex.startsWith('0x')) {
    colorHex = "0xFF$colorHex";
  }

  print("=========================================");
  print("🚀 WEBSITE WRAPPER CONFIGURATOR");
  print("=========================================");
  print("App Name:        $name");
  print("Target URL:      $url");
  print("Primary Color:   $colorHex");
  print("Bundle ID:       $bundleId");
  print("Enable Auth:     $enableAuth");
  print("Show Settings:   $showSettings");
  if (logoPath != null) {
    print("Logo Image Path: $logoPath");
  }
  print("=========================================\n");

  // 1. Update lib/app_config.dart
  print("✍️ Updating lib/app_config.dart...");
  final configFile = File('lib/app_config.dart');
  final configContent = '''
import 'package:flutter/material.dart';

class AppConfig {
  // Core Settings
  static const String appName = "$name";
  static const String initialUrl = "$url";

  // Branding Theme Colors
  static const Color defaultPrimaryColor = Color($colorHex);
  static const bool enableDarkMode = true;

  // Feature Toggles
  static const bool enableAuth = $enableAuth;         // Set false to completely skip Login/Signup
  static const bool enableBiometrics = true;   // Toggle device biometric auth lock
  static const bool showSettingsButton = $showSettings; // Set false to lock the app completely to WebView
  
  // Custom Logos & Icons
  static const String logoAssetPath = "images/app_logo.png";
}
''';
  await configFile.writeAsString(configContent);
  print("✓ lib/app_config.dart updated successfully.");

  // 2. Handle Custom Logo Copy
  if (logoPath != null) {
    print("🖼️ Processing logo image...");
    final sourceLogo = File(logoPath);
    if (await sourceLogo.exists()) {
      final targetDir = Directory('images');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final targetLogo = File('images/app_logo.png');
      await sourceLogo.copy(targetLogo.path);
      print("✓ Logo copied to images/app_logo.png.");
    } else {
      print("⚠️ Error: Source logo file not found at '$logoPath'. Skipping logo setup.");
    }
  }

  // 2.5 Update android/app/google-services.json package_name
  final googleServicesFile = File('android/app/google-services.json');
  if (await googleServicesFile.exists()) {
    print("🔧 Updating package name in android/app/google-services.json...");
    try {
      String content = await googleServicesFile.readAsString();
      final regex = RegExp(r'"package_name":\s*"[^"]*"');
      content = content.replaceAll(regex, '"package_name": "$bundleId"');
      await googleServicesFile.writeAsString(content);
      print("✓ google-services.json package name updated.");
    } catch (e) {
      print("⚠️ Failed to update google-services.json: \$e");
    }
  }

  // Direct file modification to ensure android/app/build.gradle.kts gets updated (Kotlin DSL support)
  final buildGradleKtsFile = File('android/app/build.gradle.kts');
  if (await buildGradleKtsFile.exists()) {
    try {
      String content = await buildGradleKtsFile.readAsString();
      final regexAppId = RegExp(r'applicationId\s*=\s*"[^"]*"');
      content = content.replaceAll(regexAppId, 'applicationId = "$bundleId"');
      await buildGradleKtsFile.writeAsString(content);
      print("✓ android/app/build.gradle.kts applicationId updated.");
    } catch (e) {
      print("⚠️ Failed to manually update build.gradle.kts: $e");
    }
  }

  // Direct file modification to ensure iOS project pbxproj gets updated
  final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
  if (await pbxprojFile.exists()) {
    try {
      String content = await pbxprojFile.readAsString();
      final regexBundleId = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;');
      content = content.replaceAll(regexBundleId, 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId;');
      await pbxprojFile.writeAsString(content);
      print("✓ ios/Runner.xcodeproj/project.pbxproj bundle ID updated.");
    } catch (e) {
      print("⚠️ Failed to manually update project.pbxproj: $e");
    }
  }

  // 3. Rename Android/iOS bundle identifiers
  print("📦 Renaming package identifiers/bundle IDs to '$bundleId'...");
  final renameBundleResult = await Process.run('flutter', [
    'pub',
    'run',
    'rename',
    'setBundleId',
    '--targets',
    'android,ios',
    '--value',
    bundleId
  ], runInShell: true);
  if (renameBundleResult.exitCode == 0) {
    print("✓ Package identifiers updated successfully.");
  } else {
    print("⚠️ Failed to update package identifiers: ${renameBundleResult.stderr}");
  }

  // 4. Rename Android/iOS app names
  print("📱 Renaming app visible name to '$name'...");

  // Direct file modification to ensure AndroidManifest.xml gets updated
  final androidManifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (await androidManifestFile.exists()) {
    try {
      String content = await androidManifestFile.readAsString();
      final regex = RegExp(r'android:label="[^"]*"');
      content = content.replaceAll(regex, 'android:label="$name"');
      await androidManifestFile.writeAsString(content);
      print("✓ android/app/src/main/AndroidManifest.xml android:label updated.");
    } catch (e) {
      print("⚠️ Failed to manually update AndroidManifest.xml: $e");
    }
  }

  // Direct file modification to ensure Info.plist gets updated
  final infoPlistFile = File('ios/Runner/Info.plist');
  if (await infoPlistFile.exists()) {
    try {
      String content = await infoPlistFile.readAsString();
      final regexDisplayName = RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>');
      final regexBundleName = RegExp(r'<key>CFBundleName</key>\s*<string>[^<]*</string>');
      
      content = content.replaceAll(regexDisplayName, '<key>CFBundleDisplayName</key>\n\t<string>$name</string>');
      content = content.replaceAll(regexBundleName, '<key>CFBundleName</key>\n\t<string>$name</string>');
      await infoPlistFile.writeAsString(content);
      print("✓ ios/Runner/Info.plist app names updated.");
    } catch (e) {
      print("⚠️ Failed to manually update Info.plist: $e");
    }
  }

  final renameNameResult = await Process.run('flutter', [
    'pub',
    'run',
    'rename',
    'setAppName',
    '--targets',
    'android,ios',
    '--value',
    name
  ], runInShell: true);
  if (renameNameResult.exitCode == 0) {
    print("✓ App name updated successfully.");
  } else {
    print("⚠️ Failed to update app name: ${renameNameResult.stderr}");
  }

  // 5. Regenerate Launcher Icons
  print("🎨 Regenerating Android & iOS launcher icons...");
  final iconsResult = await Process.run('flutter', [
    'pub',
    'run',
    'flutter_launcher_icons'
  ], runInShell: true);
  if (iconsResult.exitCode == 0) {
    print("✓ Launcher icons generated successfully.");
  } else {
    print("⚠️ Launcher icon generation log:\n${iconsResult.stdout}\n${iconsResult.stderr}");
  }

  print("\n🎉 Configuration Complete! Your white-labeled app is ready.");
  print("Run 'flutter build apk' or build in Xcode to test.");
}

void printUsage() {
  print("Website Wrapper Configurator CLI Tool");
  print("\nUsage:");
  print("  dart run bin/configure.dart [options]");
  print("\nOptions:");
  print("  --url <url>            The URL of the client's web application (default: https://flutter.dev)");
  print("  --name <name>          The display name of the application (default: Website Wrapper)");
  print("  --color <hex>          The brand primary color in hex format, e.g. #FF5733 (default: 0xFF448AFF)");
  print("  --bundle-id <id>       The Android package name/iOS Bundle ID, e.g. com.company.app (default: com.example.app)");
  print("  --logo <path>          The path to the local logo image to copy as the app logo/icon");
  print("  --enable-auth <bool>   Whether to enable the signup/login screen (default: false)");
  print("  --show-settings <bool> Whether to allow access to Settings in the WebView screen (default: false)");
  print("\nExample:");
  print("  dart run bin/configure.dart --url \"https://google.com\" --name \"SearchApp\" --color \"#00FF00\" --bundle-id \"com.google.searchapp\"");
}
