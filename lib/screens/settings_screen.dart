import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../main.dart'; // Import to access theme notifiers

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  late Color _selectedColor;
  bool _useBiometrics = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = themeColorNotifier.value;
    _isDarkMode = themeModeNotifier.value == ThemeMode.dark;
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('custom_app_name') ?? AppConfig.appName;
      _useBiometrics = prefs.getBool('use_biometrics') ?? AppConfig.enableBiometrics;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? AppConfig.enableDarkMode;
      int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) {
        _selectedColor = Color(colorValue);
      }
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_app_name', _nameController.text.trim());
    await prefs.setBool('use_biometrics', _useBiometrics);
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setInt('theme_color', _selectedColor.value);

    // Update the global theme settings immediately
    themeColorNotifier.value = _selectedColor;
    themeModeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved & Applied!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Features'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personalize your App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // 1. Custom App Name
            const Text(
              "What would you like to call this App?",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[100]
                        : Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: "Enter App Name",
              ),
            ),

            const SizedBox(height: 32),

            // 2. Dark Mode Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Dark Mode",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Switch between light and dark themes"),
              value: _isDarkMode,
              activeColor: _selectedColor,
              onChanged: (val) => setState(() => _isDarkMode = val),
            ),

            const SizedBox(height: 32),

            // 3. Theme Color Picker
            const Text(
              "Choose your favorite Theme Color",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _colorOption(Colors.blueAccent),
                _colorOption(Colors.deepPurpleAccent),
                _colorOption(Colors.greenAccent),
                _colorOption(Colors.orangeAccent),
                _colorOption(Colors.pinkAccent),
                _colorOption(Colors.redAccent),
                _colorOption(Colors.teal),
                _colorOption(Colors.indigo),
                _colorOption(Colors.amber),
                _colorOption(Colors.cyan),
              ],
            ),

            const SizedBox(height: 32),

            // 4. Biometric Toggle
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Enable Fingerprint Lock",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Keep your web app secure"),
              trailing: Switch(
                value: _useBiometrics,
                onChanged: (val) => setState(() => _useBiometrics = val),
                activeColor: _selectedColor,
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save & Apply",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    bool isSelected = _selectedColor.value == color.value;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
