import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pantry/core/auth/auth_repository.dart';
import 'package:home_pantry/main.dart';

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  testWidgets('registration validates input and accepts Ukrainian names', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Немає акаунта? Зареєструватися'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Зареєструватися'));
    await tester.pumpAndSettle();
    expect(find.text('Введіть ім’я.'), findsOneWidget);
    expect(find.text('Введіть електронну пошту.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Марія--Коваль');
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.text('Зареєструватися'));
    await tester.pumpAndSettle();
    expect(
      find.text('Використовуйте літери, пробіли, апострофи або дефіс.'),
      findsOneWidget,
    );
    expect(find.text('Введіть коректну електронну пошту.'), findsOneWidget);
    expect(
      find.text('Пароль має містити щонайменше 6 символів.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), "О’Коннор Марія");
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'maria@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(find.text('Зареєструватися'));
    await tester.pumpAndSettle();

    expect(repository.currentUser?.displayName, "О’Коннор Марія");
    expect(find.text('Профіль'), findsNothing);
    expect(find.text("О’Коннор Марія"), findsWidgets);
  });

  testWidgets('Firebase session signs out and signs back in', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Немає акаунта? Зареєструватися'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Марія Коваль');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'maria@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(find.text('Зареєструватися'));
    await tester.pumpAndSettle();

    expect(repository.currentUser?.email, 'maria@example.com');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Мій профіль'), findsOneWidget);
    await tester.tap(find.text('Мій профіль'));
    await tester.pumpAndSettle();
    expect(find.text('Профіль'), findsOneWidget);
    await tester.tap(find.text('РЕДАГУВАТИ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), "Марія O'Neil");
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'http://example.com/avatar.png',
    );
    await tester.tap(find.text('ЗБЕРЕГТИ'));
    await tester.pumpAndSettle();
    expect(find.text('Введіть коректне HTTPS-посилання.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(2),
      'https://example.com/avatar.png',
    );
    await tester.tap(find.text('ЗБЕРЕГТИ'));
    await tester.pumpAndSettle();
    expect(repository.currentUser?.displayName, "Марія O'Neil");
    expect(repository.currentUser?.photoUrl, 'https://example.com/avatar.png');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ЗМІНА ПАРОЛЯ'));
    expect(find.text('ЗМІНА ПАРОЛЯ'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'newsecret456');
    await tester.enterText(find.byType(TextFormField).at(4), 'newsecret456');
    await tester.ensureVisible(find.text('ЗМІНИТИ ПАРОЛЬ'));
    await tester.tap(find.text('ЗМІНИТИ ПАРОЛЬ'));
    await tester.pumpAndSettle();
    expect(repository.lastChangedPassword, 'newsecret456');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ПІД’ЄДНАТИ GOOGLE'));
    await tester.tap(find.text('ПІД’ЄДНАТИ GOOGLE'));
    await tester.pumpAndSettle();
    expect(repository.currentUser?.hasGoogleProvider, isTrue);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ВИЙТИ'));
    await tester.pumpAndSettle();
    expect(repository.currentUser, isNull);
    expect(find.text('Вхід'), findsOneWidget);
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'maria@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrect');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();
    expect(
      find.text('Неправильна електронна пошта або пароль.'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'newsecret456');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();
    expect(repository.currentUser?.email, 'maria@example.com');
    expect(find.text('Мій профіль'), findsOneWidget);
  });

  testWidgets('forgot password sends a reset email', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Забули пароль?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.tap(find.text('Відновити пароль'));
    await tester.pumpAndSettle();

    expect(repository.passwordResetEmail, 'person@example.com');
    expect(
      find.text(
        'Якщо для цієї адреси є акаунт, надіслано лист для відновлення пароля.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('password reset explains when email/password is disabled', (
    WidgetTester tester,
  ) async {
    repository.passwordResetErrorCode = 'operation-not-allowed';
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Забули пароль?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.tap(find.text('Відновити пароль'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('У Firebase вимкнено вхід електронною поштою'),
      findsOneWidget,
    );
  });

  testWidgets('Google sign-in button delegates to the auth repository', (
    WidgetTester tester,
  ) async {
    repository.googleSignInResult = true;
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Увійти через Google'));
    await tester.tap(find.text('Увійти через Google'));
    await tester.pumpAndSettle();

    expect(repository.googleSignInCalls, 1);
    expect(repository.currentUser?.hasGoogleProvider, isTrue);
  });

  testWidgets('Google user can set a password and sign in both ways', (
    WidgetTester tester,
  ) async {
    repository.googleSignInResult = true;
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Увійти через Google'));
    await tester.pumpAndSettle();
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    final googleUid = repository.currentUser!.uid;
    await tester.tap(find.text('Мій профіль'));
    await tester.pumpAndSettle();
    expect(find.text('ВСТАНОВИТИ ПАРОЛЬ'), findsOneWidget);
    expect(find.text('ПОТОЧНИЙ ПАРОЛЬ'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(2), 'googleSecret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'googleSecret123');
    await tester.ensureVisible(find.text('ВСТАНОВИТИ ПАРОЛЬ'));
    await tester.tap(find.text('ВСТАНОВИТИ ПАРОЛЬ'));
    await tester.pumpAndSettle();

    expect(repository.currentUser?.hasPasswordProvider, isTrue);
    expect(repository.currentUser?.hasGoogleProvider, isTrue);
    expect(
      find.textContaining('Тепер можна входити через Google'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ВИЙТИ'));
    await tester.pumpAndSettle();
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'google@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'googleSecret123');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();
    expect(repository.currentUser?.uid, googleUid);
    expect(repository.currentUser?.hasGoogleProvider, isTrue);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мій профіль'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ВИЙТИ'));
    await tester.pumpAndSettle();
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Увійти через Google'));
    await tester.pumpAndSettle();
    expect(repository.currentUser?.uid, googleUid);
    expect(repository.currentUser?.hasPasswordProvider, isTrue);
  });

  testWidgets('a persisted Firebase user opens the authenticated app', (
    WidgetTester tester,
  ) async {
    await repository.signUp(
      name: 'Олена',
      email: 'olena@example.com',
      password: 'secret123',
    );
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Мій профіль'), findsOneWidget);
    expect(find.text('Вхід'), findsNothing);
  });

  testWidgets('profile photo appears in both pantry navigation avatars', (
    WidgetTester tester,
  ) async {
    await repository.signUp(
      name: 'Олена',
      email: 'olena@example.com',
      password: 'secret123',
    );
    await repository.updateProfile(
      displayName: 'Олена',
      photoUrl: 'https://example.com/avatar.png',
    );
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pump();

    final avatars = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is NetworkImage &&
          (widget.image as NetworkImage).url ==
              'https://example.com/avatar.png',
    );
    expect(avatars, findsNWidgets(2));
  });

  testWidgets('pantry, stock, and category navigation keeps the app shell', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repository.signUp(
      name: 'Олена',
      email: 'olena@example.com',
      password: 'secret123',
    );
    await tester.pumpWidget(PantryApp(repository: repository));
    await tester.pumpAndSettle();
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Комори').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Відкрити запаси').first);
    await tester.pumpAndSettle();
    expect(find.text('Молоко 2.5%'), findsOneWidget);
    expect(find.text('Мій профіль'), findsOneWidget);

    await tester.tap(find.byTooltip('Переглянути').first);
    await tester.pumpAndSettle();
    expect(find.text('ПОТОЧНА КІЛЬКІСТЬ'), findsOneWidget);
    expect(find.text('Мій профіль'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Додати запас'));
    await tester.pumpAndSettle();
    expect(find.text('Мій профіль'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.getRect(find.text('Мій профіль')).left, lessThan(205));
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Категорії').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продукти').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Запаси в категорії'), findsOneWidget);
    expect(find.text('Молоко 2.5%'), findsOneWidget);
    expect(find.text('ТЕРМІН ПРИДАТНОСТІ'), findsWidgets);
    expect(find.text('Мій профіль'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final _users = <String, ({String name, String password})>{};
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  AuthUser? _googleUser;
  String? _googlePassword;
  String? passwordResetEmail;
  String? passwordResetErrorCode;
  bool googleSignInResult = false;
  int googleSignInCalls = 0;
  String? lastChangedPassword;
  int _nextUid = 0;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> get userChanges => Stream<AuthUser?>.multi((controller) {
    controller.add(_currentUser);
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });

  void _setCurrentUser(AuthUser? user) {
    _currentUser = user;
    if (user?.hasGoogleProvider == true) _googleUser = user;
    _changes.add(user);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_users.containsKey(email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    _users[email] = (name: name, password: password);
    _setCurrentUser(
      AuthUser(
        uid: 'user-${_nextUid++}',
        email: email,
        displayName: name,
        photoUrl: null,
        hasPasswordProvider: true,
        hasGoogleProvider: false,
      ),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (_googleUser?.email == email && _googlePassword == password) {
      _setCurrentUser(_googleUser);
      return;
    }
    final user = _users[email];
    if (user == null || user.password != password) {
      throw FirebaseAuthException(code: 'wrong-password');
    }
    _setCurrentUser(
      AuthUser(
        uid: 'user-${_nextUid++}',
        email: email,
        displayName: user.name,
        photoUrl: null,
        hasPasswordProvider: true,
        hasGoogleProvider: false,
      ),
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleSignInCalls++;
    if (googleSignInResult) {
      _setCurrentUser(
        _googleUser ??
            const AuthUser(
              uid: 'google-user',
              email: 'google@example.com',
              displayName: 'Google User',
              photoUrl: null,
              hasPasswordProvider: false,
              hasGoogleProvider: true,
            ),
      );
    }
    return googleSignInResult;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (passwordResetErrorCode != null) {
      throw FirebaseAuthException(code: passwordResetErrorCode!);
    }
    passwordResetEmail = email;
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String? photoUrl,
  }) async {
    final user = _currentUser!;
    _setCurrentUser(
      AuthUser(
        uid: user.uid,
        email: user.email,
        displayName: displayName,
        photoUrl: photoUrl,
        hasPasswordProvider: user.hasPasswordProvider,
        hasGoogleProvider: user.hasGoogleProvider,
      ),
    );
    _users[user.email] = (
      name: displayName,
      password: _users[user.email]?.password ?? '',
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser!;
    final account = _users[user.email]!;
    if (account.password != currentPassword) {
      throw FirebaseAuthException(code: 'wrong-password');
    }
    _users[user.email] = (name: account.name, password: newPassword);
    lastChangedPassword = newPassword;
  }

  @override
  Future<void> setPassword({required String newPassword}) async {
    final user = _currentUser!;
    if (!user.hasGoogleProvider) {
      throw FirebaseAuthException(code: 'google-provider-required');
    }
    _googlePassword = newPassword;
    lastChangedPassword = newPassword;
    _setCurrentUser(
      AuthUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        hasPasswordProvider: true,
        hasGoogleProvider: true,
      ),
    );
  }

  @override
  Future<bool> linkGoogleAccount() async {
    final user = _currentUser!;
    _setCurrentUser(
      AuthUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        hasPasswordProvider: user.hasPasswordProvider,
        hasGoogleProvider: true,
      ),
    );
    return true;
  }

  @override
  Future<void> signOut() async => _setCurrentUser(null);

  Future<void> dispose() => _changes.close();
}
