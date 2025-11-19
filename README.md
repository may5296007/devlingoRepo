
````markdown
# DevLingo – Architecture actuelle (refactor MVVM)


Ce document décrit **l’architecture actuelle** après le refactor en modules (`features/` + `core/`) et l’utilisation de Provider pour la gestion d’état.

---

## 1. Stack technique

- **Flutter / Dart**
- **Firebase**
  - `firebase_auth` pour l’authentification
  - `cloud_firestore` pour les données (users, langages, cours, progression)
- **Provider**
  - Gestion du thème (`ThemeProvider`)
  - Injection de `AuthService`
  - `StreamProvider<User?>` pour suivre l’état d’authentification
- **SharedPreferences**
  - Préférence de thème (dark / light)
  - Futur: état “onboarding déjà vu”

---

## 2. Organisation des dossiers

```text
lib/
├─ core/
│  ├─ models/          # (à remplir plus tard : modèles globaux)
│  ├─ routing/         # AuthWrapper, routes globales
│  ├─ services/        # Logique métier "générique"
│  │   ├─ auth_service.dart
│  │   ├─ cours_service.dart
│  │   └─ role_service.dart
│  ├─ theme/
│  │   └─ theme_provider.dart
│  └─ widgets/         # (à créer/peupler plus tard pour widgets réutilisables)
│
├─ features/
│  ├─ auth/
│  │   ├─ view/
│  │   │   ├─ login_screen.dart
│  │   │   └─ signup_screen.dart
│  │   └─ viewmodel/
│  │       └─ auth_view_model.dart (à structurer plus tard)
│  ├─ home/
│  │   └─ view/
│  │       └─ home_screen.dart
│  ├─ courses/
│  │   ├─ view/
│  │   │   ├─ cours_list_screen.dart
│  │   │   ├─ langage_cours_screen.dart
│  │   │   ├─ cours_swipe_screen.dart
│  │   │   └─ course_detail_screen.dart (legacy / à revoir)
│  │   └─ admin/
│  │       └─ view/
│  │           └─ course_editor_screen.dart (version simplifiée)
│  ├─ onboarding/
│  │   └─ view/
│  │       ├─ onboarding_screen.dart
│  │       └─ welcome_screen.dart
│  ├─ profile/
│  │   └─ view/
│  │       └─ profile_screen.dart
│  └─ settings/
│      └─ view/
│          └─ settings_screen.dart
│
├─ legacy/
│  ├─ auth_button.dart
│  ├─ card_model.dart
│  ├─ cours_card.dart
│  ├─ cours_model.dart
│  ├─ langage_model.dart
│  ├─ role_guard.dart
│  ├─ swipable_card.dart
│  └─ user_role.dart
│
├─ firebase_options.dart
└─ main.dart
````

* Tout ce qui est **nouvelle architecture** va dans `core/` et `features/`.
* Le dossier **`legacy/`** contient l’ancien code fonctionnel (modèles, widgets de carte, etc.) encore utilisé mais pas encore refactorisé en “clean MVVM”.

---

## 3. `main.dart` & Provider

`main.dart` fait 3 choses principales :

1. **Initialisation**

   * `Firebase.initializeApp(...)`
   * `SharedPreferences.getInstance()` (log de debug)
2. **Injection des services & du thème**

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    Provider<AuthService>(create: (_) => AuthService()),
    StreamProvider<User?>(
      create: (context) => context.read<AuthService>().authStateChanges,
      initialData: null,
    ),
  ],
  child: Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return MaterialApp(
        title: 'DevLingo',
        debugShowCheckedModeBanner: false,
        theme: themeProvider.lightTheme,
        darkTheme: themeProvider.darkTheme,
        themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const AuthWrapper(),
        routes: {
          '/onboarding': (context) => const OnBoardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/cours': (context) => CoursListScreen(),
          '/admin-cours': (context) => /* écran admin */,
          '/course-detail': (context) => const CourseDetailScreen(),
        },
      );
    },
  ),
);
```

3. **Choix de l’écran de départ** via `AuthWrapper`.

---

## 4. AuthWrapper & navigation d’entrée

`core/routing/auth_wrapper.dart` (ou équivalent) gère la logique d’entrée :

* Si `User` Firebase ≠ `null` → `HomeScreen`
* Sinon :

  * vérifie si l’onboarding a déjà été vu (plus tard via SharedPreferences)
  * `OnBoardingScreen` puis `WelcomeScreen` puis écrans d’auth

C’est la “porte d’entrée” de l’app.

---

## 5. Services (core/services)

### 5.1 `AuthService`

Responsable de **tout** ce qui touche à l’utilisateur :

* Firebase Auth :

  * `inscription(email, password, nom, prenom, niveau, birthday)`
  * `connexion(email, password)`
  * `connexionGoogle()` (avec `clientId` pour le Web)
  * `deconnexion()`
  * `resetPassword(email)`
* Firestore :

  * création du document `users/{uid}` avec :

    * `nom`, `prenom`, `email`
    * `niveau`
    * `role` (`user` par défaut)
    * `points`, `streak`, `badges`, etc.
  * `getProfilUtilisateur(uid)`
* Système de **streak / calendrier** :

  * `marquerJourComplete(uid)`
  * `estJourComplete(uid, date)`
  * `getJoursCompletsSemaine(uid)`
  * `updateStreakSiNecessaire(uid)`

Le `HomeScreen` consomme ce service pour afficher :

* le streak,
* les points,
* les badges,
* les jours complétés de la semaine.

---

### 5.2 `CoursService`

Responsable de **langages / cours / progression** :

* **Langages** (`collection('langages')`) :

  * `getAllLangages()` → `Stream<List<LangageModel>>`
  * `createLangage(nom, icon, description)`
* **Cours** (`collection('cours')`) :

  * `getCoursByLangage(langageId)` → `Stream<List<CoursModel>>`
  * `createCours(titre, langageId, cards, description?)`
  * `updateCours(coursId, {...})`
  * `deleteCours(coursId)`
* **Progression utilisateur** (dans `users/{uid}.coursProgress`) :

  * `saveProgress(coursId, cardIndex, totalCards)`
  * `getProgress(coursId)` → `{ progress: %, completed: bool }`

> **Note** : actuellement, les `cards` sont encore basés sur le `CardModel` du dossier `legacy/`.
> Le nouvel éditeur de cours enregistre pour l’instant des cours avec une **liste de cartes vide** (on complétera plus tard).

---

### 5.3 `RoleService`

Service qui gère les **rôles** et les permissions (admin / teacher / user) pour :

* Savoir si l’utilisateur peut créer/éditer/supprimer un cours
* Utilisé dans :

  * `CoursListScreen` (affichage du bouton Admin)
  * `CoursService` (vérification des droits côté création / édition / delete)

---

## 6. Thème (core/theme)

`ThemeProvider` gère :

* `isDarkMode` (bool)
* `lightTheme` / `darkTheme` (ThemeData custom type Duolingo)
* `toggleTheme()` avec sauvegarde dans `SharedPreferences`

Utilisation : `Consumer<ThemeProvider>` dans `main.dart` (et potentiellement dans `SettingsScreen` pour changer de thème).

---

## 7. Modules fonctionnels (features)

### 7.1 Auth (`features/auth`)

* `view/login_screen.dart`

  * Formulaire email/mot de passe
  * Bouton connexion → `AuthService.connexion`
  * Bouton Google → `AuthService.connexionGoogle` (quand configuré)
* `view/signup_screen.dart`

  * Formulaire inscription avec :

    * nom, prénom
    * email, mot de passe
    * niveau (débutant / intermédiaire / avancé)
    * date de naissance
  * Appel `AuthService.inscription` puis création Firestore
* `viewmodel/auth_view_model.dart`

  * Base pour sortir la logique des écrans (à structurer plus tard)

### 7.2 Home (`features/home/view/home_screen.dart`)

Dashboard principal, connecté à Firestore via `AuthService` :

* Récupère `userData` + `joursCompletsSemaine`
* Affiche :

  * header avec prénom, niveau, accès profil / settings / cours,
  * statistiques (streak, XP, niveau),
  * mini-calendrier de la semaine,
  * objectif du jour,
  * liste des langages/cours depuis Firestore,
  * badges.
* Interaction :

  * Bouton “Aujourd’hui complété” → `AuthService.marquerJourComplete()`
  * Bouton “Cours” → navigation vers `/cours`.

### 7.3 Cours (`features/courses`)

#### 7.3.1 `CoursListScreen`

* Utilise `CoursService.getAllLangages()`
* Affiche un **Grid** de langages (`LangageModel`)
* Chaque carte → `LangageCoursScreen(langage: ...)`
* Bouton flotant “Admin” affiché seulement si `RoleService().getCurrentUserRole().canCreateCours()` est vrai.

#### 7.3.2 `LangageCoursScreen`

* Affiche la description du langage
* Liste des cours (`CoursService.getCoursByLangage(langage.id)`)
* Pour chaque `CoursModel` :

  * N°, titre, nb de cartes, nb de quiz, progression (via `getProgress`)
  * Tap → `CoursSwipeScreen(cours: cours)`

#### 7.3.3 `CoursSwipeScreen`

* Gère la navigation **carte par carte** via un widget custom `SwipableCard` (dans `legacy/swipable_card.dart`).
* À chaque swipe :

  * `CoursService.saveProgress(...)` met à jour la progression.
* À la fin :

  * Écran de complétion avec stats et bouton “Retour aux cours / Recommencer”.

#### 7.3.4 `CourseEditorScreen` (Admin)

Version simplifiée actuelle :

* Écran pour **créer / éditer un cours** avec :

  * `titre`
  * `description` (optionnelle)
* À la création :

  * appelle `CoursService.createCours(...)` avec `cards: []`
* À l’édition :

  * appelle `CoursService.updateCours(...)` (on ne touche pas encore aux cartes)
* L’édition des cartes (leçons/quiz) sera ajoutée plus tard (probablement un autre écran ou un stepper).

---

### 7.4 Onboarding & Welcome

* `OnBoardingScreen` : slides d’intro, animations Lottie, CTA vers `WelcomeScreen`.
* `WelcomeScreen` : choix “Se connecter” / “S’inscrire”.
* Gestion du “onboarding déjà vu” sera plus tard branchée sur `SharedPreferences` dans l’`AuthWrapper`.

---

### 7.5 Profile & Settings

* `ProfileScreen` :

  * Affiche les infos utilisateur chargées depuis Firestore (`AuthService.getProfilUtilisateur`).
* `SettingsScreen` :

  * Changements de thème via `ThemeProvider.toggleTheme()`
  * Potentiellement déconnexion, préférences, etc.

---

## 8. Legacy

Le dossier `legacy/` contient encore :

* `card_model.dart`, `cours_model.dart`, `langage_model.dart`
* `swipable_card.dart`, `cours_card.dart`
* `user_role.dart`, `role_guard.dart`
* `auth_button.dart`, `code_animation.dart`

Ce code est **toujours utilisé** par certaines features (`CoursService`, `CoursSwipeScreen`, etc.), mais l’objectif est :

1. Graduellement migrer ces modèles vers `core/models/`
2. Remplacer les widgets legacy par des widgets dans `core/widgets/` ou `features/*/view/`
3. Supprimer `legacy/` une fois la migration terminée

---

## 9. Idées pour les prochaines étapes MVVM

* Créer un vrai **`AuthViewModel`** qui encapsule les appels `AuthService` + gestion des états de formulaire.
* Introduire un `HomeViewModel` pour la récupération des stats, calendrier, langages/cours.
* Créer des `CourseViewModel` / `CoursesViewModel` pour isoler toute la logique Firestore des écrans.
* Déplacer les modèles (`LangageModel`, `CoursModel`, `CardModel`, `UserRole`) dans `core/models`.

---

## 10. Résumé

* L’app est maintenant structurée en **`core/` (services, thème, routing)** + **`features/` par module**.
* `main.dart` injecte `AuthService` + `ThemeProvider` et gère les routes.
* L’auth, le home, la liste de cours, la navigation par langage et le swiping des cartes fonctionnent avec Firestore.
* L’éditeur de cours admin est **simple** (titre + description), sans gestion des cartes pour l’instant.
* Le dossier `legacy/` sert de transition jusqu’au refactor complet en MVVM.


