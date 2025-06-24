// lib/pages/ecran_creation_compte.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Pour le sélecteur de couleur

// Import du modèle de TypeDeCompte (si vous l'avez dans un fichier séparé)
// Si TypeDeCompte est défini dans compte_model.dart, importez ce dernier
import '../models/compte_model.dart'; // Assurez-vous que ce chemin est correct et que TypeDeCompte y est défini

class EcranCreationCompte extends StatefulWidget {
  const EcranCreationCompte({super.key});

  @override
  State<EcranCreationCompte> createState() => _EcranCreationCompteState();
}

class _EcranCreationCompteState extends State<EcranCreationCompte> {
  final _formKey = GlobalKey<FormState>();
  String _nomCompte = '';
  double _soldeInitial = 0.0;
  TypeDeCompte _typeDeCompteSelectionne = TypeDeCompte
      .compteBancaire; // Valeur par défaut
  Color _couleurCompteSelectionnee = Color(0xFF037703); // Couleur par défaut
  bool _isSaving = false;

  // Pas de dispose nécessaire pour les contrôleurs car ils ne sont pas utilisés directement
  // mais via onSaved et les variables d'état.
  // Si vous utilisiez des TextEditingController, vous les disposeriez ici.

  // --- Fonctions auxiliaires (avant le build) ---

  void _ouvrirSelecteurDeCouleur() {
    Color pickerColor = _couleurCompteSelectionnee; // Couleur initiale du picker

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisissez une couleur pour le compte'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (nouvelleCouleur) {
                pickerColor =
                    nouvelleCouleur; // Met à jour la couleur dans le scope du dialogue
              },
              availableColors: [
                Color(0xFF037703),// Exemples de couleurs, vous pouvez personnaliser cette liste
                Color(0xFF0F3B01),
                Color(0xFFBE6304),
                Color(0xFF73400B),
                Color(0xFFBEBE06),
                Color(0xFF545408),
                Color(0xFF0FC95A),
                Color(0xFF0D5930),
                Color(0xFF0FB0B0),
                Color(0xFF0A5252),
                Color(0xFF1165BD),
                Color(0xFF0A4983),
                Color(0xFF1212DA),
                Color(0xFF4F1CA6),
                Color(0xFF7D00FF),
                Color(0xFFD046D0),
                Color(0xFF6E1466),
                Color(0xFFD02279),
                Color(0xFF830746),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  _couleurCompteSelectionnee =
                      pickerColor; // Applique la couleur sélectionnée à l'état
                });
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
      return; // Si le formulaire n'est pas valide, ne rien faire
    }
    _formKey.currentState!
        .save(); // Appelle les méthodes onSaved des champs du formulaire

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Erreur: Utilisateur non connecté. Veuillez vous reconnecter.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    String uid = currentUser.uid;

    try {
      // Préparation des données du compte
      Map<String, dynamic> donneesCompte = {
        'nom': _nomCompte,
        'soldeInitial': _soldeInitial,
        'soldeActuel': _soldeInitial, // <--- ASSUREZ-VOUS QUE CECI EST BIEN LÀ
        'type': _typeDeCompteSelectionne.toString().split('.').last,
        'couleurHex': '#${_couleurCompteSelectionnee.value.toRadixString(16).substring(2).padLeft(6, '0')}',
        'dateCreation': Timestamp.now(),
        'devise': 'CAD',
      };

      // Ajout du document à la sous-collection 'comptes' de l'utilisateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('comptes')
          .add(donneesCompte);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compte "$_nomCompte" créé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
            context, true); // Retourne à l'écran précédent, true indique succès
      }
    } catch (e) {
      debugPrint("Erreur Firestore lors de la création du compte: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Firestore: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 20.0;
    const double fieldVerticalSpacing = 18.0;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Créer un nouveau compte'),
          // backgroundColor: Theme.of(context).primaryColor, // Optionnel: pour styler l'AppBar
        ),
        body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
    const SizedBox(height: 20.0)
    , // Espace en haut// Champ Nom du compte
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Nom du compte',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          hintText: 'Ex: Compte Chèque, Épargne Voyage',
        ),
        validator: (value) {
          if (value == null || value
              .trim()
              .isEmpty) {
            return 'Veuillez entrer un nom pour le compte.';
          }
          if (value.length > 50) {
            return 'Le nom ne doit pas dépasser 50 caractères.';
          }
          return null;
        },
        onSaved: (value) => _nomCompte = value!.trim(),
      ),
      const SizedBox(height: fieldVerticalSpacing),

      // Champ Solde initial
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Solde initial',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.attach_money),
          suffixText: 'CAD', // Ou la devise par défaut/sélectionnée
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un solde initial (0 si aucun).';
          }
          final n = double.tryParse(value.replaceAll(
              ',', '.')); // Gère la virgule comme séparateur décimal
          if (n == null) {
            return 'Veuillez entrer un nombre valide.';
          }
          if (n < -1000000000 || n > 1000000000) {
            return 'Le solde est hors des limites acceptables.';
          }
          return null;
        },
        onSaved: (value) =>
        _soldeInitial = double.parse(value!.replaceAll(',', '.')),
      ),
      const SizedBox(height: fieldVerticalSpacing),

      // Champ Type de compte
      DropdownButtonFormField<TypeDeCompte>(
        decoration: const InputDecoration(
          labelText: 'Type de compte',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category_outlined),
        ),
        value: _typeDeCompteSelectionne,
        items: TypeDeCompte.values.map((TypeDeCompte type) {
          // Pour un affichage plus convivial des noms des enum
          String displayName = type
              .toString()
              .split('.')
              .last;
          displayName = displayName.replaceAllMapped(
              RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim();
          displayName = displayName[0].toUpperCase() + displayName
              .substring(1)
              .toLowerCase();
          if (displayName == "Compte bancaire")
            displayName = "Compte bancaire"; // Cas spécifique si besoin
          else if (displayName == "Especes") displayName = "Espèces";

          return DropdownMenuItem<TypeDeCompte>(
            value: type,
            child: Text(displayName),
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
            ? 'Veuillez sélectionner un type de compte.'
            : null,
      ),
      const SizedBox(height: fieldVerticalSpacing),

      // Sélecteur de Couleur
      Row(
        children: [
          const Text('Couleur du compte:', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          InkWell(
            onTap: _ouvrirSelecteurDeCouleur,
            borderRadius: BorderRadius.circular(18),
            // Pour un effet de ripple circulaire
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _couleurCompteSelectionnee,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  boxShadow: [ // Petite ombre pour un effet de profondeur
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _ouvrirSelecteurDeCouleur,
            child: const Text('Choisir une couleur'),
          )
        ],
      ),
      const SizedBox(height: fieldVerticalSpacing * 1.5),
      // Plus d'espace avant le bouton

      // Bouton Enregistrer
      if (_isSaving)
        const Center(child: Padding(
            padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
      else
        ElevatedButton.icon(
          icon: const Icon(Icons.save_alt_outlined),
          label: const Text('Enregistrer le compte'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: Theme
                .of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            // backgroundColor: Theme.of(context).primaryColor, // Optionnel
            // foregroundColor: Colors.white, // Optionnel
          ),
          onPressed: _enregistrerCompte,
        ),
      const SizedBox(height: fieldVerticalSpacing),
      // Espace en bas
    ],
    ),
    ),
        ),
        ),
        ),
    );
  }
}