import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  double _progress = 0;
  bool _isWebViewVisible = false;
  String _appName = AppConfig.appName;

  // Scroll tracking variables
  bool _showAppBar = true;
  double _lastScrollY = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setOnScrollPositionChange((ScrollPositionChange change) {
            _handleScroll(change.y);
          })
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
                try {
                  final double statusBarHeight = MediaQuery.of(context).padding.top;
                  final double totalPadding = kToolbarHeight + statusBarHeight;
                  _controller.runJavaScript('''
                    if (document.body) {
                      document.body.style.paddingTop = '${totalPadding}px';
                    }
                  ''');
                } catch (e) {
                  debugPrint("Failed to inject padding: $e");
                }
              },
              onWebResourceError: (WebResourceError error) {},
              onNavigationRequest: (NavigationRequest request) {
                return NavigationDecision.navigate;
              },
            ),
          );

    _loadCustomSettings();

    // If authentication is disabled, automatically load the default URL
    if (!AppConfig.enableAuth) {
      _loadUrl(AppConfig.initialUrl);
    }
  }

  void _handleScroll(double y) {
    if (!_isWebViewVisible) return;

    // Always show AppBar at the top of the page
    if (y <= 50) {
      if (!_showAppBar) {
        setState(() {
          _showAppBar = true;
        });
      }
      _lastScrollY = y;
      return;
    }

    final double delta = y - _lastScrollY;

    // Reset baseline if scrolling direction changed without triggering a state update yet
    if ((delta > 0 && !_showAppBar) || (delta < 0 && _showAppBar)) {
      _lastScrollY = y;
    }

    if (delta > 15) {
      // Scroll Down -> Hide App Bar
      if (_showAppBar) {
        setState(() {
          _showAppBar = false;
        });
      }
      _lastScrollY = y;
    } else if (delta < -15) {
      // Scroll Up -> Show App Bar
      if (!_showAppBar) {
        setState(() {
          _showAppBar = true;
        });
      }
      _lastScrollY = y;
    }
  }

  void _loadCustomSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appName = prefs.getString('custom_app_name') ?? AppConfig.appName;
    });
  }

  void _loadUrl(String url) async {
    if (url.isEmpty) return;

    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    setState(() {
      _isWebViewVisible = true;
      _showAppBar = true; // Show AppBar by default on new load
      _lastScrollY = 0;
    });

    _controller.loadRequest(Uri.parse(formattedUrl));
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, Color primaryColor) {
    return AppBar(
      primary: false, // Manage status bar height padding manually/externally
      elevation: 0,
      title: Text(
        _appName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        if (_isWebViewVisible)
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: () => _controller.reload(),
          ),
        if (AppConfig.showSettingsButton)
          IconButton(
            icon: Icon(Icons.tune_rounded, color: primaryColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              if (result == true) _loadCustomSettings();
            },
          ),
        if (AppConfig.enableAuth)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (_isWebViewVisible) {
          if (await _controller.canGoBack()) {
            await _controller.goBack();
          } else {
            if (AppConfig.enableAuth) {
              setState(() {
                _isWebViewVisible = false;
              });
            } else {
              SystemNavigator.pop();
            }
          }
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _isWebViewVisible
            ? _buildWebViewLayout(context, theme, primaryColor)
            : SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, theme, primaryColor),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phonelink_setup_rounded,
                                size: 80,
                                color: primaryColor,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Convert Website to App',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[900]
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _urlController,
                                  style: TextStyle(color: theme.colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. google.com',
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.language,
                                      color: primaryColor,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        Icons.rocket_launch_rounded,
                                        color: primaryColor,
                                      ),
                                      onPressed: () => _loadUrl(_urlController.text),
                                    ),
                                  ),
                                  onSubmitted: _loadUrl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWebViewLayout(BuildContext context, ThemeData theme, Color primaryColor) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = kToolbarHeight + statusBarHeight;

    return Stack(
      children: [
        // WebView occupying the screen statically (NEVER resizes to prevent lag)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: WebViewWidget(controller: _controller),
        ),
        
        // Slideable Top Header/AppBar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          top: _showAppBar ? 0 : -appBarHeight,
          left: 0,
          right: 0,
          height: appBarHeight,
          child: Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.only(top: statusBarHeight),
            child: _buildAppBar(context, theme, primaryColor),
          ),
        ),
        
        // Dynamic loading progress indicator (stays just below status bar or at the top)
        if (_isLoading)
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              color: primaryColor,
              minHeight: 3,
            ),
          ),
      ],
    );
  }
}
