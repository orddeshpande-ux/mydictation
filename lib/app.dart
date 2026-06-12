import 'package:flutter/material.dart';
import 'package:omniscribe_ai/src/ui/theme.dart';
import 'package:omniscribe_ai/src/screens/main_shell.dart';
import 'package:omniscribe_ai/src/screens/onboarding_screen.dart';

class OmniScribeApp extends StatelessWidget {
  final bool seenOnboarding;

  const OmniScribeApp({
    super.key,
    required this.seenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniScribe AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: seenOnboarding ? const MainShell() : const OnboardingScreen(),
    );
  }
}
