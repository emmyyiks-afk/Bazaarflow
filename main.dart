import 'package:flutter/material.dart';
import 'package:iyadunni_shopmore/Homepage.dart';
import 'package:iyadunni_shopmore/HomepageScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'themeprovider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Iyadunni_shopmore',
          theme: themeProvider.currentTheme, // Use the theme from provider
          home: HomepageScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
