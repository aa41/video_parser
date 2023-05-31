import 'package:flutter/material.dart';
import 'package:video_parser/widget/webview_cache_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CacheCoreList(child: const HomePage()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final array = ['https://www.baidu.com', "https://m.bilibili.com"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (ctx) {
        return MaterialButton(
          onPressed: () {
            CacheCoreList.of(ctx)?.addBackgroundHandle(
              array[_index++ % 2],
              onStart: (controller) {
                print("onStart----");
              },
              onLoaded: (controller) {
                print("onLoaded----");
                Future.delayed(Duration(seconds: 3), () {
                  controller.removeSelf();
                });
              },
              onProgress: (progress, controller) {
                print("onProgress----$progress");
              },
              onFailed: (error, controller) {
                print("onFailed----$error");
              },
            );
          },
          child: Text('测试添加'),
        );
      }),
    );
  }
}
