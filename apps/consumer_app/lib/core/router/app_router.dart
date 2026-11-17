import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/catalog/presentation/product_list_screen.dart';
import '../../features/quotation/presentation/quotation_form_screen.dart';
import '../../features/quotation/presentation/quotation_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bridges Riverpod state to go_router so redirects re-run on login/logout.
  final authState = ValueNotifier<AuthStatus>(ref.read(authControllerProvider));
  ref.listen<AuthStatus>(authControllerProvider, (_, next) => authState.value = next);
  ref.onDispose(authState.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authState,
    redirect: (context, state) {
      final status = authState.value;
      final location = state.matchedLocation;

      if (status == AuthStatus.unknown) return location == '/splash' ? null : '/splash';
      if (status == AuthStatus.unauthenticated) return location == '/login' ? null : '/login';
      // Authenticated: keep users away from the splash/login screens.
      if (location == '/login' || location == '/splash') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const QuotationListScreen()),
      GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
      GoRoute(
        path: '/quotations/new/:productCode',
        builder: (_, state) =>
            QuotationFormScreen(productCode: state.pathParameters['productCode']),
      ),
      GoRoute(
        path: '/quotations/:id',
        builder: (_, state) => QuotationFormScreen(quotationId: state.pathParameters['id']),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
