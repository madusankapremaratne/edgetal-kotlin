import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:edgetal/app/app.dart';
import 'package:edgetal/features/import/import_screen.dart';

void main() {
  testWidgets('App boots to the Candidates screen', (tester) async {
    // Avoid network font fetches during the test.
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const ProviderScope(child: EdgeTalApp()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Candidates'), findsWidgets);
    expect(find.byType(NavigationBar).evaluate().isNotEmpty ||
        find.text('EdgeTal').evaluate().isNotEmpty, isTrue);
  });

  // Regression: Import / Details are pushed by the root navigator, outside the
  // shell's Scaffold. Their TextFields must still find a Material ancestor
  // (PageScaffold now provides one).
  testWidgets('Pushed screens render their TextField without a Scaffold parent',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ImportScreen())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);
  });
}
