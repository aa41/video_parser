import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_parser/global.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:collection/collection.dart';

const _kMaxTimeout = Duration(seconds: 60);

const double _kDebugContainerHeight = 150.0;

class CacheCoreList extends StatefulWidget {
  final Widget child;

  const CacheCoreList({Key? key, required this.child}) : super(key: key);

  static CacheCoreDelegate? of(BuildContext context) {
    return context.findAncestorStateOfType<CacheCoreListState>();
  }

  static CacheCoreDelegate? ofRoot(BuildContext context) {
    return context.findRootAncestorStateOfType<CacheCoreListState>();
  }

  @override
  State<CacheCoreList> createState() => CacheCoreListState();
}

class CacheCoreListState extends State<CacheCoreList>
    with CacheCoreDelegate<CacheCoreList> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    Widget result;
    if (!isDebug) {
      children = _cores;
      result = Stack(
        children: [
          ...children,
          widget.child,
        ],
      );
    } else {
      children = _cores.mapIndexed((index, element) {
        return Container(
          width: _kDebugContainerHeight,
          height: _kDebugContainerHeight,
          child: element,
        );
      }).toList();
      result = Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: _kDebugContainerHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      );
    }

    return result;
  }

  @override
  void dispose() {
    _cores.clear();
    super.dispose();
  }
}

mixin CacheCoreDelegate<T extends StatefulWidget> on State<T> {
  final List<WebViewCacheCore> _cores = [];

  void addBackgroundHandle(String url,
      {Function(CacheController controller)? onStart,
      Function(int progress, CacheController controller)? onProgress,
      Function(CacheController controller)? onLoaded,
      Function(Object? error, CacheController controller)? onFailed}) {
    dynamic _onInit = (CacheController controller) {};
    dynamic _onFailed = (Object? error, CacheController controller) {
      onFailed?.call(error, controller);
      controller.removeSelf();
    };
    dynamic _onStart = (CacheController controller) {
      try {
        onStart?.call(controller);
      } catch (e, stack) {
        _onFailed.call(stack, controller);
      }
    };

    dynamic _onProgress = (int progress, CacheController controller) {
      try {
        onProgress?.call(progress, controller);
      } catch (e, stack) {
        _onFailed.call(stack, controller);
      }
    };
    dynamic _onLoaded = (CacheController controller) {
      try {
        onLoaded?.call(controller);
      } catch (e, stack) {
        _onFailed.call(stack, controller);
      }
    };

    if (mounted) {
      setState(() {
        _cores.add(WebViewCacheCore(
          url: url,
          onStart: _onStart,
          onProgress: _onProgress,
          onLoaded: _onLoaded,
          onFailed: _onFailed,
          onInit: _onInit,
        ));
      });
    }
  }

  Future<void> removeFromController(CacheController controller) async {
    Future.microtask(() {
      _cores.remove(controller.state.widget);
      if (mounted) {
        setState(() {});
      }
    });
  }
}

class WebViewCacheCore extends StatefulWidget {
  final String url;
  final Function(CacheController controller)? onStart;
  final Function(int progress, CacheController controller)? onProgress;
  final Function(CacheController controller)? onLoaded;
  final Function(Object? error, CacheController controller)? onFailed;
  final Function(CacheController controller)? onInit;

  const WebViewCacheCore(
      {Key? key,
      required this.url,
      this.onStart,
      this.onProgress,
      this.onLoaded,
      this.onFailed,
      this.onInit})
      : super(key: key);

  static T? of<T extends CacheController>(BuildContext context) {
    return context
        .findAncestorStateOfType<_WebViewCacheCoreState>()
        ?.cacheController as T?;
  }

  @override
  State<StatefulWidget> createState() => _WebViewCacheCoreState();
}

class _WebViewCacheCoreState extends State<WebViewCacheCore> {
  CacheController? cacheController;
  bool _isPageFinishCalled = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initController().then((value) {
      Future.microtask(() {
        if (mounted) {
          cacheController = value;
          setState(() {});
        }
      });
    }).catchError((err, stack) {
      debugPrint("$stack");
    });
  }

  Future<CacheController> _initController() async {
    Completer<CacheController> completer = Completer();
    WebViewController _controller = WebViewController();
    CacheController cacheController = CacheController(_controller, this);
    widget.onInit?.call(cacheController);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(const Color(0x00000000));
    await cacheController.injectCore();
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          widget.onProgress?.call(progress, cacheController);
          if (progress == 100) {
            if (!_isPageFinishCalled) {
              _isPageFinishCalled = true;
              widget.onLoaded?.call(cacheController);
            }
          }
        },
        onUrlChange: (UrlChange urlChange) {},
        onPageStarted: (String url) {
          widget.onStart?.call(cacheController);
        },
        onPageFinished: (String url) {
          if (!_isPageFinishCalled) {
            _isPageFinishCalled = true;
            widget.onLoaded?.call(cacheController);
          }
        },
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          //should not jump to other http
          return NavigationDecision.prevent;
        },
      ),
    );
    if (!completer.isCompleted) {
      completer.complete(cacheController);
    }
    await _controller.loadRequest(Uri.parse(widget.url));
    //超时 取消
    Future.delayed(_kMaxTimeout, () {
      if (_isDisposed) return;
      widget.onFailed?.call(ArgumentError("core timeout!!!"), cacheController);
    });
    return completer.future;
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
    _isDisposed = true;
    cacheController?.dispose();
    super.dispose();
  }
}

class CacheController {
  final WebViewController webViewController;
  final State<WebViewCacheCore> state;
  bool _isDisposed = false;

  CacheController(this.webViewController, this.state);

  bool get isDisposed => _isDisposed;

  CacheCoreDelegate? findTargetCacheCore() {
    if (isDisposed) return null;
    return CacheCoreList.of(state.context);
  }

  void removeSelf() {
    findTargetCacheCore()?.removeFromController(this);
  }

  Future<void> injectCore() async {
    if (isDisposed) return;
    Completer<void> completer = Completer();
    try {
      //  await webViewController.runJavaScript("");
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e, stack) {
      completer.completeError(e, stack);
    }

    return completer.future;
  }

  void dispose() {
    _isDisposed = true;
  }
}
