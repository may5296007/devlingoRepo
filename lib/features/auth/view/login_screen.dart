import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_view_model.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onLogin(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    await viewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (viewModel.status == AuthStatus.success) {
      // Redirection vers Home
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else if (viewModel.status == AuthStatus.error &&
        viewModel.errorMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(
         authService: context.read<AuthService>(),
      ),
      child: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          final isLoading = viewModel.status == AuthStatus.loading;

          return Scaffold(
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // TODO: garder ton logo / titre / animations ici
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entre ton email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'Mot de passe'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entre ton mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : () => _onLogin(viewModel),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Connexion'),
                          ),
                        ),
                        // TODO: ton bouton Google etc. ici si tu veux
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
