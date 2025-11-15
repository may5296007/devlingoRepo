class Wizard {
  final String image;
  final String title;
  final String brief;

  Wizard({
    required this.image,
    required this.title,
    required this.brief,
  });
}

class WizardData {
  static List<Wizard> getWizard() {
    return [
      Wizard(
        image: "assets/lottie/welcome.json",  // ← Vérifier ce chemin
        title: "Bienvenue sur DevLingo",
        brief: "Apprends à coder de manière interactive et amusante",
      ),
      Wizard(
        image: "assets/lottie/rocket.json",
        title: "Lance ta carrière tech",
        brief: "Des cours adaptés à ton niveau, de débutant à avancé",
      ),
      Wizard(
        image: "assets/lottie/third.json",
        title: "Progresse à ton rythme",
        brief: "Gagne des points, des badges et monte de niveau",
      ),
    ];
  }
}