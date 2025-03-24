// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:alphazed/models/game_state.dart';
import 'package:alphazed/services/audio_service.dart';

import 'package:alphazed/main.dart';
import 'package:alphazed/screens/game_screen.dart';
import 'package:alphazed/screens/letter_to_picture.dart';

void main() {
  testWidgets('GameScreen loads correctly', (WidgetTester tester) async {
    // Set up the providers for the test.
    final audioService = AudioService();
    final gameState = GameState(audioService: audioService);

    // Wrap the app with MultiProvider to provide dependencies.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AudioService>.value(value: audioService),
          ChangeNotifierProvider<GameState>.value(value: gameState),
        ],
        child: MyApp(),
      ),
    );

    // Verify that the LetterPictureMatch widget is present.
    expect(find.byType(LetterPictureMatch), findsOneWidget);

    // Verify that the SafeArea widget wrapping the LetterPictureMatch is present.
    final safeAreaFinder = find.ancestor(of: find.byType(LetterPictureMatch), matching: find.byType(SafeArea));
    expect(safeAreaFinder, findsOneWidget);
  });
}
