import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../global.dart';

const _kMaxTimeout = Duration(seconds: 30);

class CacheCoreList extends StatefulWidget {
  final Widget child;

  const CacheCoreList({Key? key, required this.child}) : super(key: key);

  static CacheCoreListDelegate? of(BuildContext context) {
    return context.findAncestorStateOfType<CacheCoreListState>();
  }

  static CacheCoreListDelegate? ofRoot(BuildContext context) {
    return context.findRootAncestorStateOfType<CacheCoreListState>();
  }

  @override
  State<CacheCoreList> createState() => CacheCoreListState();
}

class CacheCoreListState extends State<CacheCoreList>
    implements CacheCoreListDelegate {
  final List<WebViewCacheCore> cores = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...cores,
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    cores.clear();
    super.dispose();
  }

  @override
  Future<void> addSingleCacheCore(String url,
      {Function? onStart,
      Function(int progress)? onProgress,
      Function? onLoaded,
      Function? onFailed}) async {}
}

abstract class CacheCoreListDelegate {
  Future<void> addSingleCacheCore(String url,
      {Function? onStart,
      Function(int progress)? onProgress,
      Function? onLoaded,
      Function? onFailed});
}

abstract class WebViewCacheCore extends StatefulWidget {
  final String url;
  final Function? onStart;
  final Function? onProgress;
  final Function? onLoaded;
  final Function? onFailed;

  const WebViewCacheCore(
      {Key? key,
      required this.url,
      this.onStart,
      this.onProgress,
      this.onLoaded,
      this.onFailed})
      : super(key: key);

  static T? of<T extends CacheController>(BuildContext context) {
    return context
        .findAncestorStateOfType<_WebViewCacheCoreState>()
        ?.cacheController as T?;
  }
}

abstract class _WebViewCacheCoreState extends State<WebViewCacheCore> {
  CacheController? cacheController;
  bool isPageFinishCalled = false;

  @override
  void initState() {
    super.initState();
    _initController().then((value) {
      cacheController = value;
      setState(() {});
    }).catchError((err, stack) {
      debugPrint(stack);
    });
  }

  CacheController provideCacheController(WebViewController controller);

  Future<CacheController> _initController() async {
    WebViewController _controller = WebViewController();
    CacheController cacheController = provideCacheController(_controller);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(const Color(0x00000000));
    await cacheController.injectCore();
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          widget.onProgress?.call(progress);
        },
        onUrlChange: (UrlChange urlChange) {},
        onPageStarted: (String url) {
          widget.onStart?.call();
        },
        onPageFinished: (String url) {
          if (!isPageFinishCalled) {
            isPageFinishCalled = true;
          }
          widget.onLoaded?.call();
        },
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.prevent;
        },
      ),
    );
    await _controller.loadRequest(Uri.parse(widget.url));
    //超时 取消
    Future.delayed(_kMaxTimeout, () {
      if (!mounted || isPageFinishCalled) return;
      widget.onFailed?.call();
    });
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

abstract class CacheController {
  final WebViewController webViewController;

  CacheController(this.webViewController);

  //todo 注入js
  Future<void> injectCore();
}
