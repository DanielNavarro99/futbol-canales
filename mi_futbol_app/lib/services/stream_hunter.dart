import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class StreamHunter {
  Future<String?> hunt(String pageUrl) async {
    String? streamUrl;
    HeadlessInAppWebView? browser;

    browser = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(pageUrl)),
      initialSettings: InAppWebViewSettings(
        userAgent:
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
        javaScriptEnabled: true,
        useOnLoadResource: true,
        useShouldInterceptRequest: true,
      ),
      shouldInterceptRequest: (controller, request) async {
        final url = request.url.toString();

        // Busca .m3u8 primero
        if (url.contains('.m3u8') && streamUrl == null) {
          print('✅ m3u8 encontrado: $url');
          streamUrl = url;
          await browser?.dispose();
          return null;
        }

        // Si encuentra segmentos .ts con token, construye el m3u8
        if (url.contains('.ts') && url.contains('token') && streamUrl == null) {
          print('🎯 Segmento .ts encontrado: $url');
          try {
            final uri = Uri.parse(url);
            final token = uri.queryParameters['token'] ?? '';
            final pathParts = uri.pathSegments;
            final canal = pathParts[0];
            final m3u8Url =
                '${uri.scheme}://${uri.host}/$canal/index.m3u8?token=$token';
            print('🔨 m3u8 construido: $m3u8Url');
            streamUrl = m3u8Url;
            await browser?.dispose();
          } catch (e) {
            print('💥 Error: $e');
          }
        }

        return null;
      },
      onLoadStop: (controller, url) async {
        print('📄 Página cargada: $url');
      },
    );

    await browser.run();

    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (streamUrl == null && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await browser.dispose();
    return streamUrl;
  }
}
