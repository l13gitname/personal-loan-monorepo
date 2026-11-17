import 'package:consumer_app/app.dart';
import 'package:consumer_app/core/network/providers.dart';
import 'package:consumer_app/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Run on a device/emulator:
///   flutter test integration_test --dart-define-from-file=env/dev.json
///
/// The first test needs no backend. The second needs the API running with
/// the seeded database and a registered user (see README).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a signed-out user is sent to the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(InMemoryTokenStorage())],
        child: const ConsumerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets(
    'login -> product list (needs a running backend)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tokenStorageProvider.overrideWithValue(InMemoryTokenStorage())],
          child: const ConsumerApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'demo@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'ChangeMe123!');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('My quotations'), findsOneWidget);

      await tester.tap(find.byKey(const Key('new-quotation')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Personal loan'), findsOneWidget);
      expect(find.text('Motorcycle hire-purchase'), findsOneWidget);
    },
    skip: const bool.fromEnvironment('E2E_BACKEND') == false,
  );
}
