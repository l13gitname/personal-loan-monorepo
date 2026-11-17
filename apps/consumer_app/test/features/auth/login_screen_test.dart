import 'package:consumer_app/core/network/api_exception.dart';
import 'package:consumer_app/features/auth/data/auth_models.dart';
import 'package:consumer_app/features/auth/data/auth_repository.dart';
import 'package:consumer_app/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.hasSession()).thenAnswer((_) async => false);
  });

  Future<void> pumpLogin(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

  testWidgets('does not call the API when the form is empty', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('This field is required'), findsWidgets);
    verifyNever(() => repo.login(any(), any()));
  });

  testWidgets('shows the server message on bad credentials', (tester) async {
    when(() => repo.login(any(), any()))
        .thenThrow(const ApiException('Invalid email or password'));
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'demo@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('Invalid email or password'), findsOneWidget);
  });

  testWidgets('submits the trimmed credentials', (tester) async {
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => const UserProfile(
        id: 'u-1',
        email: 'demo@example.com',
        firstName: 'Demo',
        lastName: 'User',
      ),
    );
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'demo@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'ChangeMe123!');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    verify(() => repo.login('demo@example.com', 'ChangeMe123!')).called(1);
  });
}
