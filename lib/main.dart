import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRM393 Coffee',
      home: Scaffold(
        appBar: AppBar(title: const Text('PRM393 Coffee')),
        body: const Center(child: Text('Hello, Flutter!')),
      ),
    );
  }
}
