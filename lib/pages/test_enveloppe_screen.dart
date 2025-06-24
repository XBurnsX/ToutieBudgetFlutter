// lib/screens/test_enveloppe_screen.dart

import 'package:flutter/material.dart';

import '../widgets/EnveloppeCard.dart';

class TestEnveloppeScreen extends StatelessWidget {
  const TestEnveloppeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Liste de données de test pour les enveloppes
    final List<EnveloppeTestData> enveloppesDeTest = [
      EnveloppeTestData(
        nom: 'Épicerie',
        icone: Icons.shopping_cart_checkout_rounded,
        soldeActuel: 53.75,
        montantAlloue: 100.00,
        typeObjectif: TypeObjectif.mensuel,
        montantCible: 200.00,
        couleurTheme: Colors.orange.shade700,
        couleurSoldeCompte: Colors.green.shade500,
      ),
      EnveloppeTestData(
        nom: 'Loyer',
        icone: Icons.home_work_rounded,
        soldeActuel: 0,
        // Solde à 0 après paiement, mais objectif mensuel atteint
        montantAlloue: 1250.00,
        typeObjectif: TypeObjectif.mensuel,
        montantCible: 1250.00,
        couleurTheme: Colors.blue.shade700,
        couleurSoldeCompte: Colors.grey.shade500, // Sera gris car solde = 0
      ),
      EnveloppeTestData(
        nom: 'Vacances',
        icone: Icons.flight_takeoff_rounded,
        soldeActuel: 1350.00,
        montantAlloue: 150.00,
        // Montant ajouté ce cycle, pour info
        typeObjectif: TypeObjectif.dateFixe,
        montantCible: 3500.00,
        dateCible: DateTime(2025, 7, 20),
        couleurTheme: Colors.teal.shade600,
        couleurSoldeCompte: Colors.green.shade500,
      ),
      EnveloppeTestData(
        nom: 'Restaurants & Sorties',
        icone: Icons.local_bar_rounded,
        soldeActuel: -35.10,
        montantAlloue: 150.00,
        // Alloué au départ
        typeObjectif: TypeObjectif.mensuel,
        // Avait un objectif mensuel
        montantCible: 150.00,
        couleurTheme: Colors.purple.shade500,
        couleurSoldeCompte: Colors.red.shade700, // Sera rouge car solde < 0
      ),
      EnveloppeTestData(
        nom: 'Prêt Étudiant',
        icone: Icons.school_rounded,
        soldeActuel: 0.00,
        montantAlloue: 0.00,
        typeObjectif: TypeObjectif.aucun,
        couleurTheme: Colors.indigo.shade600,
        couleurSoldeCompte: Colors.grey.shade500, // Sera gris car solde = 0
      ),
      EnveloppeTestData(
        nom: 'Cadeaux',
        icone: Icons.cake_rounded,
        soldeActuel: 75.00,
        montantAlloue: 20.00,
        // Montant alloué/ajouté ce cycle
        typeObjectif: TypeObjectif.aucun,
        couleurTheme: Colors.pink.shade400,
        couleurSoldeCompte: Colors.green.shade500,
      ),
      EnveloppeTestData(
        nom: 'Vêtements',
        icone: Icons.checkroom_rounded,
        soldeActuel: 15.00,
        // Un peu de report du mois précédent
        montantAlloue: 0.00,
        // Rien alloué ce mois-ci
        typeObjectif: TypeObjectif.mensuel,
        montantCible: 75.00,
        couleurTheme: Colors.brown.shade500,
        couleurSoldeCompte: Colors.green.shade500,
      ),
      EnveloppeTestData(
        nom: 'Épargne Urgence',
        icone: Icons.savings_rounded,
        soldeActuel: 5000.00,
        montantAlloue: 0.00,
        // Plus besoin d'allouer
        typeObjectif: TypeObjectif.dateFixe,
        montantCible: 5000.00,
        dateCible: DateTime(2024, 12, 31),
        couleurTheme: Colors.lightGreen.shade700,
        couleurSoldeCompte: Colors.green.shade500,
      ),
      EnveloppeTestData(
        nom: 'Abonnements',
        icone: Icons.subscriptions_rounded,
        soldeActuel: 10.00,
        // Reste 10$ sur ce qui était alloué
        montantAlloue: 50.00,
        // 50$ étaient alloués pour cette catégorie
        typeObjectif: TypeObjectif.aucun,
        couleurTheme: Colors.cyan.shade700,
        couleurSoldeCompte: Colors.green.shade500,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu des Enveloppes'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
        itemCount: enveloppesDeTest.length,
        itemBuilder: (context, index) {
          return EnveloppeCard(enveloppe: enveloppesDeTest[index]);
        },
      ),
    );
  }
}