// lib/pages/ecran_creation_compte.dart
import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart';

class EcranCreationCompte extends StatefulWidget {
  const EcranCreationCompte({super.key});

  @override
  State<EcranCreationCompte> createState() => _EcranCreationCompteState();
}

class _EcranCreationCompteState extends State<EcranCreationCompte> {
  final _formKey = GlobalKey<FormState>();
  String _nomCompte = '';
  double _soldeInitial = 0.0;
  TypeDeCompte _typeDeCompteSelectionne = TypeDeCompte.compteBancaire;

  void _enregistrerCompte() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final nouveauCompte = Compte(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        nom: _nomCompte,
        type: _typeDeCompteSelectionne,
        solde: _soldeInitial,
      );
      // Pour l'instant, on retourne juste à l'écran précédent
      // Vous passerez 'nouveauCompte' si l'écran précédent doit le recevoir
      Navigator.pop(context, nouveauCompte);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 20.0;
    const double fieldVerticalSpacing = 24.0; // Espacement entre les champs

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un nouveau compte'),
      ),
      body: SafeArea( // Bonne pratique
        child: SingleChildScrollView( // Pour gérer le dépassement avec le clavier
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Pour que le bouton prenne toute la largeur
                children: <Widget>[
                  // VVVV VOTRE AJOUT DEMANDÉ ICI VVVV
                  const SizedBox(height: 100.0),
                  // AJOUTEZ CET ESPACE EN HAUT
                  // ^^^^ VOTRE AJOUT DEMANDÉ ICI ^^^^

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nom du compte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom.';
                      }
                      return null;
                    },
                    onSaved: (value) => _nomCompte = value!,
                  ),
                  const SizedBox(height: fieldVerticalSpacing),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Solde initial',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un solde.';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Nombre invalide.';
                      }
                      return null;
                    },
                    onSaved: (value) => _soldeInitial = double.parse(value!),
                  ),
                  const SizedBox(height: fieldVerticalSpacing),

                  DropdownButtonFormField<TypeDeCompte>(
                    decoration: const InputDecoration(
                      labelText: 'Type de compte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    value: _typeDeCompteSelectionne,
                    items: TypeDeCompte.values.map((TypeDeCompte type) {
                      return DropdownMenuItem<TypeDeCompte>(
                        value: type,
                        child: Text(type
                            .toString()
                            .split('.')
                            .last
                            .replaceAllMapped(
                            RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}'
                        )
                            .trim()
                            .replaceFirstMapped(RegExp(r'^[a-z]'), (match) =>
                            match.group(0)!.toUpperCase())
                        ),
                      );
                    }).toList(),
                    onChanged: (TypeDeCompte? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _typeDeCompteSelectionne = newValue;
                        });
                      }
                    },
                    validator: (value) =>
                    value == null
                        ? 'Sélectionnez un type.'
                        : null,
                  ),
                  const SizedBox(height: fieldVerticalSpacing * 1.5),
                  // Un peu plus d'espace avant le bouton

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: Theme
                          .of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    onPressed: _enregistrerCompte,
                    child: const Text('Enregistrer le compte'),
                  ),
                  const SizedBox(height: fieldVerticalSpacing),
                  // Espace optionnel en bas de la page
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}