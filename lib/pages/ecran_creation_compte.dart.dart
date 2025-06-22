import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // IMPORT POUR LE COLOR PICKER

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
  Color _couleurCompteSelectionnee = Colors.green; // AJOUT: Couleur par défaut
  bool _isSaving = false;

  // Fonction pour afficher le sélecteur de couleur
  void _ouvrirSelecteurDeCouleur() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisissez une couleur pour le compte'),
          content: SingleChildScrollView(
            child: BlockPicker( // Ou ColorPicker, SlidePicker, etc.
              pickerColor: _couleurCompteSelectionnee,
              onColorChanged: (nouvelleCouleur) {
                setState(() {
                  _couleurCompteSelectionnee = nouvelleCouleur;
                });
              },
              // availableColors: [ // Vous pouvez limiter les couleurs disponibles
              //   Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
              //   Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
              //   // ... autres couleurs
              // ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _enregistrerCompte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur non connecté.')),
      );
      return;
    }

    setState(() { _isSaving = true; });
    String uid = currentUser.uid;

    try {
      Map<String, dynamic> donneesCompte = {
        'nom': _nomCompte,
        'soldeInitial': _soldeInitial,
        'type': _typeDeCompteSelectionne.toString().split('.').last,
        'couleurValue': _couleurCompteSelectionnee.value, // AJOUT: Sauvegarde de la valeur entière
        'soldeActuel': _soldeInitial,
        'dateCreation': Timestamp.now(),
        'devise': 'CAD',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('comptes')
          .add(donneesCompte);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compte "$_nomCompte" créé avec succès!')),
      );
      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      print("Erreur Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur Firestore: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 20.0;
    const double fieldVerticalSpacing = 18.0; // Un peu réduit pour plus de champs

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un nouveau compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20.0),
                  TextFormField( /* ... Nom du compte ... */
                    decoration: const InputDecoration(labelText: 'Nom du compte', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Veuillez entrer un nom.' : null,
                    onSaved: (value) => _nomCompte = value!.trim(),
                  ),
                  const SizedBox(height: fieldVerticalSpacing),
                  TextFormField( /* ... Solde initial ... */
                    decoration: const InputDecoration(labelText: 'Solde initial', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez entrer un solde.';
                      if (double.tryParse(value) == null) return 'Nombre invalide.';
                      return null;
                    },
                    onSaved: (value) => _soldeInitial = double.parse(value!),
                  ),
                  const SizedBox(height: fieldVerticalSpacing),
                  DropdownButtonFormField<TypeDeCompte>( /* ... Type de compte ... */
                    decoration: const InputDecoration(labelText: 'Type de compte', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined)),
                    value: _typeDeCompteSelectionne,
                    items: TypeDeCompte.values.map((TypeDeCompte type) => DropdownMenuItem<TypeDeCompte>(value: type, child: Text(type.toString().split('.').last.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim().replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase())) )).toList(),
                    onChanged: (TypeDeCompte? newValue) => (newValue != null) ? setState(() => _typeDeCompteSelectionne = newValue) : null,
                    validator: (value) => value == null ? 'Sélectionnez un type.' : null,
                  ),
                  const SizedBox(height: fieldVerticalSpacing),

                  // --- AJOUT DU SÉLECTEUR DE COULEUR ---
                  Row(
                    children: [
                      const Text('Couleur du compte:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _ouvrirSelecteurDeCouleur,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _couleurCompteSelectionnee,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          ),
                        ),
                      ),
                      const Spacer(), // Pour pousser le bouton à droite si nécessaire
                      TextButton(
                        onPressed: _ouvrirSelecteurDeCouleur,
                        child: const Text('Choisir une couleur'),
                      )
                    ],
                  ),
                  // --- FIN DE L'AJOUT ---

                  const SizedBox(height: fieldVerticalSpacing * 1.5),
                  if (_isSaving)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0), textStyle: Theme.of(context).textTheme.titleMedium),
                      onPressed: _enregistrerCompte,
                      child: const Text('Enregistrer le compte'),
                    ),
                  const SizedBox(height: fieldVerticalSpacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}