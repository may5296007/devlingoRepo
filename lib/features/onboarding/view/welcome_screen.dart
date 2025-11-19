import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8F0FE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Spacer(flex: 2),

                // Logo DevLingo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    '</DevLingo>',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                SizedBox(height: 60),

                // Illustration
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cercle de fond
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF2F80ED).withOpacity(0.1),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          // Code snippets flottants
                          Positioned(
                            top: 20,
                            left: 20,
                            child: _buildCodeChip('{ }', Color(0xFFFF6B6B)),
                          ),
                          Positioned(
                            top: 40,
                            right: 30,
                            child: _buildCodeChip('</>', Color(0xFF4ECDC4)),
                          ),
                          Positioned(
                            bottom: 60,
                            left: 40,
                            child: _buildCodeChip('fn()', Color(0xFFFFE66D)),
                          ),
                          Positioned(
                            bottom: 40,
                            right: 20,
                            child: _buildCodeChip('<div>', Color(0xFF95E1D3)),
                          ),
                          // Icône centrale
                          Icon(
                            Icons.code,
                            size: 120,
                            color: Color(0xFF2F80ED).withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Titre
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Apprends à coder\navec DevLingo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Sous-titre
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Python • JavaScript • React • Java\net bien plus encore !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ),

                Spacer(flex: 3),

                // Bouton Créer un compte
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildPrimaryButton(
                      context,
                      'Créer un compte',
                          () {
                        Navigator.pushNamed(context, '/signup');
                      },
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Bouton J'ai déjà un compte
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'J\'ai déjà un compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F80ED),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeChip(String text, Color color) {
    return TweenAnimationBuilder(
      duration: Duration(seconds: 2),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value * 0.9,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2F80ED).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2F80ED),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}