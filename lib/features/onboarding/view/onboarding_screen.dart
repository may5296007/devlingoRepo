import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../screens/onboarding/models/wizard_model.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> with TickerProviderStateMixin {
  List<Wizard> wizardData = WizardData.getWizard();

  PageController pageController = PageController(initialPage: 0);
  int page = 0;
  bool isLast = false;

  late AnimationController _buttonController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation pour le bouton
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Animation pour le fade in
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    pageController.dispose();
    _buttonController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8F0FE),
              Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Skip button avec animation
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: !isLast ?
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton(
                      onPressed: () {
                        pageController.animateToPage(
                          wizardData.length - 1,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Passer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                      : SizedBox(height: 48),
                ),
              ),

              // PageView avec contenu
              Expanded(
                child: PageView.builder(
                  onPageChanged: onPageViewChange,
                  controller: pageController,
                  itemCount: wizardData.length,
                  itemBuilder: (context, index) {
                    return buildPageItem(wizardData[index], index);
                  },
                ),
              ),

              // Dots indicator avec animation
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 60,
                child: buildDots(context),
              ),

              SizedBox(height: 20),

              // Bouton animé
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: double.infinity,
                        height: 60,
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
                          onPressed: () async {
                            _buttonController.forward();
                            await Future.delayed(Duration(milliseconds: 150));
                            _buttonController.reverse();

                            if (isLast) {
                              // Navigation vers Login
                              Navigator.pushReplacementNamed(context, '/login');
                            } else {
                              pageController.nextPage(
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2F80ED),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? 'Commencer' : 'Suivant',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                isLast ? Icons.rocket_launch : Icons.arrow_forward,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPageItem(Wizard wz, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Animation Lottie avec Hero animation
            Hero(
              tag: 'lottie_$index',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2F80ED).withOpacity(0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  wz.image,
                  height: 280,
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            SizedBox(height: 50),

            // Titre avec animation
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Text(
                      wz.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F80ED),
                        height: 1.3,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            // Description avec animation
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Text(
                      wz.brief,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey[700],
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDots(BuildContext context) {
    List<Widget> dots = [];
    for (int i = 0; i < wizardData.length; i++) {
      dots.add(
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 6),
          height: page == i ? 12 : 8,
          width: page == i ? 32 : 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: page == i ? Color(0xFF2F80ED) : Colors.grey[300],
            boxShadow: page == i ? [
              BoxShadow(
                color: Color(0xFF2F80ED).withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : [],
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: dots,
    );
  }

  void onPageViewChange(int _page) {
    setState(() {
      page = _page;
      isLast = _page == wizardData.length - 1;
    });

    // Redémarrer l'animation de fade
    _fadeController.reset();
    _fadeController.forward();
  }
}