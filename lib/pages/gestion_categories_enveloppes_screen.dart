import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour NumberFormat et DateFormat
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// TODO: Vérifiez et ajustez ces chemins d'importation selon la structure de votre projet
import 'package:toutie_budget/models/categorie_model.dart'; // Si CategorieModel est utilisé
import '../models/enveloppe_model.dart'; // Pour EnveloppeModel
// import 'package:toutie_budget/models/compte_bancaire_model.dart'; // Si vous avez un CompteBancaireModel externe

// Si TypeObjectif n'est pas déjà défini dans un modèle importé
enum TypeObjectif {
  aucun,
  mensuel,
  dateFixe,
}

// Modèle local pour CompteBancaireModel, si vous ne l'importez pas.
// Si vous l'importez, supprimez cette définition locale.
class CompteBancaireModel {
  final String id;
  final String nom;

  // final String? couleurHex; // Optionnel

  CompteBancaireModel({required this.id, required this.nom /*, this.couleurHex*/
  });

  factory CompteBancaireModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour le compte ID: ${doc.id}');
    }
    return CompteBancaireModel(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Compte inconnu',
      // couleurHex: data['couleurHex'] as String?,
    );
  }
}

// Modèle local pour Categorie. Si vous utilisez CategorieModel de votre fichier importé,
// assurez-vous que les types correspondent ou ajustez.
class Categorie {
  String id;
  String nom;

  // int ordre; // Si utilisé

  Categorie({
    required this.id,
    required this.nom,
    // this.ordre = 0,
  });

  factory Categorie.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour la catégorie ID: ${doc.id}');
    }
    return Categorie(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom non défini',
      // ordre: data['ordre'] as int? ?? 0,
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
      locale: 'fr_CA', symbol: '\$'); // Formatage monétaire
  final TextEditingController _nomCategorieController = TextEditingController();
  final TextEditingController _nomEnveloppeController = TextEditingController();

  // SUPPRIMÉ: // final TextEditingController _montantInitialEnveloppeController = TextEditingController();

  List<CompteBancaireModel> _comptesBancairesUtilisateur = [];

  // SUPPRIMÉ: // String? _selectedCompteIdPourNouvelleEnveloppe;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      print("ERREUR: Utilisateur non connecté sur l'écran de gestion.");
      // Optionnel: Gérer la redirection ou afficher un message persistant
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Utilisateur non connecté. Veuillez vous reconnecter.'),
                duration: Duration(seconds: 5)),
          );
          // Exemple: Navigator.of(context).pushReplacementNamed('/ecran_connexion');
        }
      });
    } else {
      _chargerComptesBancaires(); // Utile si vous avez d'autres fonctionnalités utilisant les comptes
    }
  }

  @override
  void dispose() {
    _nomCategorieController.dispose();
    _nomEnveloppeController.dispose();
    // SUPPRIMÉ: // _montantInitialEnveloppeController.dispose();
    super.dispose();
  }

  Future<void> _chargerComptesBancaires() async {
    if (_currentUser == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection(
          'comptes') // Assurez-vous que le nom de la collection est correct
          .get();
      if (mounted) {
        setState(() {
          _comptesBancairesUtilisateur = snapshot.docs
              .map((doc) => CompteBancaireModel.fromSnapshot(doc))
              .toList();
        });
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

  // --- Fonctions utilitaires diverses ---
  String _getNomMoisActuel() {
    // S'assure que 'fr_FR' est initialisé si nécessaire (main.dart)
    // await initializeDateFormatting('fr_FR', null);
    return DateFormat('MMMM', 'fr_FR').format(DateTime.now());
  }

  Stream<List<EnveloppeModel>> _getAllEnveloppesAvecObjectifMensuelStream() {
    if (_currentUser == null) return Stream.value([]);
    return _firestore
        .collectionGroup(
        'enveloppes') // Requête sur toutes les collections 'enveloppes'
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('typeObjectifString', isEqualTo: TypeObjectif.mensuel.name)
    // Ajoutez d'autres filtres ou tris si nécessaire
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => EnveloppeModel.fromSnapshot(doc))
            .toList());
  }

  // Fonction pour afficher le widget trailing d'une enveloppe (objectif, etc.)
  // Cette fonction était dans votre code d'origine, je la conserve.
  // Adaptez-la si EnveloppeModel a changé ou si vous ne l'utilisez plus.
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
            enveloppe.objectifDateEcheance!.toDate())}';
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
          // Naviguer vers un écran de définition/modification d'objectif
          print('Naviguer pour définir/modifier l\'objectif pour ${enveloppe
              .nom}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Définition d\'objectif pour ${enveloppe
                  .nom} non implémentée.')),
            );
          }
        },
        child: Text('Ajouter objectif', style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: theme.textTheme.bodySmall?.fontSize)),
      );
    }
  }

  void _navigateToReorderScreen() {
    // Naviguer vers l'écran de réorganisation
    print('Navigation vers la page de réorganisation demandée.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Page de réorganisation non implémentée.')),
      );
    }
  }

  // --- Gestion des Catégories (Dialogues et Actions Firestore) ---

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
              onPressed: () {
                final nomCategorie = _nomCategorieController.text.trim();
                if (nomCategorie.isNotEmpty) {
                  _ajouterCategorie(dialogContext);
                } else {
                  if (mounted) { // Assurez-vous que le widget est toujours monté
                    ScaffoldMessenger
                        .of(dialogContext)
                        .showSnackBar( // Utilisez dialogContext ici
                      const SnackBar(content: Text(
                          "Le nom de la catégorie ne peut pas être vide.")),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _ajouterCategorie(BuildContext dialogContext) async {
    final nomCategorie = _nomCategorieController.text.trim();
    // La vérification de nom vide est déjà faite avant d'appeler cette méthode

    final userCategoriesCollection = _getUserCategoriesCollection();
    if (userCategoriesCollection == null) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar( // Utilisez dialogContext ici
                content: Text(
                    'Utilisateur non authentifié. Impossible d\'ajouter la catégorie.')));
      }
      return;
    }

    try {
      // Optionnel: ajouter un champ 'ordre' ou 'dateCreation'
      await userCategoriesCollection.add({
        'nom': nomCategorie,
        'ordre': 0, // Exemple
        'dateCreation': Timestamp.now(), // Exemple
      });
      Navigator.of(dialogContext).pop(); // Ferme le dialogue
      _nomCategorieController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catégorie "$nomCategorie" ajoutée.')),
        );
      }
    } catch (e) {
      print("Erreur ajout catégorie: $e");
      if (mounted) {
        ScaffoldMessenger
            .of(dialogContext)
            .showSnackBar( // Utilisez dialogContext ici
          SnackBar(
              content: Text('Erreur lors de l\'ajout de la catégorie: $e')),
        );
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
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _nomCategorieController
                    .clear(); // Important pour la prochaine ouverture
              },
            ),
            TextButton(
              child: const Text('Sauvegarder'),
              onPressed: () async {
                final nouveauNom = _nomCategorieController.text.trim();
                if (nouveauNom.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Le nom ne peut pas être vide.')));
                  }
                  return; // Ne pas fermer, laisser l'utilisateur corriger
                }
                if (nouveauNom == categorie.nom) {
                  Navigator.of(dialogContext).pop(); // Pas de changement
                  _nomCategorieController.clear();
                  return;
                }

                final categoryDocRef = _getUserCategoryDoc(categorie.id);
                if (categoryDocRef == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Utilisateur non authentifié.')));
                  }
                  // Navigator.of(dialogContext).pop(); // Pas nécessaire de pop si le doc ref est null
                  return;
                }
                try {
                  await categoryDocRef.update({'nom': nouveauNom});
                  Navigator.of(dialogContext).pop();
                  _nomCategorieController.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                          'Catégorie renommée en "$nouveauNom".')),
                    );
                  }
                } catch (e) {
                  print("Erreur modification catégorie: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Erreur de modification: $e')),
                    );
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
          content: Text(
              'Supprimer la catégorie "${categorie
                  .nom}" et toutes ses enveloppes ? Cette action est irréversible.'),
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
                  // Navigator.of(dialogContext).pop(); // Pas nécessaire si erreur avant action
                  return;
                }
                try {
                  // Supprimer d'abord les enveloppes dans la sous-collection
                  final enveloppesSnapshot = await categoryDocRef.collection(
                      'enveloppes').get();
                  WriteBatch batch = _firestore.batch();
                  for (DocumentSnapshot doc in enveloppesSnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  // Ensuite, supprimer la catégorie elle-même
                  await categoryDocRef.delete();

                  Navigator
                      .of(dialogContext)
                      .pop(); // Fermer le dialogue de confirmation
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Catégorie "${categorie
                                  .nom}" et ses enveloppes supprimées.')),
                    );
                  }
                } catch (e) {
                  print("Erreur suppression catégorie: $e");
                  // Il est possible que le dialogue soit déjà fermé si l'erreur survient après le pop
                  // Donc, utiliser le context principal pour ce snackbar d'erreur
                  if (mounted) {
                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar( // Changé pour context principal
                      SnackBar(content: Text('Erreur de suppression: $e')),
                    );
                  }
                  // S'assurer que le dialogue est fermé en cas d'erreur avant le pop initial
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Gestion des Enveloppes (Dialogues et Actions Firestore) ---

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
    // SUPPRIMÉ: _montantInitialEnveloppeController.clear();
    // SUPPRIMÉ: _selectedCompteIdPourNouvelleEnveloppe = null;

    // SUPPRIMÉ: La vérification _comptesBancairesUtilisateur.isEmpty et le code associé
    // car le Dropdown des comptes a été retiré.

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Le StatefulBuilder n'est plus nécessaire car il n'y a plus d'état interne (comme le dropdown) à gérer dans le dialogue.
        return AlertDialog(
          title: Text('Nouvelle Enveloppe pour "${categorie.nom}"'),
          content: SingleChildScrollView(
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
                // SUPPRIMÉ: SizedBox et TextField pour le montant initial
                // SUPPRIMÉ: SizedBox et DropdownButtonFormField pour la sélection du compte
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
                  final nomEnveloppe = _nomEnveloppeController.text.trim();
                  if (nomEnveloppe.isNotEmpty) {
                    // MODIFIÉ: Appel de _ajouterEnveloppe sans le compteIdSelectionne et montantInitial
                    _ajouterEnveloppe(categorie, dialogContext);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text(
                            'Veuillez saisir un nom pour l\'enveloppe.')),
                      );
                    }
                  }
                }),
          ],
        );
      },
    );
  }

  Future<void> _ajouterEnveloppe(Categorie categorie,
      BuildContext dialogContext,
      // SUPPRIMÉ: Pas besoin de compteIdSelectionne ni de montantInitialController ici
      ) async {
    final nomEnveloppe = _nomEnveloppeController.text.trim();
    // La vérification de nom vide est déjà faite avant d'appeler cette méthode

    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
                content: Text(
                    'Utilisateur non connecté. Impossible d\'ajouter l\'enveloppe.')));
      }
      return;
    }

    final nouvelIdEnveloppe = _firestore
        .collection('temp')
        .doc()
        .id; // Génère un ID unique côté client

    // MODIFIÉ: Le montant initial est toujours 0.0 et pas de compte source
    final nouvelleEnveloppe = EnveloppeModel(
      id: nouvelIdEnveloppe,
      nom: nomEnveloppe,
      userId: _currentUser!.uid,
      categorieId: categorie.id,
      compteSourceAttacheId: null,
      // MODIFIÉ: Toujours null
      couleurCompteSourceHex: null,
      // MODIFIÉ: Toujours null (ou votre valeur par défaut si applicable)
      soldeEnveloppe: 0.0,
      // MODIFIÉ: Solde initial toujours 0.0
      ordre: 0,
      // Vous pouvez implémenter une logique d'ordre si nécessaire
      typeObjectifString: TypeObjectif.aucun.name,
      // Valeur par défaut
      objectifMontantPeriodique: null,
      objectifDateEcheance: null,
      dateCreation: Timestamp.now(),
      derniereModification: Timestamp.now(),
      // Assurez-vous que tous les champs requis par votre EnveloppeModel.toJson() sont ici
    );

    try {
      await _getUserCategoryDoc(
          categorie.id)! // Le '!' est utilisé car on a vérifié _currentUser
          .collection('enveloppes')
          .doc(nouvelIdEnveloppe) // Utilise l'ID généré
          .set(nouvelleEnveloppe.toJson());

      Navigator.of(dialogContext).pop(); // Ferme le dialogue
      _nomEnveloppeController.clear();
      // SUPPRIMÉ: _montantInitialEnveloppeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                '"$nomEnveloppe" créez avec succès.')));
      }
    } catch (e) {
      print("Erreur ajout enveloppe: $e");
      if (mounted) {
        ScaffoldMessenger
            .of(dialogContext)
            .showSnackBar( // Utiliser dialogContext pour le SnackBar d'erreur du dialogue
            SnackBar(
                content: Text('Erreur lors de l\'ajout de l\'enveloppe: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      // Afficher un état de chargement/erreur si l'utilisateur n'est pas connecté
      // Cet état peut être amélioré pour être plus informatif.
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
            onPressed: _navigateToReorderScreen, // Implémentez cette navigation
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Widget pour afficher le total des objectifs mensuels (si utilisé)
          StreamBuilder<List<EnveloppeModel>>(
            stream: _getAllEnveloppesAvecObjectifMensuelStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SizedBox
                    .shrink(); // ou un petit indicateur de chargement
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
          // Liste principale des catégories et de leurs enveloppes
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getUserCategoriesCollection()
                  ?.orderBy('nom') // ou 'ordre' si vous l'utilisez
                  .snapshots(),
              builder: (context, categorieSnapshot) {
                if (categorieSnapshot.connectionState ==
                    ConnectionState.waiting && !categorieSnapshot.hasData &&
                    !categorieSnapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (categorieSnapshot.hasError) {
                  print('Erreur Firestore Stream Catégories: ${categorieSnapshot
                      .error}');
                  return Center(
                      child: Text(
                          'Erreur: ${categorieSnapshot
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
                    final categorieCourante = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      // Espace entre les catégories
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Entête de la catégorie
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            margin: const EdgeInsets.only(
                                bottom: 4.0, left: 4.0, right: 4.0),
                            // decoration: BoxDecoration( ... ), // Style optionnel
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    categorieCourante.nom.toUpperCase(),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
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
                                      tooltip:
                                      'Ajouter une enveloppe à ${categorieCourante
                                          .nom}',
                                      onPressed: () =>
                                          _afficherDialogueAjoutEnveloppe(
                                              categorieCourante),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert,
                                          color: theme
                                              .colorScheme.onSurfaceVariant),
                                      tooltip:
                                      'Options pour ${categorieCourante.nom}',
                                      onSelected: (String value) {
                                        if (value == 'modifier_cat') {
                                          _afficherDialogueModificationCategorie(
                                              categorieCourante);
                                        } else if (value == 'supprimer_cat') {
                                          _confirmerSuppressionCategorie(
                                              categorieCourante);
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
                                            leading: Icon(
                                                Icons.delete_outline,
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
                          // Liste des enveloppes pour cette catégorie
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _getUserCategoriesCollection()
                                ?.doc(categorieCourante.id)
                                .collection('enveloppes')
                                .orderBy(
                                'ordre') // ou 'nom', selon votre modèle EnveloppeModel
                                .snapshots(),
                            builder: (context, enveloppeSnapshot) {
                              if (enveloppeSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                                  !enveloppeSnapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                      child: SizedBox(
                                          width: 16,
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
                                        'Aucune enveloppe dans "${categorieCourante
                                            .nom}".',
                                        style: TextStyle(
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
                                physics:
                                const NeverScrollableScrollPhysics(),
                                // Important pour ListView dans Column
                                itemCount: enveloppes.length,
                                itemBuilder: (context, envIndex) {
                                  final enveloppe = enveloppes[envIndex];
                                  final couleurThemeEnveloppe = enveloppe
                                      .couleurThemeValue != null ? Color(
                                      enveloppe.couleurThemeValue!) : theme
                                      .colorScheme
                                      .surfaceContainerHighest; // Couleur par défaut

                                  return Card(
                                    elevation: 1.0,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    // Utilisation d'une couleur de fond légère basée sur couleurThemeEnveloppe
                                    color: couleurThemeEnveloppe.withOpacity(
                                        0.15),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: couleurThemeEnveloppe,
                                          width: 0.5), // Bordure subtile
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      leading: Icon(Icons.wallet_outlined,
                                          color: couleurThemeEnveloppe),
                                      // Icône d'enveloppe
                                      title: Text(enveloppe.nom,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                              fontWeight: FontWeight.w500)),
                                      subtitle: enveloppe.soldeEnveloppe == 0.0
                                          ? null // Ne rien afficher si le solde est de 0
                                          : Text(
                                        'Solde: ${currencyFormatter.format(enveloppe.soldeEnveloppe)}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      trailing: _buildTrailingWidgetForEnveloppeModel(
                                          enveloppe, theme),
                                      // Widget pour afficher l'objectif
                                      onTap: () {
                                        // TODO: Naviguer vers les détails de l'enveloppe ou une action
                                        print('Enveloppe "${enveloppe
                                            .nom}" cliquée.');
                                        // Navigator.push(context, MaterialPageRoute(builder: (context) => DetailEnveloppeScreen(enveloppe: enveloppe)));
                                      },
                                      onLongPress: () {
                                        // TODO: Afficher un menu contextuel pour l'enveloppe (modifier, supprimer, etc.)
                                        print(
                                            'Long press sur l\'enveloppe "${enveloppe
                                                .nom}"');
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (index < categories.length -
                              1) // Ajoute un séparateur entre les catégories sauf pour la dernière
                            Divider(height: 16,
                                thickness: 0.5,
                                indent: 8,
                                endIndent: 8),

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