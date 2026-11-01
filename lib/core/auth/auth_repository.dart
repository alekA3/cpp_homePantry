import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool hasPasswordProvider;
  final bool hasGoogleProvider;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.hasPasswordProvider,
    required this.hasGoogleProvider,
  });
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> get userChanges;
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signIn({required String email, required String password});
  Future<bool> signInWithGoogle();
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> updateProfile({
    required String displayName,
    required String? photoUrl,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> setPassword({required String newPassword});
  Future<bool> linkGoogleAccount();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    final providers = user.providerData.map((provider) => provider.providerId);
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      hasPasswordProvider: providers.contains(EmailAuthProvider.PROVIDER_ID),
      hasGoogleProvider: providers.contains(GoogleAuthProvider.PROVIDER_ID),
    );
  }

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges => _auth.userChanges().map(_mapUser);

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<OAuthCredential?> _googleCredential() async {
    final signIn = GoogleSignIn.instance;
    final initialization = _googleInitialization ??= signIn.initialize();
    await initialization;
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Google не повернув токен автентифікації.',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return true;
    }

    try {
      final credential = await _googleCredential();
      if (credential == null) return false;
      await _auth.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: error.description,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Користувач не авторизований.',
      );
    }
    await user.updateDisplayName(displayName.trim());
    await user.updatePhotoURL(photoUrl);
    await user.reload();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Користувач не авторизований.',
      );
    }
    if (!user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    )) {
      throw FirebaseAuthException(
        code: 'email-provider-required',
        message: 'Для цього акаунта пароль задається через Google.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> setPassword({required String newPassword}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Користувач не авторизований.',
      );
    }

    final providers = user.providerData.map((provider) => provider.providerId);
    if (providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      throw FirebaseAuthException(
        code: 'email-provider-already-linked',
        message: 'Для цього акаунта пароль уже встановлено.',
      );
    }
    if (!providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      throw FirebaseAuthException(
        code: 'google-provider-required',
        message: 'Для встановлення пароля спершу увійдіть через Google.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: newPassword,
    );
    final linkedCredential = await user.linkWithCredential(credential);
    await linkedCredential.user?.reload();
  }

  @override
  Future<bool> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Користувач не авторизований.',
      );
    }
    if (kIsWeb) {
      await user.linkWithPopup(GoogleAuthProvider());
      return true;
    }

    try {
      final credential = await _googleCredential();
      if (credential == null) return false;
      await user.linkWithCredential(credential);
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: error.description,
      );
    }
  }

  @override
  Future<void> signOut() async {
    final isGoogleUser = _auth.currentUser?.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    if (!kIsWeb && isGoogleUser == true) {
      final initialization = _googleInitialization ??= GoogleSignIn.instance
          .initialize();
      await initialization;
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}
