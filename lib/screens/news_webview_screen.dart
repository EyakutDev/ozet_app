import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/core/diagnostics/app_logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsWebViewScreen extends StatefulWidget {
  const NewsWebViewScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<NewsWebViewScreen> createState() => _NewsWebViewScreenState();
}

class _NewsWebViewScreenState extends State<NewsWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _errorMessage = null);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            AppLogger.event(
              'news_webview_error',
              level: AppLogLevel.warning,
              context: {
                'errorCode': error.errorCode,
                'host': Uri.tryParse(widget.url)?.host ?? 'unknown',
              },
            );
            if (mounted) {
              setState(() {
                _errorMessage = 'Haber sayfası yüklenemedi.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF111111)
        : const Color(0xFFF6F8FA);
    final surface = isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0A2342);
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: textColor,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kadwa(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              Uri.tryParse(widget.url)?.host ?? widget.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kadwa(color: mutedColor, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 100
              ? LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 3,
                  color: const Color(0xFF9EC8ED),
                  backgroundColor: Colors.transparent,
                )
              : const SizedBox(height: 3),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_errorMessage != null)
            Positioned.fill(
              child: Container(
                color: background,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: mutedColor,
                        size: 34,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _errorMessage = null);
                          _controller.reload();
                        },
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
