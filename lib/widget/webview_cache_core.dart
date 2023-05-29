import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../global.dart';

class CacheCoreList extends StatefulWidget {
  final Widget child;

  const CacheCoreList({Key? key, required this.child}) : super(key: key);

  static CacheCoreListState? of(BuildContext context) {
    return context.findAncestorStateOfType<CacheCoreListState>();
  }

  static CacheCoreListState? ofRoot(BuildContext context) {
    return context.findRootAncestorStateOfType<CacheCoreListState>();
  }

  @override
  State<CacheCoreList> createState() => CacheCoreListState();
}

class CacheCoreListState extends State<CacheCoreList> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [],
    );
  }
}

class WebViewCacheCore extends StatefulWidget {
  final String url;

  const WebViewCacheCore({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewCacheCore> createState() => _WebViewCacheCoreState();

  static CacheController? of(BuildContext context) {
    return context
        .findAncestorStateOfType<_WebViewCacheCoreState>()
        ?.cacheController;
  }

  static CacheController? ofRoot(BuildContext context) {
    return context
        .findRootAncestorStateOfType<_WebViewCacheCoreState>()
        ?.cacheController;
  }
}

class _WebViewCacheCoreState extends State<WebViewCacheCore> {
  CacheController? cacheController;

  @override
  void initState() {
    super.initState();
    _initController().then((value) {
      cacheController = value;
      setState(() {

      });
    }).catchError((err, stack) {
      debugPrint(stack);
    });
  }

  Future<CacheController> _initController() async {
    WebViewController _controller = WebViewController();
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(const Color(0x00000000))
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {},
        onUrlChange: (UrlChange urlChange) {},
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    await _controller.runJavaScript('');
    await _controller.loadRequest(Uri.parse(widget.url));
    CacheController cacheController = CacheController(_controller);
    return cacheController;
  }

  @override
  Widget build(BuildContext context) {
    if (cacheController == null) return SizedBox();
    return WebViewWidget(
      controller: cacheController!.webViewController,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class CacheController {
  final WebViewController webViewController;

  CacheController(this.webViewController);

//todo 注入js
}

