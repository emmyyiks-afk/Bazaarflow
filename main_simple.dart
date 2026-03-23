import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iyadunni_shopmore',
      home: Scaffold(
        appBar: AppBar(title: Text('iyadunni_shopmore Works!')),
        body: Center(child: Text('App is running')),
      ),
    );
  }
}
