import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:story_project/presentation/providers/auth_provider.dart';
import 'package:story_project/presentation/widgets/custom_text_field.dart';
import 'package:story_project/presentation/widgets/loading_indicator.dart';
import 'package:story_project/presentation/providers/locale_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _confirmPasswordVisible = !_confirmPasswordVisible;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.nameRequired;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppLocalizations.of(context)!.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.passwordRequired;
    }
    if (value.length < 8) {
      return AppLocalizations.of(context)!.passwordLength;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.passwordRequired;
    }
    if (value != _passwordController.text) {
      return AppLocalizations.of(context)!.passwordNotMatch;
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      await context.read<AuthProvider>().register(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
      
      if (mounted && context.read<AuthProvider>().state != AuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.registerSuccess),
            backgroundColor: Colors.green,
          ),
        );
        context.goNamed('login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.register),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.language),
            tooltip: 'Language',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: const Text('English'),
              ),
              PopupMenuItem(
                value: 'id',
                child: const Text('Bahasa Indonesia'),
              ),
            ],
            onSelected: (value) {
              final locale = Locale(value);
              context.read<LocaleProvider>().setLocale(locale);
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.state == AuthState.loading) {
            return const LoadingIndicator();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.app_registration,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.register,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (authProvider.state == AuthState.error && authProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        l10n.registerError(authProvider.errorMessage!),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  CustomTextField(
                    controller: _nameController,
                    labelText: l10n.name,
                    validator: _validateName,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    labelText: l10n.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: l10n.password,
                    obscureText: !_passwordVisible,
                    validator: _validatePassword,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: l10n.confirmPassword,
                    obscureText: !_confirmPasswordVisible,
                    validator: _validateConfirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.register),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.goNamed('login'),
                    child: Text(l10n.alreadyHaveAccount),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 