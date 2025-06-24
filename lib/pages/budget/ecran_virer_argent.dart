// lib/screens/ecran_virer_argent.dart ou similaire
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../gestion_categories_enveloppes_screen.dart'; // Pour le formatage de la devise

class EcranVirerArgent extends StatefulWidget {
  const EcranVirerArgent({Key? key}) : super(key: key);

  @override
  State<EcranVirerArgent> createState() => _EcranVirerArgentState();
}

class _EcranVirerArgentState extends State<EcranVirerArgent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montantController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(
      locale: 'fr_CA', symbol: '\$');

  List<Categorie> _categoriesAvecEnveloppes = [];
  List<EnveloppeTestData> _toutesLesEnveloppes = [];

  EnveloppeTestData? _enveloppeSourceSelectionnee;
  EnveloppeTestData? _enveloppeDestinationSelectionnee;

  // Pour stocker l'ID de la catégorie parente de l'enveloppe, utile pour la mise à jour
  String? _idCategorieSource;
  String? _idCategorieDestination;


  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _chargerEnveloppes();
    } else {
      // Gérer le cas où l'utilisateur n'est pas connecté
      // Peut-être naviguer vers l'écran de connexion ou afficher un message
      setState(() {
        _isLoading = false;
        _errorMessage = "Utilisateur non connecté.";
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
                "Veuillez vous connecter pour effectuer un virement.")),
          );
          Navigator
              .of(context)
              .pop(); // Revenir en arrière si l'utilisateur n'est pas connecté
        }
      });
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _chargerEnveloppes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final uid = _currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
        "Impossible de récupérer les enveloppes : utilisateur non identifié.";
      });
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
      // .orderBy('ordre') // ou 'nom', selon votre structure
          .get();

      final List<Categorie> categoriesChargees = querySnapshot.docs.map((doc) {
        return Categorie.fromFirestore(
            doc); // Assurez-vous que cette méthode est robuste
      }).toList();

      final List<EnveloppeTestData> toutesEnveloppesTemp = [];
      for (var categorie in categoriesChargees) {
        for (var enveloppe in categorie.enveloppes) {
          // On pourrait stocker l'ID de la catégorie ici si ce n'est pas déjà dans EnveloppeTestData
          // ou le stocker séparément lors de la sélection
          toutesEnveloppesTemp.add(enveloppe);
        }
      }

      // Trier les enveloppes par nom pour une meilleure présentation dans les dropdowns
      toutesEnveloppesTemp.sort((a, b) =>
          a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));


      setState(() {
        _categoriesAvecEnveloppes =
            categoriesChargees; // Utile si vous avez besoin de l'ID de la catégorie parente
        _toutesLesEnveloppes = toutesEnveloppesTemp;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des enveloppes: $e");
      setState(() {
        _isLoading = false;
        _errorMessage =
        "Erreur lors du chargement des enveloppes: ${e.toString()}";
      });
    }
  }

  // Méthode pour trouver l'ID de la catégorie d'une enveloppe
  String? _findCategorieIdForEnveloppe(EnveloppeTestData enveloppe) {
    for (var categorie in _categoriesAvecEnveloppes) {
      if (categorie.enveloppes.any((env) => env.id == enveloppe.id)) {
        return categorie.id;
      }
    }
    return null;
  }


  Future<void> _effectuerVirement() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Validation échouée
    }

    if (_enveloppeSourceSelectionnee == null ||
        _enveloppeDestinationSelectionnee == null ||
        _montantController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    final double? montant = double.tryParse(_montantController.text.replaceAll(
        ',', '.')); // Gérer les virgules et points

    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide.')),
      );
      return;
    }

    if (montant > _enveloppeSourceSelectionnee!.soldeActuel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solde insuffisant dans l\'enveloppe source.')),
      );
      return;
    }

    if (_enveloppeSourceSelectionnee!.id ==
        _enveloppeDestinationSelectionnee!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Les enveloppes source et destination doivent être différentes.')),
      );
      return;
    }

    // Trouver les ID des catégories parentes
    _idCategorieSource =
        _findCategorieIdForEnveloppe(_enveloppeSourceSelectionnee!);
    _idCategorieDestination =
        _findCategorieIdForEnveloppe(_enveloppeDestinationSelectionnee!);

    if (_idCategorieSource == null || _idCategorieDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Erreur: Impossible de trouver les catégories parentes des enveloppes.')),
      );
      return;
    }


    setState(() {
      _isLoading = true;
    }); // Afficher un indicateur de chargement

    final uid = _currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non authentifié.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Lire les documents des catégories source et destination
        final docRefCategorieSource = _firestore
            .collection('users')
            .doc(uid)
            .collection('categories')
            .doc(_idCategorieSource!);
        final docRefCategorieDestination = _firestore.collection('users').doc(
            uid).collection('categories').doc(_idCategorieDestination!);

        DocumentSnapshot<Map<String, dynamic>> snapCategorieSource;
        DocumentSnapshot<Map<String, dynamic>> snapCategorieDestination;

        // Si source et destination sont dans la même catégorie, lire une seule fois
        if (_idCategorieSource == _idCategorieDestination) {
          snapCategorieSource = await transaction.get(docRefCategorieSource);
          snapCategorieDestination = snapCategorieSource; // Même snapshot
        } else {
          snapCategorieSource = await transaction.get(docRefCategorieSource);
          snapCategorieDestination =
          await transaction.get(docRefCategorieDestination);
        }


        if (!snapCategorieSource.exists || !snapCategorieDestination.exists) {
          throw Exception("Une des catégories n'existe plus.");
        }

        Categorie categorieSource = Categorie.fromFirestore(
            snapCategorieSource);
        Categorie categorieDestination = (_idCategorieSource ==
            _idCategorieDestination)
            ? categorieSource // Réutiliser l'instance si c'est la même catégorie
            : Categorie.fromFirestore(snapCategorieDestination);

        // 2. Trouver les enveloppes spécifiques dans les listes d'enveloppes des catégories
        int indexSource = categorieSource.enveloppes.indexWhere((env) =>
        env.id == _enveloppeSourceSelectionnee!.id);
        int indexDestination = categorieDestination.enveloppes.indexWhere((
            env) => env.id == _enveloppeDestinationSelectionnee!.id);

        if (indexSource == -1 || indexDestination == -1) {
          throw Exception(
              "Une des enveloppes n'a pas été trouvée dans sa catégorie respective.");
        }

        // 3. Mettre à jour les soldes
        categorieSource.enveloppes[indexSource].soldeActuel -= montant;
        categorieDestination.enveloppes[indexDestination].soldeActuel +=
            montant;

        // 4. Préparer les données pour la mise à jour
        List<Map<String, dynamic>> enveloppesSourceMaj = categorieSource
            .enveloppes.map((e) => e.toMap()).toList();
        transaction.update(
            docRefCategorieSource, {'enveloppes': enveloppesSourceMaj});

        // Si les catégories sont différentes, mettre à jour la catégorie destination séparément
        if (_idCategorieSource != _idCategorieDestination) {
          List<Map<String,
              dynamic>> enveloppesDestinationMaj = categorieDestination
              .enveloppes.map((e) => e.toMap()).toList();
          transaction.update(docRefCategorieDestination,
              {'enveloppes': enveloppesDestinationMaj});
        }
        // Si c'est la même catégorie, la mise à jour de docRefCategorieSource a déjà tout fait.
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Virement de ${currencyFormatter.format(
            montant)} effectué avec succès!')),
      );
      _montantController.clear();
      setState(() {
        // Réinitialiser les sélections et recharger les données pour refléter les changements
        _enveloppeSourceSelectionnee = null;
        _enveloppeDestinationSelectionnee = null;
        _idCategorieSource = null;
        _idCategorieDestination = null;
        _isLoading = false; // Arrêter le chargement
        _chargerEnveloppes(); // Recharger pour voir les soldes mis à jour
      });
      // Optionnel: Navigator.of(context).pop(); // Revenir à l'écran précédent
    } catch (e) {
      print("Erreur lors du virement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du virement: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Construction de l'UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virer de l\'Argent'),
      ),
      body: _isLoading && _toutesLesEnveloppes
          .isEmpty // Afficher le loader seulement si on n'a rien à montrer
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(
          _errorMessage!, style: const TextStyle(color: Colors.red)))
          : _currentUser == null || _toutesLesEnveloppes.isEmpty && !_isLoading
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _currentUser == null
                ? 'Veuillez vous connecter.'
                : 'Aucune enveloppe trouvée. Créez des enveloppes pour pouvoir effectuer des virements.',
            textAlign: TextAlign.center,
            style: Theme
                .of(context)
                .textTheme
                .titleMedium,
          ),
        ),
      )
          : SingleChildScrollView( // Permet le défilement si le contenu dépasse
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Sélecteur Enveloppe Source ---
              DropdownButtonFormField<EnveloppeTestData>(
                value: _enveloppeSourceSelectionnee,
                decoration: InputDecoration(
                  labelText: 'De (Enveloppe Source)',
                  border: const OutlineInputBorder(),
                  hintText: _enveloppeSourceSelectionnee == null
                      ? 'Choisir une enveloppe'
                      : null,
                ),
                isExpanded: true,
                items: _toutesLesEnveloppes.map((EnveloppeTestData enveloppe) {
                  return DropdownMenuItem<EnveloppeTestData>(
                    value: enveloppe,
                    child: Text('${enveloppe.nom} (${currencyFormatter.format(
                        enveloppe.soldeActuel)})'),
                  );
                }).toList(),
                onChanged: (EnveloppeTestData? newValue) {
                  setState(() {
                    _enveloppeSourceSelectionnee = newValue;
                    // Optionnel: si destination est la même que source, réinitialiser destination
                    if (_enveloppeDestinationSelectionnee?.id == newValue?.id) {
                      _enveloppeDestinationSelectionnee = null;
                    }
                  });
                },
                validator: (value) =>
                value == null
                    ? 'Veuillez sélectionner une enveloppe source.'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Sélecteur Enveloppe Destination ---
              DropdownButtonFormField<EnveloppeTestData>(
                value: _enveloppeDestinationSelectionnee,
                decoration: InputDecoration(
                  labelText: 'Vers (Enveloppe Destination)',
                  border: const OutlineInputBorder(),
                  hintText: _enveloppeDestinationSelectionnee == null
                      ? 'Choisir une enveloppe'
                      : null,
                ),
                isExpanded: true,
                // Filtre pour ne pas afficher l'enveloppe source dans la liste destination
                items: _toutesLesEnveloppes
                    .where((env) => env.id != _enveloppeSourceSelectionnee?.id)
                    .map((EnveloppeTestData enveloppe) {
                  return DropdownMenuItem<EnveloppeTestData>(
                    value: enveloppe,
                    child: Text(enveloppe
                        .nom), // Pas besoin d'afficher le solde ici
                  );
                }).toList(),
                onChanged: (EnveloppeTestData? newValue) {
                  setState(() {
                    _enveloppeDestinationSelectionnee = newValue;
                  });
                },
                validator: (value) =>
                value == null
                    ? 'Veuillez sélectionner une enveloppe destination.'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Champ Montant ---
              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(
                  labelText: 'Montant à Virer',
                  border: const OutlineInputBorder(),
                  prefixText: '\$ ', // Ou votre symbole de devise
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un montant.';
                  }
                  final double? montant = double.tryParse(
                      value.replaceAll(',', '.'));
                  if (montant == null || montant <= 0) {
                    return 'Veuillez saisir un montant valide.';
                  }
                  if (_enveloppeSourceSelectionnee != null &&
                      montant > _enveloppeSourceSelectionnee!.soldeActuel) {
                    return 'Solde insuffisant.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Bouton de Virement ---
              ElevatedButton.icon(
                icon: _isLoading ? Container(width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3)) : const Icon(
                    Icons.send),
                label: Text(_isLoading
                    ? 'Virement en cours...'
                    : 'Effectuer le Virement'),
                onPressed: _isLoading ? null : _effectuerVirement,
                // Désactiver pendant le chargement
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}