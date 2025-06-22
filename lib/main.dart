// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/ecran_accueil.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    // Définissons nos couleurs personnalisées
    const Color couleurFondSombre = Color(0xFF121212); // Un noir pas tout à fait 0x000000, un peu plus doux
    const Color couleurPrimaire = Color(0xFF830101); // Ou un rouge plus spécifique ex: const Color(0xFFD32F2F);
    const Color couleurTexteBlanc = Colors.white;
    const Color couleurSurfaceSombre = Color(0xFF1E1E1E); // Pour les surfaces comme les Cards, dialogues

    return MaterialApp(
      title: 'Mon Budget Facile',
      theme: ThemeData( // <<< DÉBUT DU CONSTRUCTEUR ThemeData
        brightness: Brightness.dark,
        scaffoldBackgroundColor: couleurFondSombre,
        primaryColor: couleurPrimaire,
        colorScheme: ColorScheme.dark(
          primary: couleurPrimaire,
          onPrimary: couleurTexteBlanc,
          secondary: couleurPrimaire,
          onSecondary: couleurTexteBlanc,
          surface: couleurSurfaceSombre,
          onSurface: couleurTexteBlanc,
          background: couleurFondSombre,
          onBackground: couleurTexteBlanc,
          error: Colors.red[700]!,
          onError: couleurTexteBlanc,
          outline: couleurPrimaire.withAlpha(150),
        ), // <<< FIN de colorScheme

        dividerColor: couleurPrimaire, // VOTRE dividerColor EST BIEN ICI

        // Thème pour l'AppBar
        appBarTheme: const AppBarTheme( // <<< DOIT ÊTRE À L'INTÉRIEUR DE ThemeDat
          backgroundColor: couleurSurfaceSombre,
          // Fond des AppBars
          elevation: 0,
          // Pas d'ombre par défaut pour un look plus plat
          iconTheme: IconThemeData(color: couleurTexteBlanc),
          // Icônes de l'AppBar en blanc
          titleTextStyle: TextStyle(
            color: couleurTexteBlanc,
            fontSize: 20,
            fontWeight: FontWeight.w500, // Un peu moins gras que bold
          ),
        ),

        // Thème pour le texte global
        textTheme: Typography.whiteMountainView
            .apply( // Utilise un ensemble de styles de texte blancs comme base
          bodyColor: couleurTexteBlanc,
          // Couleur par défaut pour le corps du texte
          displayColor: couleurTexteBlanc, // Couleur pour les grands textes (display, headline)
        ).copyWith( // Et on peut surcharger spécifiquement si besoin
          titleLarge: const TextStyle(color: couleurTexteBlanc,
              fontSize: 22,
              fontWeight: FontWeight.w500),
          titleMedium: const TextStyle(color: couleurTexteBlanc,
              fontSize: 18,
              fontWeight: FontWeight.normal),
          bodyMedium: const TextStyle(color: couleurTexteBlanc, fontSize: 16),
        ),

        // Thème pour les boutons (ElevatedButton, TextButton, OutlinedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: couleurPrimaire,
            // Fond des ElevatedButton
            foregroundColor: couleurTexteBlanc,
            // Couleur du texte et de l'icône du bouton
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  8.0), // Coins légèrement arrondis
            ),
          ),
        ),
        // Vous pouvez aussi définir textButtonTheme et outlinedButtonTheme si vous les utilisez
        // textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: couleurPrimaireRouge)),

        // Thème pour les FloatingActionButtons
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: couleurPrimaire,
          foregroundColor: couleurTexteBlanc,
        ),

        // Thème pour la BottomNavigationBar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: couleurSurfaceSombre,
          selectedItemColor: couleurPrimaire,
          // Couleur de l'item sélectionné
          unselectedItemColor: Colors.grey[500],
          // Couleur des items non sélectionnés
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          // type: BottomNavigationBarType.fixed, // Déjà géré dans EcranAccueil, mais peut être mis ici
        ),

        // Thème pour les champs de saisie (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1C1C1C),
          // Fond légèrement différent pour les champs
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: TextStyle(color: couleurTexteBlanc.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none, // Pas de bordure par défaut
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: couleurPrimaire,
                width: 2.0), // Bordure rouge quand focus
          ),
          // contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        ),

        // Thème pour les Card
        cardTheme: CardThemeData( // <<< CORRECT ICI
          color: couleurSurfaceSombre,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        // Assurez-vous d'utiliser Material 3 pour que ColorScheme soit pleinement utilisé
        useMaterial3: true,
      ),
      home: const EcranAccueil(),
      debugShowCheckedModeBanner: false,
    );
  }
}