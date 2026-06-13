import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harfidar/features/auth/presentation/screens/login_screen.dart';
import 'package:harfidar/features/auth/presentation/providers/auth_provider.dart';
import 'package:harfidar/core/router/route_names.dart';

// Helper to wrap widget under test
Widget buildLoginScreen({AuthState? authState}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: RouteNames.home, builder: (_, __) => const Scaffold(body: Text('Home'))),
      GoRoute(path: RouteNames.register, builder: (_, __) => const Scaffold(body: Text('Register'))),
      GoRoute(path: RouteNames.forgotPassword, builder: (_, __) => const Scaffold(body: Text('Forgot'))),
    ],
  );

  return ProviderScope(
    overrides: authState != null
        ? [authStateProvider.overrideWith((ref) => AuthNotifier(ref)..setStateForTest(authState))]
        : [],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.textContaining('Email'), findsWidgets);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'invalid');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.textContaining('valid'), findsWidgets);
    });

    testWidgets('shows validation error for short password', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.textContaining('8'), findsWidgets);
    });

    testWidgets('has register link', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('سجل'), findsWidgets);
    });

    testWidgets('has forgot password link', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('نسيت'), findsOneWidget);
    });
  });
}
