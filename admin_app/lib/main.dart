import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0B0F19),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WakeWakeAdminApp());
}

class WakeWakeAdminApp extends StatelessWidget {
  const WakeWakeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAKE, WAKE Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4338CA),
          surface: Color(0xFF111827),
        ),
      ),
      home: const AdminHomeScreen(),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  WebViewController? _popupController;
  bool _showPopup = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F19))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      // تفعيل إنشاء نوافذ منبثقة عائمة داخل التطبيق لتسجيل الدخول عبر Google
      ..setPlatformNavigationDelegate(
        PlatformNavigationDelegate(
          onWidgeCreateWindow: (CreateWindowAction action) {
            final popupCtrl = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onNavigationRequest: (NavigationRequest request) {
                    if (request.url.contains('firebaseapp.com/__/auth/handler') ||
                        request.url.contains('close') ||
                        !request.url.contains('accounts.google.com')) {
                      // عند الانتهاء من المصادقة، إغلاق النافذة المنبثقة والعودة للوحة التحكم
                      setState(() {
                        _showPopup = false;
                        _popupController = null;
                      });
                      _controller.reload();
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              );
            
            setState(() {
              _popupController = popupCtrl;
              _showPopup = true;
            });
            return Completer<WebViewController?>()..complete(popupCtrl);
          },
        ),
      )
      ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1")
      ..loadFlutterAsset('assets/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showPopup) {
          setState(() {
            _showPopup = false;
            _popupController = null;
          });
          return false;
        }
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFBBF24),
                  ),
                ),
              // نافذة منبثقة عائمة صغيرة لتسجيل دخول جوجل (مشابهة لطلبك)
              if (_showPopup && _popupController != null)
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("تسجيل الدخول عبر Google", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _showPopup = false;
                                      _popupController = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              child: WebViewWidget(controller: _popupController!),
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
}
