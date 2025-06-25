// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <<<--- 1. IMPORTEZ CECI
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
    const Color couleurFondSombre = Color(0xFF121212);
    const Color couleurPrimaire = Color(0xFF830101);
    const Color couleurTexteBlanc = Colors.white;
    const Color couleurSurfaceSombre = Color(0xFF1E1E1E);

    return MaterialApp(
      title: 'Mon Budget Facile',

      // --- 2. AJOUTS POUR LA LOCALISATION ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
        Locale('en', ''), // Anglais (comme fallback ou si vous le supportez)
        // Ajoutez d'autres locales que vous souhaitez supporter
      ],
      // Vous pouvez définir la locale par défaut de l'application ici si nécessaire,
      // mais votre DatePickerDialog spécifie déjà 'fr_FR'.
      // locale: const Locale('fr', 'FR'),
      // --- FIN DES AJOUTS POUR LA LOCALISATION ---

      theme: ThemeData(
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
          error: Colors.red[700]!,
          onError: couleurTexteBlanc,
          outline: couleurPrimaire.withAlpha(150),
        ),
        dividerColor: couleurPrimaire,
        appBarTheme: const AppBarTheme(
          backgroundColor: couleurSurfaceSombre,
          elevation: 0,
          iconTheme: IconThemeData(color: couleurTexteBlanc),
          titleTextStyle: TextStyle(
            color: couleurTexteBlanc,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        textTheme: Typography.whiteMountainView
            .apply(
          bodyColor: couleurTexteBlanc,
          displayColor: couleurTexteBlanc,
        ).copyWith(
          titleLarge: const TextStyle(color: couleurTexteBlanc,
              fontSize: 22,
              fontWeight: FontWeight.w500),
          titleMedium: const TextStyle(color: couleurTexteBlanc,
              fontSize: 18,
              fontWeight: FontWeight.normal),
          bodyMedium: const TextStyle(color: couleurTexteBlanc, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: couleurPrimaire,
            foregroundColor: couleurTexteBlanc,
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: couleurPrimaire,
          foregroundColor: couleurTexteBlanc,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: couleurSurfaceSombre,
          selectedItemColor: couleurPrimaire,
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1C),
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: TextStyle(color: couleurTexteBlanc.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: couleurPrimaire, width: 2.0),
          ),
        ),
        cardTheme: CardThemeData(
          color: couleurSurfaceSombre,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        useMaterial3: true,
      ),
      home: const EcranAccueil(),
      debugShowCheckedModeBanner: false,
    );
  }
}