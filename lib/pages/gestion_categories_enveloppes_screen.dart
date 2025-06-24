// lib/screens/gestion_categories_enveloppes_screen.dart
import 'package:flutter/material.dart';

class GestionCategoriesEnveloppesScreen extends StatelessWidget {
  const GestionCategoriesEnveloppesScreen({Key? key}) : super(key: key);

  static const String routeName = '/gestion-categories-enveloppes'; // Optionnel, pour les routes nommées

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer Catégories/Enveloppes'),
      ),
      body: const Center(
        child: Text(
          'Page de Gestion des Catégories et Enveloppes - À construire !',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}