import 'package:flutter/material.dart';

import 'core/widgets/app_button.dart';
import 'core/widgets/app_text_field.dart';

const Color olive = Color(0xFF687044);
const Color lightOlive = Color(0xFFF0F1E9);
const Color pageColor = Color(0xFFF7F7F4);

void main() {
  runApp(const PantryApp());
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const LoginScreen(),
    );
  }
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
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Вхід через Google поки не налаштовано'),
            ),
          );
        },
        icon: const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
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

// 1. Екран авторизації.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Вхід',
        subtitle: 'Увійдіть, щоб продовжити роботу',
        children: [
          const AppTextField(
            label: 'Електронна пошта',
            hint: 'name@example.com',
          ),
          const Text('Пароль', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          TextField(
            obscureText: !showPassword,
            decoration: InputDecoration(
              hintText: 'Введіть пароль',
              filled: true,
              fillColor: const Color(0xFFF8F8F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text(
                'Забули пароль?',
                style: TextStyle(color: olive),
              ),
            ),
          ),
          AppButton(
            text: 'Увійти',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          const _AuthDivider(),
          const SizedBox(height: 14),
          const _GoogleSignInButton(),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
                'Немає акаунта? Зареєструватися',
                style: TextStyle(color: olive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Реєстрація.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Реєстрація',
        subtitle: 'Створіть акаунт для домашньої комори',
        children: [
          const AppTextField(label: 'Ім’я', hint: 'Ваше ім’я'),
          const AppTextField(
            label: 'Електронна пошта',
            hint: 'name@example.com',
          ),
          const AppTextField(
            label: 'Пароль',
            hint: 'Введіть пароль',
            isPassword: true,
          ),
          AppButton(
            text: 'Зареєструватися',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          const _AuthDivider(),
          const SizedBox(height: 14),
          const _GoogleSignInButton(),
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

// 3. Відновлення пароля.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Відновлення пароля',
        subtitle: 'Введіть електронну пошту для відновлення доступу',
        children: [
          const AppTextField(
            label: 'Електронна пошта',
            hint: 'name@example.com',
          ),
          AppButton(
            text: 'Відновити пароль',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              );
            },
          ),
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

// 4. Встановлення нового пароля.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AuthCard(
        title: 'Новий пароль',
        subtitle: 'Створіть новий пароль для акаунта',
        children: [
          const AppTextField(
            label: 'Новий пароль',
            hint: 'Введіть новий пароль',
            isPassword: true,
          ),
          const AppTextField(
            label: 'Підтвердіть пароль',
            hint: 'Повторіть пароль',
            isPassword: true,
          ),
          AppButton(
            text: 'Зберегти новий пароль',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// 5. Головна сторінка та бічна навігація.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String userName = 'Олександр Половенко';
  bool isProfileSelected = false;

  final List<String> sections = [
    'Головна',
    'Комори',
    'Усі запаси',
    'Комора 1',
    'Комора 2',
    'Категорії',
    'Нагадування',
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                              selected: selectedIndex == index,
                              selectedTileColor: lightOlive,
                              leading: Icon(
                                [
                                  Icons.home_outlined,
                                  Icons.kitchen_outlined,
                                  Icons.inventory_2_outlined,
                                  Icons.storage_outlined,
                                  Icons.storage,
                                  Icons.category_outlined,
                                  Icons.notifications_none,
                                ][index],
                                color: selectedIndex == index
                                    ? olive
                                    : Colors.grey.shade700,
                                size: 20,
                              ),
                              title: Text(
                                sections[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedIndex == index
                                      ? olive
                                      : Colors.black87,
                                  fontWeight: selectedIndex == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                  isProfileSelected = false;
                                });
                              },
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
                      leading: const CircleAvatar(
                        backgroundColor: lightOlive,
                        child: Icon(Icons.person, color: olive),
                      ),
                      title: const Text(
                        'Мій профіль',
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Користувач',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        setState(() => isProfileSelected = true);
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
                        Expanded(
                          child: Text(
                            isProfileSelected
                                ? 'Профіль'
                                : sections[selectedIndex],
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => setState(() => isProfileSelected = true),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              const CircleAvatar(
                                backgroundColor: lightOlive,
                                child: Icon(Icons.person, color: olive),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isProfileSelected
                        ? const ProfileContent()
                        : selectedIndex == 0
                        ? const DashboardPlaceholder()
                        : EmptySection(title: sections[selectedIndex]),
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

// Головний екран поки без бізнес-логіки.
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, size: 70, color: olive),
          SizedBox(height: 16),
          Text(
            'Домашня комора',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Ваш простір для керування запасами',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class EmptySection extends StatelessWidget {
  final String title;

  const EmptySection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 60, color: olive),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Цей розділ поки порожній',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool isEditing = false;
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
                  _buildAccountPanel(isWide),
                  const SizedBox(height: 24),
                  _buildPasswordPanel(isWide),
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
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _profileField('ІМ’Я ТА ПРІЗВИЩЕ', 'Олександр Половенко'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _profileField(
                  'ЕЛЕКТРОННА ПОШТА',
                  'o.povalenko@example.com',
                ),
              ),
            ],
          )
        else ...[
          _profileField('ІМ’Я ТА ПРІЗВИЩЕ', 'Олександр Половенко'),
          const SizedBox(height: 12),
          _profileField('ЕЛЕКТРОННА ПОШТА', 'o.povalenko@example.com'),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() => isEditing = !isEditing);
                if (!isEditing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Профіль збережено')),
                  );
                }
              },
              icon: Icon(
                isEditing ? Icons.check : Icons.edit_outlined,
                size: 17,
              ),
              label: Text(isEditing ? 'ЗБЕРЕГТИ' : 'РЕДАГУВАТИ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: olive,
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, size: 17),
              label: const Text('ВИЙТИ'),
              style: OutlinedButton.styleFrom(foregroundColor: olive),
            ),
          ],
        ),
      ],
    );

    return _profilePanel(
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 22),
                Expanded(child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: _buildAvatar()),
                const SizedBox(height: 18),
                details,
              ],
            ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: lightOlive,
            border: Border.all(color: olive.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person, size: 46, color: olive),
        ),
        Positioned(
          right: -8,
          bottom: -8,
          child: IconButton.filled(
            tooltip: 'Змінити фото',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Завантаження фото поки недоступне'),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: olive,
              foregroundColor: Colors.white,
              fixedSize: const Size(32, 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: !isEditing,
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

  Widget _buildPasswordPanel(bool isWide) {
    final passwordFields = isWide
        ? Row(
            children: [
              Expanded(child: _passwordField('ПОТОЧНИЙ ПАРОЛЬ')),
              const SizedBox(width: 12),
              Expanded(child: _passwordField('НОВИЙ ПАРОЛЬ')),
              const SizedBox(width: 12),
              Expanded(child: _passwordField('ПІДТВЕРДІТЬ ПАРОЛЬ')),
            ],
          )
        : Column(
            children: [
              _passwordField('ПОТОЧНИЙ ПАРОЛЬ'),
              const SizedBox(height: 12),
              _passwordField('НОВИЙ ПАРОЛЬ'),
              const SizedBox(height: 12),
              _passwordField('ПІДТВЕРДІТЬ ПАРОЛЬ'),
            ],
          );

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
          const SizedBox(height: 24),
          passwordFields,
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Демонстрація: пароль не змінено'),
                    ),
                  );
                },
                icon: const Icon(Icons.key, size: 17),
                label: const Text('ЗМІНИТИ ПАРОЛЬ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: olive,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(foregroundColor: olive),
                child: const Text('СКАСУВАТИ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _passwordField(String label) {
    return TextFormField(
      obscureText: true,
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
