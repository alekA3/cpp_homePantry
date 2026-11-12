import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

class AuthSessionProvider extends ChangeNotifier {
  AuthSessionProvider(AuthRepository repository)
    : user = repository.currentUser {
    _subscription = repository.userChanges.listen(
      (updatedUser) {
        user = updatedUser;
        error = null;
        notifyListeners();
      },
      onError: (Object streamError) {
        error = streamError;
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthUser?> _subscription;

  AuthUser? user;
  Object? error;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
