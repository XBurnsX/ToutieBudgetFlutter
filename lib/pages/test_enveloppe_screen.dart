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
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
      ),
      EnveloppeTestData(
        id: 'env1',
        nom: 'Affirm kath',
        soldeActuel: 38.80,
        montantAlloue: 38.80,
        typeObjectif: TypeObjectif.aucun,
        montantCible: null,
        couleurSoldeCompteValue: Colors.orange.value,
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