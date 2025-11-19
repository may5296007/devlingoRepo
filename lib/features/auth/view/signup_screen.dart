import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_view_model.dart';
import '../../../core/services/auth_service.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedLevel = 'débutant';
  DateTime? _birthDate;

  // garde ton animation controller si tu veux
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
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis ta date de naissance')),
      );
      return;
    }

    await viewModel.signUp(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      level: _selectedLevel,
      birthDate: _birthDate!,
    );

    if (viewModel.status == AuthStatus.success) {
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
                        // TODO: ton header, titre, etc.
                        TextFormField(
                          controller: _prenomController,
                          decoration:
                              const InputDecoration(labelText: 'Prénom'),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Obligatoire'
                                  : null,
                        ),
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Obligatoire'
                                  : null,
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration:
                              const InputDecoration(labelText: 'Email'),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Obligatoire'
                                  : null,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Mot de passe'),
                          validator: (value) => (value == null ||
                                  value.length < 6)
                              ? 'Minimum 6 caractères'
                              : null,
                        ),
                        // TODO: ton sélecteur de niveau + date picker
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : () => _onSignUp(viewModel),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Créer mon compte"),
                          ),
                        ),
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
