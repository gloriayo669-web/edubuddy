import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EduBuddyApp());
}

const Color purple = Color(0xFF5946B2);
const Color navy = Color(0xFF172554);
const Color pageBackground = Color(0xFFF5F2FF);

class EduBuddyApp extends StatelessWidget {
  const EduBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
        scaffoldBackgroundColor: pageBackground,
        iconTheme: const IconThemeData(size: 27),
        primaryIconTheme: const IconThemeData(size: 27),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E1F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: purple, width: 1.5),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class StudentData {
  static String name = '';
  static String email = '';
  static String phone = '';
  static String course = '';
  static String level = '';
  static String studyTime = '';
  static String goals = '';
  static List<String> learningMethods = [];
  static int completedSessions = 0;
  static int totalStudyMinutes = 0;
}

/// Local account storage for the prototype. Accounts are stored on this device.
class AccountStorage {
  static const String _accountsKey = 'edubuddy_accounts_v1';

  static Future<Map<String, dynamic>> _readAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<bool> emailExists(String email) async {
    final accounts = await _readAccounts();
    return accounts.containsKey(email.trim().toLowerCase());
  }

  static Future<bool> createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final accounts = await _readAccounts();
    final key = email.trim().toLowerCase();
    if (accounts.containsKey(key)) return false;
    accounts[key] = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'course': '',
      'level': '',
      'studyTime': '',
      'learningMethods': <String>[],
      'goals': '',
      'completedSessions': 0,
      'totalStudyMinutes': 0,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
    return true;
  }

  static Future<bool> signIn(String email, String password) async {
    final accounts = await _readAccounts();
    final account = accounts[email.trim().toLowerCase()];
    if (account == null || account['password'] != password) return false;
    _loadStudent(account);
    return true;
  }

  static Future<bool> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    final accounts = await _readAccounts();
    final key = email.trim().toLowerCase();
    final account = accounts[key];
    if (account == null) return false;

    final savedPhone = (account['phone'] ?? '').toString().trim();
    if (savedPhone != phone.trim()) return false;

    account['password'] = newPassword;
    accounts[key] = account;

    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  static void _loadStudent(Map<dynamic, dynamic> account) {
    StudentData.name = (account['name'] ?? '').toString();
    StudentData.email = (account['email'] ?? '').toString();
    StudentData.phone = (account['phone'] ?? '').toString();
    StudentData.course = (account['course'] ?? '').toString();
    StudentData.level = (account['level'] ?? '').toString();
    StudentData.studyTime = (account['studyTime'] ?? '').toString();
    StudentData.learningMethods =
        List<String>.from(account['learningMethods'] ?? <String>[]);
    StudentData.goals = (account['goals'] ?? '').toString();
    StudentData.completedSessions = (account['completedSessions'] ?? 0) as int;
    StudentData.totalStudyMinutes = (account['totalStudyMinutes'] ?? 0) as int;
  }

  static Future<void> saveStudent() async {
    if (StudentData.email.trim().isEmpty) return;
    final accounts = await _readAccounts();
    final key = StudentData.email.trim().toLowerCase();
    final existing = accounts[key];
    if (existing == null) return;
    final account = Map<String, dynamic>.from(existing as Map);
    account.addAll({
      'name': StudentData.name,
      'email': StudentData.email,
      'phone': StudentData.phone,
      'course': StudentData.course,
      'level': StudentData.level,
      'studyTime': StudentData.studyTime,
      'learningMethods': StudentData.learningMethods,
      'goals': StudentData.goals,
      'completedSessions': StudentData.completedSessions,
      'totalStudyMinutes': StudentData.totalStudyMinutes,
    });
    accounts[key] = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }
}

Widget pageFrame({required Widget child}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, pageBackground],
      ),
    ),
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    ),
  );
}

// Full brand logo on the welcome page; compact app icon elsewhere.
Widget appLogo({double size = 74}) {
  return Container(
    color: Colors.transparent,
    child: Image.asset(
      'images/edubuddy_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}

Widget fullLogo({double height = 210}) {
  return Image.asset(
    'images/edubuddy_logo.png',
    height: height,
    fit: BoxFit.contain,
  );
}

Widget primaryButton({
  required String text,
  required VoidCallback onPressed,
  IconData? icon,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: 25),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
    ),
  );
}

Widget sectionTitle(String title, {String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          )),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      ],
    ],
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pageFrame(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 25, 26, 25),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  fullLogo(height: 210),
                  const SizedBox(height: 25),
                  const Text(
                    'Learn Better. Grow Smarter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 29,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Build better study habits, stay motivated, and make steady progress towards your academic goals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 38),
                  primaryButton(
                    text: 'Get Started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistrationScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: purple,
                        side: const BorderSide(color: purple),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Log In'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'YOUR PERSONAL LEARNING COMPANION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
          style: const TextStyle(
              color: navy, fontWeight: FontWeight.w600, fontSize: 14)),
    );

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> continueRegistration() async {
    if (!formKey.currentState!.validate()) return;
    final email = emailController.text.trim();
    final created = await AccountStorage.createAccount(
      name: nameController.text,
      email: email,
      phone: phoneController.text,
      password: passwordController.text,
    );
    if (!mounted) return;
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An account with this email already exists. Please log in.')),
      );
      return;
    }
    StudentData.name = nameController.text.trim();
    StudentData.email = email;
    StudentData.phone = phoneController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: pageFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appLogo(size: 66),
                const SizedBox(height: 22),
                const Text('Create your account',
                    style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: navy)),
                const SizedBox(height: 8),
                Text('Tell us a little about yourself to get started.',
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 25),
                _label('Full name'),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline, size: 26)),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 15),
                _label('Email address'),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'example@email.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 26)),
                  validator: (v) {
                    if (v == null || !v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _label('Phone number'),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 26)),
                  validator: (v) => v == null || v.trim().length < 7
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 15),
                _label('Password'),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 26),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Use at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 15),
                _label('Confirm password'),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Enter your password again',
                    prefixIcon: const Icon(Icons.lock_outline, size: 26),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                  validator: (v) => v != passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 25),
                primaryButton(
                    text: 'Continue',
                    onPressed: continueRegistration,
                    icon: Icons.arrow_forward),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Already have an account? Log in',
                        style: TextStyle(color: purple)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    final success = await AccountStorage.signIn(
      emailController.text.trim(),
      passwordController.text,
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account not found or password is incorrect. Please check your details or sign up.')),
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: pageFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appLogo(size: 75),
                const SizedBox(height: 25),
                const Text('Welcome back',
                    style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: navy)),
                const SizedBox(height: 8),
                Text('Log in and continue working towards your goals.',
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 30),
                _label('Email address'),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined, size: 26)),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter your email' : null,
                ),
                const SizedBox(height: 18),
                _label('Password'),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 26),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Enter your password'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: purple)),
                  ),
                ),
                const SizedBox(height: 12),
                primaryButton(text: 'Log In', onPressed: login),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistrationScreen()),
                    ),
                    child: const Text("Don't have an account? Sign up",
                        style: TextStyle(color: purple)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isSaving = false;

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> updatePassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    final changed = await AccountStorage.resetPassword(
      email: emailController.text,
      phone: phoneController.text,
      newPassword: passwordController.text,
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not verify those details. Check that the email and phone number match your registered account.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated. You can now log in with your new password.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reset password'),
      ),
      body: pageFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appLogo(size: 75),
                const SizedBox(height: 24),
                const Text(
                  'Forgot your password?',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the email address and phone number you used when creating your account, then choose a new password.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 26),
                _label('Email address'),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your registered email',
                    prefixIcon: Icon(Icons.email_outlined, size: 26),
                  ),
                  validator: (value) =>
                      value == null || !value.contains('@')
                          ? 'Enter a valid email address'
                          : null,
                ),
                const SizedBox(height: 16),
                _label('Registered phone number'),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter your registered phone number',
                    prefixIcon: Icon(Icons.phone_outlined, size: 26),
                  ),
                  validator: (value) =>
                      value == null || value.trim().length < 7
                          ? 'Enter your registered phone number'
                          : null,
                ),
                const SizedBox(height: 16),
                _label('New password'),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a new password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 26),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => obscurePassword = !obscurePassword,
                      ),
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 6
                      ? 'Use at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                _label('Confirm new password'),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Enter the new password again',
                    prefixIcon: const Icon(Icons.lock_outline, size: 26),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => obscureConfirm = !obscureConfirm,
                      ),
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) => value != passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 26),
                primaryButton(
                  text: isSaving ? 'Updating...' : 'Reset password',
                  onPressed: isSaving ? () {} : updatePassword,
                  icon: Icons.lock_reset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final courseController = TextEditingController();
  final goalsController = TextEditingController();
  int currentStep = 0;
  String? selectedLevel;
  String? selectedTime;
  final Set<String> selectedMethods = {};

  final levels = [
    'ND 1', 'ND 2', 'HND 1', 'HND 2', '100 Level',
    '200 Level', '300 Level', '400 Level', '500 Level', 'Other'
  ];
  final times = [
    'Early Morning', 'Morning', 'Afternoon', 'Evening', 'Late Night'
  ];
  final methods = [
    'Reading', 'Watching Videos', 'Listening to Audio',
    'Practical Exercises', 'Group Study', 'Taking Notes'
  ];

  @override
  void dispose() {
    courseController.dispose();
    goalsController.dispose();
    super.dispose();
  }

  bool validateStep() {
    if (currentStep == 0 && courseController.text.trim().isEmpty) {
      _message('Please enter your course of study.');
      return false;
    }
    if (currentStep == 1 && selectedLevel == null) {
      _message('Please select your academic level.');
      return false;
    }
    if (currentStep == 2 && selectedTime == null) {
      _message('Please select your preferred study time.');
      return false;
    }
    if (currentStep == 3 && selectedMethods.isEmpty) {
      _message('Please select at least one learning method.');
      return false;
    }
    if (currentStep == 4 && goalsController.text.trim().isEmpty) {
      _message('Please tell us about your academic goal.');
      return false;
    }
    return true;
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void next() {
    if (!validateStep()) return;
    if (currentStep < 4) {
      setState(() => currentStep++);
    } else {
      StudentData.course = courseController.text.trim();
      StudentData.level = selectedLevel!;
      StudentData.studyTime = selectedTime!;
      StudentData.learningMethods = selectedMethods.toList();
      StudentData.goals = goalsController.text.trim();
      AccountStorage.saveStudent();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Widget choiceTile(String value, bool selected, VoidCallback onTap) {
    return Card(
      color: selected ? purple.withOpacity(0.10) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: selected ? purple : const Color(0xFFE5E1F2)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(value,
            style: TextStyle(
                color: navy,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color: selected ? purple : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'What course are you studying?',
      'What is your academic level?',
      'When do you prefer to study?',
      'How do you learn best?',
      'What is your academic goal?'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalise your experience',
            style: TextStyle(color: navy, fontSize: 17)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: pageFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question ${currentStep + 1} of 5',
                      style: const TextStyle(
                          color: purple, fontWeight: FontWeight.w600)),
                  Text('${((currentStep + 1) / 5 * 100).round()}%',
                      style: const TextStyle(color: navy)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / 5,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: purple,
                ),
              ),
              const SizedBox(height: 32),
              Text(titles[currentStep],
                  style: const TextStyle(
                      fontSize: 24,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: navy)),
              const SizedBox(height: 10),
              Text(
                'Your answers help EduBuddy suggest a study routine that suits you.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 25),
              if (currentStep == 0)
                TextField(
                  controller: courseController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Computer Science',
                    prefixIcon: Icon(Icons.school_outlined, size: 26),
                  ),
                ),
              if (currentStep == 1)
                ...levels.map((level) => choiceTile(
                      level,
                      selectedLevel == level,
                      () => setState(() => selectedLevel = level),
                    )),
              if (currentStep == 2)
                ...times.map((time) => choiceTile(
                      time,
                      selectedTime == time,
                      () => setState(() => selectedTime = time),
                    )),
              if (currentStep == 3)
                ...methods.map((method) => choiceTile(
                      method,
                      selectedMethods.contains(method),
                      () => setState(() {
                        if (!selectedMethods.add(method)) {
                          selectedMethods.remove(method);
                        }
                      }),
                    )),
              if (currentStep == 4)
                TextField(
                  controller: goalsController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Improve my grades and study consistently.',
                    alignLabelWithHint: true,
                  ),
                ),
              const SizedBox(height: 30),
              primaryButton(
                text: currentStep == 4 ? 'Finish' : 'Continue',
                onPressed: next,
                icon: currentStep == 4
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
              ),
              if (currentStep > 0) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => setState(() => currentStep--),
                    child: const Text('Previous',
                        style: TextStyle(color: purple)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedTab = 0;

  final pages = const [
    HomeTab(),
    StudiesTab(),
    ProgressTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pageFrame(
        child: IndexedStack(index: selectedTab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        indicatorColor: purple.withOpacity(0.13),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 28),
              selectedIcon: Icon(Icons.home, color: purple, size: 28),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, size: 28),
              selectedIcon: Icon(Icons.menu_book, color: purple, size: 28),
              label: 'My Studies'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, size: 28),
              selectedIcon: Icon(Icons.bar_chart, color: purple, size: 28),
              label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.person_outline, size: 28),
              selectedIcon: Icon(Icons.person, color: purple, size: 28),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = StudentData.name.trim().isEmpty
        ? 'Student'
        : StudentData.name.trim().split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $firstName 👋',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: navy)),
                    const SizedBox(height: 5),
                    Text('Ready to make progress today?',
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              appLogo(size: 52),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A little motivation',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 10),
                Text(
                  '“Success is the sum of small efforts, repeated day in and day out.”',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.4,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Text('Keep showing up for yourself.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          sectionTitle('Your study snapshot'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.check_circle_outline,
                  value: '${StudentData.completedSessions}',
                  label: 'Sessions done',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.timer_outlined,
                  value: '${StudentData.totalStudyMinutes} min',
                  label: 'Study time',
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          sectionTitle('Your study profile'),
          const SizedBox(height: 12),
          _infoCard(
            Icons.school_outlined,
            'Course',
            StudentData.course.isEmpty ? 'Not added yet' : StudentData.course,
          ),
          _infoCard(
            Icons.schedule,
            'Preferred time',
            StudentData.studyTime.isEmpty
                ? 'Not selected yet'
                : StudentData.studyTime,
          ),
          const SizedBox(height: 25),
          sectionTitle('Quick actions'),
          const SizedBox(height: 12),
          _actionCard(
            context,
            icon: Icons.play_circle_outline,
            title: 'Start a study session',
            subtitle: 'Focus on one task at a time',
            destination: const StudyTimerScreen(),
          ),
          _actionCard(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'View study timetable',
            subtitle: 'Plan when you will study',
            destination: const TimetableScreen(),
          ),
        ],
      ),
    );
  }
}

Widget _statCard(
    {required IconData icon, required String value, required String label}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFEAE6F5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: purple, size: 29),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: navy)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    ),
  );
}

Widget _infoCard(IconData icon, String title, String value) {
  return Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: purple, size: 29),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      color: navy, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _actionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget destination,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(icon, color: purple, size: 29),
      ),
      title: Text(title,
          style: const TextStyle(
              color: navy, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: purple, size: 27),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
    ),
  );
}

class StudiesTab extends StatelessWidget {
  const StudiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('My Studies',
              subtitle: 'Keep your learning organised.'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: purple, size: 30),
                const SizedBox(height: 12),
                Text(
                  StudentData.course.isEmpty
                      ? 'Your course'
                      : StudentData.course,
                  style: const TextStyle(
                      color: navy, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 5),
                Text(
                  StudentData.level.isEmpty
                      ? 'Academic level not set'
                      : StudentData.level,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _actionCard(
            context,
            icon: Icons.timer_outlined,
            title: 'Start study session',
            subtitle: 'Use the focus timer',
            destination: const StudyTimerScreen(),
          ),
          _actionCard(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Study timetable',
            subtitle: 'Edit your weekly plan',
            destination: const TimetableScreen(),
          ),
          const SizedBox(height: 18),
          sectionTitle('How you prefer to learn'),
          const SizedBox(height: 10),
          if (StudentData.learningMethods.isEmpty)
            const Text('Your learning preferences will appear here.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StudentData.learningMethods
                  .map((m) => Chip(
                        label: Text(m),
                        backgroundColor: Colors.transparent,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// Timetable values are stored locally on the device using shared_preferences.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> days = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];

  final Map<String, String> defaultActivities = {
    'Monday': 'Review lecture notes',
    'Tuesday': 'Practise course exercises',
    'Wednesday': 'Watch a learning video',
    'Thursday': 'Read and summarise a topic',
    'Friday': 'Revise difficult topics',
    'Saturday': 'Self-test and practise',
    'Sunday': 'Rest or plan the coming week',
  };

  Map<String, String> activities = {};
  Map<String, String> times = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final savedActivities = prefs.getString('edubuddy_timetable_activities');
    final savedTimes = prefs.getString('edubuddy_timetable_times');

    if (!mounted) return;
    setState(() {
      activities = savedActivities == null
          ? Map<String, String>.from(defaultActivities)
          : Map<String, String>.from(jsonDecode(savedActivities));
      times = savedTimes == null
          ? {for (final day in days) day: '4:00 PM'}
          : Map<String, String>.from(jsonDecode(savedTimes));
      isLoading = false;
    });
  }

  Future<void> _saveTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'edubuddy_timetable_activities', jsonEncode(activities));
    await prefs.setString('edubuddy_timetable_times', jsonEncode(times));
  }

  Future<void> _editDay(String day) async {
    final activityController =
        TextEditingController(text: activities[day] ?? '');
    String selectedTime = times[day] ?? '4:00 PM';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit $day'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Study activity',
                    style: TextStyle(
                        color: navy, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: activityController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What will you study?',
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Study time',
                    style: TextStyle(
                        color: navy, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: const [
                    '6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM',
                    '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM',
                    '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM',
                    '6:00 PM', '7:00 PM', '8:00 PM', '9:00 PM',
                    '10:00 PM'
                  ].map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedTime = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (activityController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: purple, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        activities[day] = activityController.text.trim();
        times[day] = selectedTime;
      });
      await _saveTimetable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$day timetable updated.')),
        );
      }
    }
    activityController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study timetable')),
      body: pageFrame(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: purple))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Your weekly study plan',
                      style: TextStyle(
                          color: navy,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Tap any day to change its activity and study time. Your changes are saved on this device.',
                    style: TextStyle(
                        color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  ...days.map((day) => Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          onTap: () => _editDay(day),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: const Icon(Icons.event_note, color: purple),
                          ),
                          title: Text(day,
                              style: const TextStyle(
                                  color: navy, fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${activities[day] ?? ''}\n${times[day] ?? ''}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.edit_outlined,
                              color: purple),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  static const int sessionLength = 25 * 60;
  int secondsLeft = sessionLength;
  Timer? timer;
  bool isRunning = false;
  bool sessionSaved = false;

  void startPause() {
    if (isRunning) {
      timer?.cancel();
      setState(() => isRunning = false);
      return;
    }

    if (secondsLeft == 0) return;

    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (secondsLeft > 1) {
        setState(() => secondsLeft--);
      } else {
        t.cancel();
        setState(() {
          secondsLeft = 0;
          isRunning = false;
        });
        saveSession();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great work! Your study session is complete.'),
          ),
        );
      }
    });
  }

  void saveSession() {
    if (sessionSaved) return;
    StudentData.completedSessions++;
    StudentData.totalStudyMinutes += 25;
    sessionSaved = true;
    AccountStorage.saveStudent();
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      secondsLeft = sessionLength;
      isRunning = false;
      sessionSaved = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Study session')),
      body: pageFrame(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  appLogo(size: 68),
                  const SizedBox(height: 18),
                  const Text('Focus time',
                      style: TextStyle(
                          color: navy,
                          fontSize: 25,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Study for 25 minutes without distractions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: 205,
                    height: 205,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: purple, width: 8),
                    ),
                    child: Center(
                      child: Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 43,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 27),
                  primaryButton(
                    text: isRunning
                        ? 'Pause'
                        : secondsLeft == 0
                            ? 'Session completed'
                            : 'Start studying',
                    onPressed: secondsLeft == 0 ? () {} : startPause,
                    icon: isRunning ? Icons.pause : Icons.play_arrow,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: resetTimer,
                      icon: const Icon(Icons.refresh, size: 26),
                      label: const Text('Reset timer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: purple,
                        side: const BorderSide(color: purple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  if (sessionSaved) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Session added to your progress.',
                      style: TextStyle(
                          color: purple, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('My Progress',
              subtitle: 'Every completed session is a step forward.'),
          const SizedBox(height: 22),
          _statCard(
            icon: Icons.check_circle_outline,
            value: '${StudentData.completedSessions}',
            label: 'Completed sessions',
          ),
          const SizedBox(height: 12),
          _statCard(
            icon: Icons.timer_outlined,
            value: '${StudentData.totalStudyMinutes} minutes',
            label: 'Total focused study time',
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keep your momentum',
                    style: TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  StudentData.completedSessions == 0
                      ? 'You have not completed a timed session yet. Start with one 25-minute session today.'
                      : 'You have completed ${StudentData.completedSessions} study session(s). Keep building your habit!',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('My Profile',
              subtitle: 'Your personal study information.'),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 43,
                  backgroundColor: Colors.transparent,
                  child: const Icon(Icons.person, size: 48, color: purple),
                ),
                const SizedBox(height: 12),
                Text(
                  StudentData.name.isEmpty ? 'Student' : StudentData.name,
                  style: const TextStyle(
                      color: navy, fontSize: 21, fontWeight: FontWeight.bold),
                ),
                Text(StudentData.email,
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _infoCard(
            Icons.school_outlined,
            'Course',
            StudentData.course.isEmpty ? 'Not set' : StudentData.course,
          ),
          _infoCard(
            Icons.stairs_outlined,
            'Academic level',
            StudentData.level.isEmpty ? 'Not set' : StudentData.level,
          ),
          _infoCard(
            Icons.schedule,
            'Preferred study time',
            StudentData.studyTime.isEmpty
                ? 'Not set'
                : StudentData.studyTime,
          ),
          _infoCard(
            Icons.flag_outlined,
            'Academic goal',
            StudentData.goals.isEmpty ? 'Not set' : StudentData.goals,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('You will return to the welcome page.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: purple,
                side: const BorderSide(color: purple),
                padding: const EdgeInsets.all(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
