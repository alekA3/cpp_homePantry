import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/auth/auth_repository.dart';
import 'core/auth/auth_session_provider.dart';
import 'core/pantry/pantry_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/app_button.dart';
import 'features/pantry/pantry_screens.dart';
import 'firebase_options.dart';

const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: 'https://88d2eeb55c4ac11e2b5507b7617756b2@o4512357863718912.ingest.de.sentry.io/4512357889146960',
);

Future<void> main() async {
  Future<void> startApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (_supportsCrashlytics) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    runApp(PantryApp());
  }

  if (kIsWeb && _sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) => options.dsn = _sentryDsn,
      appRunner: startApp,
    );
    return;
  }

  await startApp();
}

bool get _supportsCrashlytics =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

Future<void> _logAnalyticsEvent(String name) async {
  if (Firebase.apps.isEmpty ||
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)) {
    return;
  }
  await FirebaseAnalytics.instance.logEvent(name: name);
}

Future<void> _showAppMessage(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: lightOlive,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: olive.withValues(alpha: 0.65)),
      ),
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: olive),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Повідомлення',
              style: TextStyle(color: olive, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Закрити',
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close, color: olive),
          ),
        ],
      ),
      content: Text(message, style: const TextStyle(color: Colors.black87)),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: olive,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class PantryApp extends StatelessWidget {
  PantryApp({super.key, AuthRepository? repository})
    : repository = repository ?? FirebaseAuthRepository();

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthSessionProvider(repository)),
        ChangeNotifierProvider(create: (_) => PantryProvider()),
      ],
      child: MaterialApp(
        title: 'Домашня комора',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: pageColor,
          colorScheme: ColorScheme.fromSeed(seedColor: olive),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        home: _AuthGate(repository: repository),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.repository});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthSessionProvider>(
      builder: (context, session, _) {
        if (session.error != null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Не вдалося перевірити сеанс: ${_authErrorMessage(session.error!)}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final user = session.user;
        if (user == null) return LoginScreen(repository: repository);
        return HomeScreen(user: user, repository: repository);
      },
    );
  }
}

String _authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Перевірте формат електронної пошти.',
      'user-not-found' => 'Акаунт із такою електронною поштою не знайдено.',
      'wrong-password' ||
      'invalid-credential' => 'Неправильна електронна пошта або пароль.',
      'email-already-in-use' => 'Акаунт із такою електронною поштою вже існує.',
      'weak-password' => 'Пароль має містити щонайменше 6 символів.',
      'too-many-requests' => 'Забагато спроб. Спробуйте пізніше.',
      'network-request-failed' => 'Перевірте підключення до інтернету.',
      'requires-recent-login' => 'Для цієї дії потрібно вийти й увійти знову.',
      'provider-already-linked' => 'Google уже під’єднано до цього акаунта.',
      'email-provider-already-linked' =>
        'Пароль для цього акаунта вже встановлено.',
      'google-provider-required' =>
        'Щоб встановити пароль, спершу увійдіть через Google.',
      'credential-already-in-use' =>
        'Цей Google-акаунт уже пов’язано з іншим користувачем.',
      'operation-not-allowed' =>
        'У Firebase Console не ввімкнено цей спосіб входу.',
      'unauthorized-domain' => 'Додайте адресу сайту до авторизованих доменів Firebase Authentication.',
      'popup-closed-by-user' => 'Вхід через Google скасовано.',
      'popup-blocked' => 'Дозвольте спливаючі вікна для входу через Google.',
      'operation-not-supported-in-this-environment' =>
        'Цей спосіб входу не підтримується в поточному середовищі.',
      'account-exists-with-different-credential' =>
        'Для цієї пошти вже є акаунт з іншим способом входу.',
      'email-provider-required' =>
        'Для цього акаунта пароль задається через Google.',
      'missing-google-token' =>
        'Не вдалося отримати токен Google. Перевірте налаштування OAuth.',
      'google-sign-in-failed' => 'Не вдалося увійти через Google. Перевірте налаштування OAuth і підпису застосунку.',
      'no-current-user' => 'Сеанс завершився. Увійдіть знову.',
      _ => 'Не вдалося виконати дію. Спробуйте ще раз.',
    };
  }
  return 'Не вдалося виконати дію. Перевірте інтернет і спробуйте ще раз.';
}

String _passwordResetErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' ||
      'missing-email' => 'Перевірте адресу електронної пошти.',
      'user-not-found' => 'Для цієї адреси не знайдено акаунт із паролем. Якщо ви реєструвалися через Google, увійдіть через Google і встановіть пароль у профілі.',
      'operation-not-allowed' => 'У Firebase вимкнено вхід електронною поштою та паролем. Увімкніть Email/Password у проєкті homepantry-f22f4.',
      'too-many-requests' || 'quota-exceeded' =>
        'Firebase тимчасово обмежив надсилання листів. Спробуйте пізніше.',
      'network-request-failed' => 'Не вдалося зв’язатися з Firebase. Перевірте інтернет і спробуйте ще раз.',
      _ => 'Firebase не зміг надіслати лист. Перевірте налаштування Email/Password у проєкті homepantry-f22f4 і спробуйте ще раз.',
    };
  }
  return 'Не вдалося зв’язатися з Firebase. Перевірте інтернет і спробуйте ще раз.';
}

// Спільна картка для форм авторизації.
class AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5DE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

// Спільна оболонка екранів авторизації.
class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: olive,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.kitchen_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Домашня комора',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE1E2D9))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('АБО', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Color(0xFFE1E2D9))),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Text(
          'G',
          style: TextStyle(
            color: olive,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        label: const Text('Увійти через Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.isPassword = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: const Color(0xFFF8F8F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      onPressed: () {
                        setState(() => _obscureText = !_obscureText);
                      },
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введіть електронну пошту.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Введіть коректну електронну пошту.';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введіть пароль.';
  if (value.length < 6) return 'Пароль має містити щонайменше 6 символів.';
  return null;
}

String? _validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Введіть ім’я.';
  if (!RegExp(
    r"^[A-Za-zА-Яа-яІіЇїЄєҐґ]+(?:[ '\u2019\u02BC-][A-Za-zА-Яа-яІіЇїЄєҐґ]+)*$",
  ).hasMatch(name)) {
    return 'Використовуйте літери, пробіли, апострофи або дефіс.';
  }
  return null;
}

String? _validatePhotoUrl(String? value) {
  final url = value?.trim() ?? '';
  if (url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return 'Введіть коректне HTTPS-посилання.';
  }
  return null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    try {
      await widget.repository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isSubmitting = true);
    try {
      final signedIn = await widget.repository.signInWithGoogle();
      if (!signedIn && mounted) _showMessage('Вхід через Google скасовано.');
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    unawaited(_showAppMessage(context, message));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Вхід',
        subtitle: 'Увійдіть, щоб продовжити роботу',
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                _AuthTextField(
                  label: 'Електронна пошта',
                  hint: 'name@example.com',
                  controller: emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                _AuthTextField(
                  label: 'Пароль',
                  hint: 'Введіть пароль',
                  controller: passwordController,
                  validator: _validatePassword,
                  isPassword: true,
                  autofillHints: const [AutofillHints.password],
                ),
                AppButton(
                  text: 'Увійти',
                  onPressed: isSubmitting ? null : _signIn,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ForgotPasswordScreen(repository: widget.repository),
                  ),
                );
              },
              child: const Text(
                'Забули пароль?',
                style: TextStyle(color: olive),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _AuthDivider(),
          const SizedBox(height: 14),
          _GoogleSignInButton(
            onPressed: isSubmitting ? null : _signInWithGoogle,
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterScreen(repository: widget.repository),
                  ),
                );
              },
              child: const Text(
                'Немає акаунта? Зареєструватися',
                style: TextStyle(color: olive),
              ),
            ),
          ),
          if (isSubmitting) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

// 2. Реєстрація.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    try {
      await widget.repository.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isSubmitting = true);
    try {
      final signedIn = await widget.repository.signInWithGoogle();
      if (signedIn && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        _showMessage('Вхід через Google скасовано.');
      }
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    unawaited(_showAppMessage(context, message));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Реєстрація',
        subtitle: 'Створіть акаунт для домашньої комори',
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                _AuthTextField(
                  label: 'Ім’я',
                  hint: 'Ваше ім’я',
                  controller: nameController,
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                _AuthTextField(
                  label: 'Електронна пошта',
                  hint: 'name@example.com',
                  controller: emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.newUsername],
                ),
                _AuthTextField(
                  label: 'Пароль',
                  hint: 'Введіть пароль',
                  controller: passwordController,
                  validator: _validatePassword,
                  isPassword: true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                AppButton(
                  text: 'Зареєструватися',
                  onPressed: isSubmitting ? null : _register,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _AuthDivider(),
          const SizedBox(height: 14),
          _GoogleSignInButton(
            onPressed: isSubmitting ? null : _signInWithGoogle,
          ),
          if (isSubmitting) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Уже маєте акаунт? Увійти',
                style: TextStyle(color: olive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    late final String message;
    try {
      await widget.repository.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      message = 'Якщо для цієї адреси є акаунт, надіслано лист для відновлення пароля.';
    } catch (error) {
      message = _passwordResetErrorMessage(error);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (mounted) {
      await _showAppMessage(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Відновлення пароля',
        subtitle: 'Введіть електронну пошту для відновлення доступу',
        children: [
          Form(
            key: formKey,
            child: _AuthTextField(
              label: 'Електронна пошта',
              hint: 'name@example.com',
              controller: emailController,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'Якщо ви входили лише через Google і ще не встановили пароль, спершу увійдіть через Google, відкрийте профіль і встановіть пароль. Після цього можна буде надіслати лист для його скидання.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          AppButton(
            text: 'Відновити пароль',
            onPressed: isSubmitting ? null : _sendResetEmail,
          ),
          if (isSubmitting) const Center(child: CircularProgressIndicator()),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Повернутися до входу',
                style: TextStyle(color: olive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AuthUser user;
  final AuthRepository repository;

  const HomeScreen({super.key, required this.user, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isProfileSelected = false;
  String selectedSectionKey = 'home';
  GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();

  String get userName => widget.user.displayName.isEmpty
      ? widget.user.email
      : widget.user.displayName;
  String get userEmail => widget.user.email;

  @override
  void initState() {
    super.initState();
    unawaited(_logAnalyticsEvent('home_screen_opened'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          _showAppMessage(context, 'Сеанс відновлено або вхід виконано.'),
        );
      }
    });
  }

  void _openProfile() {
    if (!isProfileSelected) {
      unawaited(_logAnalyticsEvent('profile_opened'));
    }
    setState(() => isProfileSelected = true);
  }

  void _selectSection(_HomeSection section) {
    setState(() {
      selectedSectionKey = section.key;
      isProfileSelected = false;
      _contentNavigatorKey = GlobalKey<NavigatorState>();
    });
    if (section.key == 'all-stock') {
      unawaited(_logAnalyticsEvent('products_list_opened'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantries = context.watch<PantryProvider>().pantries;
    final sections = [
      const _HomeSection('home', 'Головна', Icons.home_outlined),
      const _HomeSection('pantries', 'Комори', Icons.kitchen_outlined),
      const _HomeSection('all-stock', 'Усі запаси', Icons.inventory_2_outlined),
      for (final pantry in pantries)
        _HomeSection(
          'pantry:${pantry.id}',
          pantry.name,
          Icons.storage_outlined,
          pantryId: pantry.id,
        ),
      const _HomeSection('categories', 'Категорії', Icons.category_outlined),
      const _HomeSection('reminders', 'Нагадування', Icons.notifications_none),
    ];
    var selectedIndex = sections.indexWhere(
      (section) => section.key == selectedSectionKey,
    );
    if (selectedIndex < 0) selectedIndex = 0;
    final selectedSection = sections[selectedIndex];
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 205,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(Icons.kitchen, color: olive, size: 27),
                        SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            'Комора',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 2,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              selected: selectedSectionKey == section.key,
                              selectedTileColor: lightOlive,
                              leading: Icon(
                                section.icon,
                                color: selectedSectionKey == section.key
                                    ? olive
                                    : Colors.grey.shade700,
                                size: 20,
                              ),
                              title: Text(
                                section.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedSectionKey == section.key
                                      ? olive
                                      : Colors.black87,
                                  fontWeight: selectedSectionKey == section.key
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () => _selectSection(section),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: _UserAvatar(photoUrl: widget.user.photoUrl),
                      title: const Text(
                        'Мій профіль',
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(userName, style: TextStyle(fontSize: 11)),
                      onTap: () {
                        _openProfile();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 65,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _openProfile,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              _UserAvatar(photoUrl: widget.user.photoUrl),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isProfileSelected
                        ? ProfileContent(
                            user: widget.user,
                            repository: widget.repository,
                          )
                        : ClipRect(
                            child: Navigator(
                              key: _contentNavigatorKey,
                              onGenerateRoute: (settings) =>
                                  MaterialPageRoute<void>(
                                    settings: settings,
                                    builder: (_) => PantrySectionScreen(
                                      sectionKey: selectedSection.key,
                                      pantryId: selectedSection.pantryId,
                                      onOpenSection: (key) {
                                        final target = sections
                                            .where(
                                              (section) => section.key == key,
                                            )
                                            .firstOrNull;
                                        if (target != null) {
                                          _selectSection(target);
                                        }
                                      },
                                    ),
                                  ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSection {
  const _HomeSection(this.key, this.title, this.icon, {this.pantryId});

  final String key;
  final String title;
  final IconData icon;
  final String? pantryId;
}

class ProfileContent extends StatefulWidget {
  final AuthUser user;
  final AuthRepository repository;

  const ProfileContent({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  final profileFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController photoUrlController;
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isEditing = false;
  bool isSavingProfile = false;
  bool isChangingPassword = false;
  bool isLinkingGoogle = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.displayName);
    photoUrlController = TextEditingController(
      text: widget.user.photoUrl ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.displayName != widget.user.displayName) {
      nameController.text = widget.user.displayName;
    }
    if (oldWidget.user.photoUrl != widget.user.photoUrl) {
      photoUrlController.text = widget.user.photoUrl ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    photoUrlController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    unawaited(_showAppMessage(context, message));
  }

  Future<void> _saveProfile() async {
    if (!profileFormKey.currentState!.validate()) return;
    setState(() => isSavingProfile = true);
    try {
      await widget.repository.updateProfile(
        displayName: nameController.text.trim(),
        photoUrl: photoUrlController.text.trim().isEmpty
            ? null
            : photoUrlController.text.trim(),
      );
      if (!mounted) return;
      setState(() => isEditing = false);
      _showMessage('Профіль збережено.');
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isSavingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (!passwordFormKey.currentState!.validate()) return;
    setState(() => isChangingPassword = true);
    try {
      if (widget.user.hasPasswordProvider) {
        await widget.repository.changePassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );
      } else {
        await widget.repository.setPassword(
          newPassword: newPasswordController.text,
        );
      }
      if (!mounted) return;
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _showMessage(
        widget.user.hasPasswordProvider ? 'Пароль успішно змінено.' : 'Пароль встановлено. Тепер можна входити через Google або пошту й пароль.',
      );
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isChangingPassword = false);
    }
  }

  Future<void> _linkGoogle() async {
    setState(() => isLinkingGoogle = true);
    try {
      final linked = await widget.repository.linkGoogleAccount();
      if (mounted) {
        _showMessage(
          linked
              ? 'Google під’єднано до акаунта.'
              : 'Під’єднання Google скасовано.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isLinkingGoogle = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.repository.signOut();
      if (mounted) {
        unawaited(_showAppMessage(context, 'Ви вийшли з акаунта.'));
      }
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Профіль',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildAccountPanel(isWide),
                  const SizedBox(height: 24),
                  _buildPasswordPanel(),
                  const SizedBox(height: 24),
                  _buildAccountStats(isWide),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountPanel(bool isWide) {
    final fields = Form(
      key: profileFormKey,
      child: Column(
        children: [
          _profileField(
            'ІМ’Я ТА ПРІЗВИЩЕ',
            controller: nameController,
            readOnly: !isEditing,
            validator: _validateName,
          ),
          const SizedBox(height: 12),
          _profileField(
            'ЕЛЕКТРОННА ПОШТА',
            initialValue: widget.user.email,
            readOnly: true,
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            _profileField(
              'HTTPS-ПОСИЛАННЯ НА ФОТО',
              controller: photoUrlController,
              readOnly: false,
              validator: _validatePhotoUrl,
              onChanged: (_) => setState(() {}),
            ),
            if (photoUrlController.text.trim().isNotEmpty &&
                _validatePhotoUrl(photoUrlController.text) == null)
              _buildPhotoPreview(photoUrlController.text.trim()),
          ],
        ],
      ),
    );

    return _profilePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 22),
                Expanded(child: fields),
              ],
            )
          else ...[
            _buildAvatar(),
            const SizedBox(height: 18),
            fields,
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isEditing)
                ElevatedButton.icon(
                  onPressed: () => setState(() => isEditing = true),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('РЕДАГУВАТИ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: olive,
                    foregroundColor: Colors.white,
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: isSavingProfile ? null : _saveProfile,
                  icon: const Icon(Icons.check, size: 17),
                  label: Text(isSavingProfile ? 'ЗБЕРЕЖЕННЯ…' : 'ЗБЕРЕГТИ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: olive,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton(
                  onPressed: isSavingProfile
                      ? null
                      : () {
                          nameController.text = widget.user.displayName;
                          photoUrlController.text = widget.user.photoUrl ?? '';
                          setState(() => isEditing = false);
                        },
                  child: const Text('СКАСУВАТИ'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, size: 17),
                label: const Text('ВИЙТИ'),
              ),
              if (!widget.user.hasGoogleProvider)
                OutlinedButton.icon(
                  onPressed: isLinkingGoogle ? null : _linkGoogle,
                  icon: const Icon(Icons.link, size: 17),
                  label: Text(
                    isLinkingGoogle ? 'ПІД’ЄДНАННЯ…' : 'ПІД’ЄДНАТИ GOOGLE',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return _UserAvatar(photoUrl: widget.user.photoUrl, radius: 44);
  }

  Widget _buildPhotoPreview(String photoUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: lightOlive,
                  child: Icon(Icons.broken_image_outlined, color: olive),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Попередній перегляд фото'),
        ],
      ),
    );
  }

  Widget _profileField(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: olive,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: isEditing ? Colors.white : pageColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: olive),
        ),
      ),
    );
  }

  Widget _buildPasswordPanel() {
    return _profilePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: olive),
              SizedBox(width: 10),
              Text(
                'ЗМІНА ПАРОЛЯ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!widget.user.hasPasswordProvider)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Встановіть пароль, щоб надалі входити в цей акаунт через Google або електронну пошту й пароль.',
              ),
            ),
          Form(
            key: passwordFormKey,
            child: Column(
              children: [
                if (widget.user.hasPasswordProvider) ...[
                  _passwordField(
                    'ПОТОЧНИЙ ПАРОЛЬ',
                    controller: currentPasswordController,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Введіть поточний пароль.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                _passwordField(
                  'НОВИЙ ПАРОЛЬ',
                  controller: newPasswordController,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                _passwordField(
                  'ПІДТВЕРДІТЬ ПАРОЛЬ',
                  controller: confirmPasswordController,
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Паролі не збігаються.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: isChangingPassword ? null : _savePassword,
            icon: const Icon(Icons.key, size: 17),
            label: Text(
              isChangingPassword
                  ? 'ЗБЕРЕЖЕННЯ…'
                  : widget.user.hasPasswordProvider
                  ? 'ЗМІНИТИ ПАРОЛЬ'
                  : 'ВСТАНОВИТИ ПАРОЛЬ',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: olive,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(
    String label, {
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: olive,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        hintText: '••••••••',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: olive),
        ),
      ),
    );
  }

  Widget _buildAccountStats(bool isWide) {
    final stats = [
      _statCard('СТАТУС АКАУНТА', 'АКТИВНИЙ', Icons.circle),
      _statCard('ОСТАННІЙ ВХІД', 'СЬОГОДНІ', Icons.schedule),
      _statCard('ПРОДУКТІВ У КОМОРІ', '0 ПОЗИЦІЙ', Icons.inventory_2_outlined),
    ];
    if (isWide) {
      return Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0) const SizedBox(width: 16),
            Expanded(child: stats[index]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          stats[index],
        ],
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return _profilePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: olive,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 14, color: olive),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profilePanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: olive.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(color: Color(0x333F472A), offset: Offset(3, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.photoUrl, this.radius = 20});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final url = photoUrl?.trim();
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _fallback(size)
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(size),
              ),
      ),
    );
  }

  Widget _fallback(double size) {
    return ColoredBox(
      color: lightOlive,
      child: Center(
        child: Icon(Icons.person, color: olive, size: size * 0.52),
      ),
    );
  }
}
