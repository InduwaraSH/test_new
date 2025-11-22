import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a/firebase_options.dart';

const String webUrl = "https://test-app-c7b2e.web.app";
const int cacheHours = 0; // Cache validity time (0 = always fetch)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WebView With Cache",
      home: const WebAppScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebAppScreen extends StatefulWidget {
  const WebAppScreen({super.key});

  @override
  State<WebAppScreen> createState() => _WebAppScreenState();
}

class _WebAppScreenState extends State<WebAppScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initWebView();
  }

  Future<void> initWebView() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    final prefs = await SharedPreferences.getInstance();

    // ----- LOAD CACHE -----
    final cachedHtml = prefs.getString("cached_page");
    final savedTime = prefs.getInt("cached_time");

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = cacheHours * 60 * 60 * 1000;

    if (cachedHtml != null && savedTime != null) {
      final age = now - savedTime;

      if (age < expiry) {
        print("📌 Loading from CACHE");
        controller.loadHtmlString(cachedHtml);
        setState(() => isLoading = false);
        return;
      }
    }

    // ----- LOAD FROM SERVER -----
    print("🌍 Fetching from SERVER…");
    controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            setState(() => isLoading = false);

            // Get web HTML
            String html = await controller
                .runJavaScriptReturningResult(
                  "document.documentElement.outerHTML",
                )
                .then((value) => value.toString());

            // Save cache
            prefs.setString("cached_page", html);
            prefs.setInt("cached_time", now);

            print("💾 Cached HTML saved");
          },
        ),
      )
      ..loadRequest(Uri.parse(webUrl));
  }

  // -------------------------------------------------------
  // 🔥 CLEAR CUSTOM CACHED HTML
  Future<void> clearMyCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("cached_page");
    await prefs.remove("cached_time");
    print("🧹 Custom HTML cache cleared");
  }

  // 🔥 CLEAR WEBVIEW BROWSER CACHE
  Future<void> clearWebViewCache() async {
    await controller.clearCache();
    print("🧹 WebView internal cache cleared");
  }

  // 🔥 CLEAR EVERYTHING + RELOAD CLEAN
  Future<void> clearAllCaches() async {
    await clearMyCache();
    await clearWebViewCache();
    print("♻️ ALL caches cleared");

    // Reload fresh
    controller.loadRequest(Uri.parse(webUrl));
    setState(() => isLoading = true);
  }
  // -------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),

      // 🔥 Floating button to clear cache
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await clearAllCaches();
        },
        child: const Icon(Icons.cleaning_services),
      ),
    );
  }
}
