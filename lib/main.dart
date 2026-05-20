import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Global notifiers for theme settings
final ValueNotifier<Color> themeColorNotifier = ValueNotifier(
  AppConfig.defaultPrimaryColor,
);
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only if auth is enabled
  if (AppConfig.enableAuth) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint("Firebase initialization failed: \$e");
    }
  }

  // Load saved theme settings
  final prefs = await SharedPreferences.getInstance();

  int? colorValue = prefs.getInt('theme_color');
  if (colorValue != null) {
    themeColorNotifier.value = Color(colorValue);
  }

  bool isDarkMode = prefs.getBool('is_dark_mode') ?? AppConfig.enableDarkMode;
  themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: themeColorNotifier,
      builder: (context, accentColor, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: accentColor,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                textTheme: GoogleFonts.poppinsTextTheme(
                  ThemeData.light().textTheme,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: accentColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                textTheme: GoogleFonts.poppinsTextTheme(
                  ThemeData.dark().textTheme,
                ),
              ),
              home: AppConfig.enableAuth ? const AuthWrapper() : const HomeScreen(),
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<User?>(
      initialData: currentUser,
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
