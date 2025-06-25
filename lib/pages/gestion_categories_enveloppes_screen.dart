import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toutie_budget/models/categorie_model.dart';
import '../models/enveloppe_model.dart';

enum TypeObjectif {
  aucun,
  mensuel,
  dateFixe,
}

class CompteBancaireModel {
  final String id;
  final String nom;

  CompteBancaireModel({required this.id, required this.nom});

  factory CompteBancaireModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour le compte ID: ${doc.id}');
    }
    return CompteBancaireModel(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Compte inconnu',
    );
  }
}


class Categorie {
  String id;
  String nom;

  Categorie({
    required this.id,
    required this.nom,
  });

  factory Categorie.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour la catégorie ID: ${doc.id}');
    }
    return Categorie(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom non défini',
    );
  }
}

class GestionCategoriesEnveloppesScreen extends StatefulWidget {
  const GestionCategoriesEnveloppesScreen({super.key});

  @override
  State<GestionCategoriesEnveloppesScreen> createState() =>
      _GestionCategoriesEnveloppesScreenState();
}

class _GestionCategoriesEnveloppesScreenState
    extends State<GestionCategoriesEnveloppesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  final currencyFormatter = NumberFormat.currency(
      locale: 'fr_CA', symbol: '\$');
  final TextEditingController _nomCategorieController = TextEditingController();
  final TextEditingController _nomEnveloppeController = TextEditingController();
  final TextEditingController _montantInitialEnveloppeController = TextEditingController();

  String? _selectedCompteIdPourNouvelleEnveloppe;
  List<CompteBancaireModel> _comptesBancairesUtilisateur = [];

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      print("ERREUR: Utilisateur non connecté sur l'écran de gestion.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
                'Utilisateur non connecté. Veuillez vous reconnecter.'),
                duration: Duration(seconds: 5)),
          );
        }
      });
    } else {
      _chargerComptesBancaires();
    }
  }

  @override
  void dispose() {
    _nomCategorieController.dispose();
    _nomEnveloppeController.dispose();
    _montantInitialEnveloppeController.dispose();
    super.dispose();
  }

  Future<void> _chargerComptesBancaires() async {
    if (_currentUser == null) return;
    try {
      final snapshot = await _firestore.collection('users')
          .doc(_currentUser!.uid)
          .collection('comptes') // VÉRIFIEZ CE CHEMIN
          .get();
      _comptesBancairesUtilisateur = snapshot.docs
          .map((doc) => CompteBancaireModel.fromSnapshot(doc))
          .toList();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Erreur chargement comptes bancaires: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement des comptes: $e')),
        );
      }
    }
  }

  CollectionReference<Map<String, dynamic>>? _getUserCategoriesCollection() {
    final uid = _currentUser?.uid;
    if (uid != null) {
      return _firestore.collection('users').doc(uid).collection('categories');
    }
    print("Tentative d'accès aux catégories sans UID utilisateur.");
    return null;
  }

  DocumentReference<Map<String, dynamic>>? _getUserCategoryDoc(
      String categoryId) {
    final uid = _currentUser?.uid;
    if (uid != null) {
      return _firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId);
    }
    print("Tentative d'accès au document catégorie sans UID utilisateur.");
    return null;
  }

  String _getNomMoisActuel() {
    return DateFormat('MMMM', 'fr_FR').format(DateTime.now());
  }

  Stream<List<EnveloppeModel>> _getAllEnveloppesAvecObjectifMensuelStream() {
    if (_currentUser == null) return Stream.value([]);
    return _firestore
        .collectionGroup('enveloppes')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('typeObjectifString', isEqualTo: TypeObjectif.mensuel.name)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => EnveloppeModel.fromSnapshot(doc)).toList());
  }

  Widget _buildTrailingWidgetForEnveloppeModel(EnveloppeModel enveloppe,
      ThemeData theme) {
    TypeObjectif typeObjectifLocal = TypeObjectif.values.firstWhere(
          (e) => e.name == enveloppe.typeObjectifString,
      orElse: () => TypeObjectif.aucun,
    );

    bool aUnObjectifDefini = typeObjectifLocal != TypeObjectif.aucun &&
        enveloppe.objectifMontantPeriodique != null &&
        enveloppe.objectifMontantPeriodique! > 0;

    if (aUnObjectifDefini) {
      String objectifStr = 'Obj: ${currencyFormatter.format(
          enveloppe.objectifMontantPeriodique)}';
      if (typeObjectifLocal == TypeObjectif.mensuel) {
        objectifStr += '/mois';
      } else if (typeObjectifLocal == TypeObjectif.dateFixe &&
          enveloppe.objectifDateEcheance != null) {
        objectifStr += ' pour ${DateFormat('dd/MM/yy', 'fr_FR').format(
            enveloppe.objectifDateEcheance!)}';
      }
      return Text(
        objectifStr,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      );
    } else {
      return TextButton(
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerRight),
        onPressed: () {
          print('Naviguer pour définir/modifier l\'objectif pour ${enveloppe
              .nom}');
          // TODO: Implémenter la navigation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Définition d\'objectif pour ${enveloppe
                  .nom} non implémentée.')),
            );
          }
        },
        child: Text('Ajouter objectif',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: theme.textTheme.bodySmall?.fontSize)),
      );
    }
  }

  void _navigateToReorderScreen() {
    print('Navigation vers la page de réorganisation demandée.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Page de réorganisation non implémentée.')),
      );
    }
  } // --- Gestion des Catégories ---
  void _afficherDialogueAjoutCategorie() {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Veuillez vous connecter pour ajouter une catégorie.')));
      }
      return;
    }
    _nomCategorieController.clear();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Nouvelle Catégorie'),
          content: TextField(
            controller: _nomCategorieController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nom de la catégorie"),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () => _ajouterCategorie(dialogContext),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ajouterCategorie(BuildContext dialogContext) async {
    final nomCategorie = _nomCategorieController.text.trim();
    if (nomCategorie.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le nom de la catégorie ne peut pas être vide.')));
      }
      return;
    }

    final userCategoriesCollection = _getUserCategoriesCollection();
    if (userCategoriesCollection == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Utilisateur non authentifié. Impossible d\'ajouter.')));
      }
      Navigator.of(dialogContext).pop();
      return;
    }

    try {
      await userCategoriesCollection.add({
        'nom': nomCategorie,
      });
      Navigator.of(dialogContext).pop();
      _nomCategorieController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catégorie "$nomCategorie" ajoutée.')));
      }
    } catch (e) {
      print("Erreur ajout catégorie: $e");
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout: $e')));
      }
    }
  }

  void _afficherDialogueModificationCategorie(Categorie categorie) {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez vous connecter pour modifier.')));
      }
      return;
    }
    _nomCategorieController.text = categorie.nom;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Modifier le nom de "${categorie.nom}"'),
          content: TextField(
            controller: _nomCategorieController,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _nomCategorieController.clear();
              },
            ),
            TextButton(
              child: const Text('Sauvegarder'),
              onPressed: () async {
                final nouveauNom = _nomCategorieController.text.trim();
                if (nouveauNom.isEmpty) return;

                final categoryDocRef = _getUserCategoryDoc(categorie.id);
                if (categoryDocRef == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Utilisateur non authentifié.')));
                  }
                  Navigator.of(dialogContext).pop();
                  return;
                }
                try {
                  await categoryDocRef.update({'nom': nouveauNom});
                  Navigator.of(dialogContext).pop();
                  _nomCategorieController.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                          'Catégorie renommée en "$nouveauNom".')));
                  }
                } catch (e) {
                  print("Erreur modification catégorie: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Erreur de modification: $e')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmerSuppressionCategorie(Categorie categorie) {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez vous connecter pour supprimer.')));
      }
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Supprimer la catégorie "${categorie
              .nom}" et toutes ses enveloppes ? Attention, cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer Définitivement'),
              onPressed: () async {
                final categoryDocRef = _getUserCategoryDoc(categorie.id);
                if (categoryDocRef == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Utilisateur non authentifié.')));
                  }
                  Navigator.of(dialogContext).pop();
                  return;
                }
                try {
                  // Supprimer d'abord toutes les enveloppes dans la sous-collection
                  final enveloppesSnapshot = await categoryDocRef.collection(
                      'enveloppes').get();
                  WriteBatch batch = _firestore.batch();
                  for (DocumentSnapshot doc in enveloppesSnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch
                      .commit(); // Exécuter la suppression en batch des enveloppes

                  // Ensuite, supprimer la catégorie elle-même
                  await categoryDocRef.delete();

                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Catégorie "${categorie
                          .nom}" et ses enveloppes supprimées.')));
                  }
                } catch (e) {
                  print("Erreur suppression catégorie: $e");
                  Navigator
                      .of(dialogContext)
                      .pop(); // S'assurer que le dialogue est fermé
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur de suppression: $e')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

// --- Gestion des Enveloppes ---
  void _afficherDialogueAjoutEnveloppe(Categorie categorie) {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Veuillez vous connecter pour ajouter une enveloppe.')));
      }
      return;
    }
    _nomEnveloppeController.clear();
    _montantInitialEnveloppeController.clear();
    _selectedCompteIdPourNouvelleEnveloppe = null; // Réinitialiser

    if (_comptesBancairesUtilisateur.isEmpty) {
      // Peut-être recharger ou informer l'utilisateur qu'aucun compte n'est disponible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
                'Aucun compte bancaire trouvé. Veuillez en ajouter un ou recharger.')),
          );
        }
      });
      return; // Ne pas ouvrir le dialogue si aucun compte n'est disponible
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Utiliser StatefulBuilder pour gérer l'état du DropdownButton à l'intérieur du dialogue
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nouvelle Enveloppe pour "${categorie.nom}"'),
              content: SingleChildScrollView( // Pour éviter les problèmes de dépassement de hauteur
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _nomEnveloppeController,
                      autofocus: true,
                      decoration: const InputDecoration(
                          hintText: "Nom de l'enveloppe"),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _montantInitialEnveloppeController,
                      decoration: InputDecoration(
                          hintText: "Montant initial (optionnel)",
                          prefixText: "${currencyFormatter.currencySymbol} "),
                      // Utiliser le symbole de la devise
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: 16),
                    // Dropdown pour sélectionner le compte source
                    if (_comptesBancairesUtilisateur.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Compte Source Principal',
                          border: OutlineInputBorder(), // Ajoute un style visuel
                        ),
                        value: _selectedCompteIdPourNouvelleEnveloppe,
                        hint: const Text('Sélectionner un compte'),
                        isExpanded: true,
                        items: _comptesBancairesUtilisateur.map((compte) {
                          return DropdownMenuItem<String>(
                            value: compte.id,
                            child: Text(compte.nom),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() { // Mettre à jour l'état du dialogue
                            _selectedCompteIdPourNouvelleEnveloppe = newValue;
                          });
                        },
                        validator: (value) { // Validation simple
                          if (value == null || value.isEmpty) {
                            return 'Veuillez sélectionner un compte source.';
                          }
                          return null;
                        },
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Chargement des comptes ou aucun compte disponible...",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.of(dialogContext).pop()),
                TextButton(
                    child: const Text('Ajouter'),
                    onPressed: () {
                      // Valider que le compte source est sélectionné
                      if (_selectedCompteIdPourNouvelleEnveloppe != null &&
                          _selectedCompteIdPourNouvelleEnveloppe!.isNotEmpty) {
                        _ajouterEnveloppe(categorie, dialogContext,
                            _selectedCompteIdPourNouvelleEnveloppe!);
                      } else {
                        // Afficher un message si aucun compte n'est sélectionné
                        // (ou utiliser la validation du DropdownButtonFormField)
                        if (mounted) { // Assurez-vous que le widget est toujours monté
                          ScaffoldMessenger
                              .of(this.context)
                              .showSnackBar( // Utiliser this.context pour le Scaffold principal
                            const SnackBar(content: Text(
                                'Veuillez sélectionner un compte source.')),
                          );
                        }
                      }
                    }),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _ajouterEnveloppe(Categorie categorie, BuildContext dialogContext) async {
    final nomEnveloppe = _nomEnveloppeController.text.trim();
    if (nomEnveloppe.isEmpty) {
      // ... (validation du nom)
      return;
    }
    if (_currentUser == null) {
      // ... (validation utilisateur)
      return;
    }

    final nouvelIdEnveloppe = _firestore.collection('temp').doc().id;

    final nouvelleEnveloppe = EnveloppeModel(
      id: nouvelIdEnveloppe,
      nom: nomEnveloppe,
      userId: _currentUser!.uid,
      categorieId: categorie.id,
      compteSourceAttacheId: null, // Initialement non lié
      couleurCompteSourceHex: null, // Initialement pas de couleur de compte
      soldeEnveloppe: 0.0,
      ordre: 0, // Ou une logique pour déterminer l'ordre
      typeObjectifString: TypeObjectif.aucun.name,
      dateCreation: Timestamp.now(),
      derniereModification: Timestamp.now(),
      // couleurThemeValue: null, // Ou une couleur par défaut si nécessaire à la création
    );

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('categories')
          .doc(categorie.id)
          .collection('enveloppes')
          .doc(nouvelIdEnveloppe)
          .set(nouvelleEnveloppe.toJson());

      Navigator.of(dialogContext).pop();
      _nomEnveloppeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enveloppe "$nomEnveloppe" ajoutée.')));
      }
    } catch (e) {
      print("Erreur ajout enveloppe: $e");
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'ajout: $e')));
      }
    }
  }

// TODO: Implémenter _modifierEnveloppe et _supprimerEnveloppe si nécessaire ici
// ou dans un écran de détail d'enveloppe.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Gérer le cas où l'utilisateur n'est pas (ou plus) connecté
    if (_currentUser == null &&
        mounted) { // Vérifier `mounted` au cas où l'état est disposé rapidement
      return Scaffold(
        appBar: AppBar(title: const Text('Budget - Catégories')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Vérification de l'authentification..."),
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Si ce message persiste, veuillez vous reconnecter."),
            ],
          ),
        ),
      );
    }
    // Si _currentUser est null mais que le widget n'est plus monté,
    // on ne devrait pas essayer de construire l'UI.
    // Cela peut arriver si l'état est disposé pendant une opération asynchrone.
    // Dans ce cas, retourner un conteneur vide est plus sûr.
    else if (_currentUser == null && !mounted) {
      return const SizedBox.shrink();
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget - Catégories'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nouvelle catégorie',
            onPressed: _afficherDialogueAjoutCategorie,
          ),
          IconButton(
            icon: const Icon(Icons.reorder),
            tooltip: 'Réorganiser',
            onPressed: _navigateToReorderScreen,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Widget pour afficher le total des objectifs mensuels
          StreamBuilder<List<EnveloppeModel>>(
            stream: _getAllEnveloppesAvecObjectifMensuelStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                // Optionnel: afficher un petit indicateur de chargement discret
                // return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                return const SizedBox
                    .shrink(); // Ou rien pendant le chargement initial
              }
              if (snapshot.hasError) {
                print("Erreur Stream Objectifs Mensuels: ${snapshot.error}");
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Erreur objectifs: ${snapshot.error}",
                      style: TextStyle(color: Colors.red)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                  child: Card(
                    elevation: 1.0,
                    color: theme.colorScheme.secondaryContainer.withOpacity(
                        0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Aucun objectif mensuel défini pour ${_getNomMoisActuel()}.',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ),
                );
              }

              double totalObjectifsMensuels = 0.0;
              for (var enveloppe in snapshot.data!) {
                if (enveloppe.objectifMontantPeriodique != null) {
                  totalObjectifsMensuels +=
                  enveloppe.objectifMontantPeriodique!;
                }
              }

              if (totalObjectifsMensuels == 0) {
                return const SizedBox
                  .shrink(); // Ne rien afficher si le total est 0
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                child: Card(
                  elevation: 2.0,
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Objectifs de ${_getNomMoisActuel()
                              .toUpperCase()}',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(totalObjectifsMensuels),
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getUserCategoriesCollection()
                  ?.orderBy('nom')
                  .snapshots(), // Ordonner par nom
              builder: (context, categorieSnapshot) {
                // Gestion explicite de l'état de connexion initiale sans données
                if (categorieSnapshot.connectionState ==
                    ConnectionState.waiting && !categorieSnapshot.hasData &&
                    !categorieSnapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (categorieSnapshot.hasError) {
                  print('Erreur Firestore Stream Catégories: ${categorieSnapshot
                      .error}');
                  return Center(child: Text('Erreur: ${categorieSnapshot
                      .error}. Vérifiez les logs.'));
                }
                if (!categorieSnapshot.hasData ||
                    categorieSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Aucune catégorie pour le moment.',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Créer une catégorie'),
                            onPressed: _afficherDialogueAjoutCategorie,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<Categorie> categories = categorieSnapshot.data!.docs
                    .map((doc) => Categorie.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categorie = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      // Espace entre les cartes de catégorie
                      child: Column( // Utiliser Column pour le titre et la liste des enveloppes
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre de la catégorie avec actions
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            margin: const EdgeInsets.only(
                                bottom: 4.0, left: 4.0, right: 4.0),
                            // Légère marge pour le titre
                            // decoration: BoxDecoration( // Optionnel: style pour le titre
                            //   border: Border(bottom: BorderSide(color: theme.dividerColor)),
                            // ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    categorie.nom.toUpperCase(),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme
                                          .primary, // Couleur distinctive pour le titre
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.add_circle,
                                          color: theme.colorScheme.secondary),
                                      tooltip: 'Ajouter une enveloppe à ${categorie
                                          .nom}',
                                      onPressed: () =>
                                          _afficherDialogueAjoutEnveloppe(
                                              categorie),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets
                                          .zero, // Réduire le padding par défaut
                                    ),
                                    const SizedBox(width: 4),
                                    // Espace entre les icônes
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert,
                                          color: theme.colorScheme
                                              .onSurfaceVariant),
                                      tooltip: 'Options pour ${categorie.nom}',
                                      onSelected: (String value) {
                                        if (value == 'modifier_cat') {
                                          _afficherDialogueModificationCategorie(
                                              categorie);
                                        } else if (value == 'supprimer_cat') {
                                          _confirmerSuppressionCategorie(
                                              categorie);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'modifier_cat',
                                          child: ListTile(
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('Modifier'),
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'supprimer_cat',
                                          child: ListTile(
                                            leading: Icon(Icons.delete_outline,
                                                color: Colors.red),
                                            title: Text('Supprimer',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // StreamBuilder pour les enveloppes de cette catégorie
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _getUserCategoriesCollection()
                                ?.doc(categorie.id)
                                .collection('enveloppes')
                                .orderBy(
                                'ordre') // TODO: ou 'nom' si vous préférez
                                .snapshots(),
                            builder: (context, enveloppeSnapshot) {
                              if (enveloppeSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                                  !enveloppeSnapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(child: SizedBox(width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.0))),
                                );
                              }
                              if (enveloppeSnapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      'Erreur chargement enveloppes: ${enveloppeSnapshot
                                          .error}',
                                      style: TextStyle(color: Colors.red)),
                                );
                              }
                              if (!enveloppeSnapshot.hasData ||
                                  enveloppeSnapshot.data!.docs.isEmpty) {
                                return Card(
                                  elevation: 0.5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: ListTile(
                                    title: Text(
                                        'Aucune enveloppe dans "${categorie
                                            .nom}".', style: TextStyle(
                                        fontStyle: FontStyle.italic)),
                                    dense: true,
                                    leading: Icon(Icons.inbox_outlined,
                                        color: theme.disabledColor),
                                  ),
                                );
                              }

                              final enveloppes = enveloppeSnapshot.data!.docs
                                  .map((doc) =>
                                  EnveloppeModel.fromSnapshot(doc))
                                  .toList();

                              return ListView.builder(
                                shrinkWrap: true,
                                // Important dans un ListView parent
                                physics: const NeverScrollableScrollPhysics(),
                                // Important dans un ListView parent
                                itemCount: enveloppes.length,
                                itemBuilder: (context, envIndex) {
                                  final enveloppe = enveloppes[envIndex];
                                  final couleurThemeEnveloppe = enveloppe
                                      .couleurThemeValue != null ? Color(
                                      enveloppe.couleurThemeValue!) : theme
                                      .colorScheme.surfaceContainerHighest;

                                  return Card(
                                    elevation: 1.0,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    color: couleurThemeEnveloppe.withOpacity(
                                        0.15),
                                    // Légère couleur de fond
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: couleurThemeEnveloppe,
                                          width: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      title: Text(
                                        enveloppe.nom,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        'Alloué: ${currencyFormatter.format(
                                            enveloppe
                                                .soldeEnveloppe)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      trailing: _buildTrailingWidgetForEnveloppeModel(
                                          enveloppe, theme),
                                      onTap: () {
                                        print(
                                            'Détail de l\'enveloppe ${enveloppe
                                                .nom}');
                                        // TODO: Naviguer vers l'écran de détail/modification de l'enveloppe
                                        // Passer categorie.id et enveloppe.id
                                        ScaffoldMessenger
                                            .of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(
                                              'Navigation vers le détail de ${enveloppe
                                                  .nom} non implémentée.')),
                                        );
                                      },
                                      // onLongPress: () { /* Pourrait ouvrir un menu d'options pour l'enveloppe */ },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (index < categories.length -
                              1) // Ne pas ajouter de Divider après le dernier item
                            Divider(height: 16,
                                thickness: 1,
                                indent: 8,
                                endIndent: 8,
                                color: theme.dividerColor.withOpacity(0.5)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}