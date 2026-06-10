import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen displays slides and transitions properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<DictationBloc>(
        create: (_) => DictationBloc(),
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Verify first page content is present
    expect(find.text('Welcome to OmniScribe AI'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next to navigate to next slide
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify second page content is present
    expect(find.text('Speak in Your Language'), findsOneWidget);

    // Tap Skip (mock route transition)
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify that onboarding preference has been recorded
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('seen_onboarding'), true);
  });
}
