import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide session state. The router listens to this for redirects.
class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    _restore();
    return AuthStatus.unknown;
  }

  Future<void> _restore() async {
    final has = await ref.read(authRepositoryProvider).hasSession();
    state = has ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  void signedIn() => state = AuthStatus.authenticated;

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = AuthStatus.unauthenticated;
  }

  /// Called by the HTTP layer when a refresh fails.
  Future<void> sessionExpired() async {
    await ref.read(authRepositoryProvider).clearLocalSession();
    state = AuthStatus.unauthenticated;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthStatus>(AuthController.new);
