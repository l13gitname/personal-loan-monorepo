import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

/// ViewModel for the login screen: holds loading/error state of the action.
class LoginViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
    if (!state.hasError) {
      ref.read(authControllerProvider.notifier).signedIn();
    }
  }
}

final loginViewModelProvider =
    AsyncNotifierProvider<LoginViewModel, void>(LoginViewModel.new);
