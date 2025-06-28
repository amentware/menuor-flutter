import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  static const String _url = 'https://themenuor.web.app/';

  @override
  void initState() {
    super.initState();
    debugPrint('WebViewScreen - initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('WebViewScreen - Post frame callback');
      _initializeWebView();
      _checkConnectivity();
    });
  }

  void _initializeWebView() {
    debugPrint('WebViewScreen - Initializing WebView');
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              debugPrint('WebView loading progress: $progress%');
            },
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = '${error.errorType}: ${error.description}';
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('Navigation request to: ${request.url}');
              if (request.url.startsWith('https://themenuor.web.app/')) {
                return NavigationDecision.navigate;
              }
              _launchURL(request.url);
              return NavigationDecision.prevent;
            },
          ),
        );
      
      debugPrint('Loading URL: $_url');
      controller.loadRequest(Uri.parse(_url));
      
      if (mounted) {
        setState(() {
          _controller = controller;
          debugPrint('WebViewController set');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing WebView: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize WebView: $e';
        });
      }
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      debugPrint('Connectivity result: $connectivityResult');
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No internet connection';
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _refresh() async {
    debugPrint('Refreshing WebView');
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('WebViewScreen - Building widget, hasError: $_hasError, isLoading: $_isLoading');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _hasError ? _buildErrorWidget() : _buildWebView(),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        if (_controller != null)
          WebViewWidget(controller: _controller!)
        else
          const Center(
            child: Text(
              'Initializing WebView...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ),
        if (_isLoading) _buildLoadingWidget(),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Menuor...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF757575),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load the page',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('Retry button pressed');
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initializeWebView();
                _checkConnectivity();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 