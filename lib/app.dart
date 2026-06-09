import 'package:flutter/material.dart';
import 'package:omniscribe_ai/src/screens/home_screen.dart';

class OmniScribeApp extends StatelessWidget {
  const OmniScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniScribe AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
