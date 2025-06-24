import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NOUVEL IMPORT

// ASSUREZ-VOUS QUE CE CHEMIN EST CORRECT ET QUE EnveloppeTestData a toMap et fromMap
// import '../widgets/EnveloppeCard.dart'; // Ou là où EnveloppeTestData est définie
// import '../models/enveloppe_test_data.dart'; // Si vous l'avez dans un dossier models

// Enum TypeObjectif (si pas déjà importé avec EnveloppeTestData)
enum TypeObjectif {
  aucun,
  mensuel,
  dateFixe
} // Assurez-vous que c'est le bon enum

// --- Définition des classes Categorie et EnveloppeTestData ---
class Categorie {
  String id;
  String nom;
  List<EnveloppeTestData> enveloppes;

  Categorie({
    required this.id,
    required this.nom,
    List<EnveloppeTestData>? enveloppes,
  }) : enveloppes = enveloppes ?? [];

  factory Categorie.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour la catégorie ID: ${doc.id}');
    }
    return Categorie(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom non défini',
      enveloppes: (data['enveloppes'] as List<dynamic>? ?? [])
          .map((item) =>
          EnveloppeTestData.fromMap(
              item as Map<String, dynamic>)) // Utilise fromMap
          .toList(),
    );
  }
}

class EnveloppeTestData {
  String id;
  String nom;
  double soldeActuel;
  double montantAlloue;
  TypeObjectif typeObjectif;
  double? montantCible;
  int couleurThemeValue;
  int couleurSoldeCompteValue;
  DateTime? dateCible; // Exemple d'ajout, adaptez si nécessaire
  int? iconeCodePoint; // Exemple d'ajout

  EnveloppeTestData({
    required this.id,
    required this.nom,
    this.soldeActuel = 0.0,
    this.montantAlloue = 0.0,
    this.typeObjectif = TypeObjectif.aucun,
    this.montantCible,
    required this.couleurThemeValue,
    required this.couleurSoldeCompteValue,
    this.dateCible,
    this.iconeCodePoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // IMPORTANT: l'ID doit être dans la map
      'nom': nom,
      'soldeActuel': soldeActuel,
      'montantAlloue': montantAlloue,
      'typeObjectif': typeObjectif.name,
      // Utilise .name pour les enums (plus sûr)
      'montantCible': montantCible,
      'couleurThemeValue': couleurThemeValue,
      'couleurSoldeCompteValue': couleurSoldeCompteValue,
      'dateCible': dateCible != null ? Timestamp.fromDate(dateCible!) : null,
      'iconeCodePoint': iconeCodePoint,
    };
  }

  factory EnveloppeTestData.fromMap(Map<String, dynamic> map) {
    return EnveloppeTestData(
      id: map['id'] as String? ?? DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      nom: map['nom'] as String? ?? '',
      soldeActuel: (map['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      montantAlloue: (map['montantAlloue'] as num?)?.toDouble() ?? 0.0,
      typeObjectif: TypeObjectif.values.firstWhere(
            (e) => e.name == map['typeObjectif'],
        orElse: () => TypeObjectif.aucun,
      ),
      montantCible: (map['montantCible'] as num?)?.toDouble(),
      couleurThemeValue: map['couleurThemeValue'] as int? ?? Colors.blue.value,
      couleurSoldeCompteValue: map['couleurSoldeCompteValue'] as int? ??
          Colors.grey.value,
      dateCible: (map['dateCible'] as Timestamp?)?.toDate(),
      iconeCodePoint: map['iconeCodePoint'] as int?,
    );
  }
}
// --- Fin des définitions de classes ---

class GestionCategoriesEnveloppesScreen extends StatefulWidget {
  const GestionCategoriesEnveloppesScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      print("ERREUR: Utilisateur non connecté sur l'écran de gestion.");
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   if (mounted) {
      //     Navigator.of(context).pushReplacementNamed('/login');
      //   }
      // });
    }
  }

  @override
  void dispose() {
    _nomCategorieController.dispose();
    _nomEnveloppeController.dispose();
    super.dispose();
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

  double _calculerTotalObjectifsMensuels(List<Categorie> categories) {
    double total = 0.0;
    for (var categorie in categories) {
      for (var enveloppe in categorie.enveloppes) {
        if (enveloppe.typeObjectif == TypeObjectif.mensuel &&
            enveloppe.montantCible != null) {
          total += enveloppe.montantCible!;
        }
      }
    }
    return total;
  }

  String _getNomMoisActuel() {
    return DateFormat('MMMM', 'fr_FR').format(DateTime.now());
  }

  Widget _buildTrailingWidgetForEnveloppe(EnveloppeTestData enveloppe,
      ThemeData theme) {
    bool aUnObjectifDefini = enveloppe.typeObjectif != TypeObjectif.aucun &&
        enveloppe.montantCible != null &&
        enveloppe.montantCible! > 0;

    if (aUnObjectifDefini) {
      String objectifStr = 'Obj: ${currencyFormatter.format(
          enveloppe.montantCible)}';
      if (enveloppe.typeObjectif == TypeObjectif.mensuel) {
        objectifStr += '/mois';
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Définition d\'objectif pour ${enveloppe
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
  }
  // --- Poursuite de _GestionCategoriesEnveloppesScreenState ---

// --- Gestion des Catégories ---
  void _afficherDialogueAjoutCategorie() {
    if (_currentUser == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour ajouter une catégorie.')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nom de la catégorie ne peut pas être vide.')));
      return;
    }

    final userCategoriesCollection = _getUserCategoriesCollection();
    if (userCategoriesCollection == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur non authentifié. Impossible d\'ajouter.')));
      Navigator.of(dialogContext).pop();
      return;
    }

    try {
      await userCategoriesCollection.add({
        'nom': nomCategorie,
        'enveloppes': [],
      });
      Navigator.of(dialogContext).pop();
      _nomCategorieController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Catégorie "$nomCategorie" ajoutée.')));
    } catch (e) {
      print("Erreur ajout catégorie: $e");
      if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout: $e')));
    }
  }

  void _afficherDialogueModificationCategorie(Categorie categorie) {
    if (_currentUser == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour modifier.')));
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
              onPressed: () { Navigator.of(dialogContext).pop(); _nomCategorieController.clear(); },
            ),
            TextButton(
              child: const Text('Sauvegarder'),
              onPressed: () async {
                final nouveauNom = _nomCategorieController.text.trim();
                if (nouveauNom.isEmpty) return;

                final categoryDocRef = _getUserCategoryDoc(categorie.id);
                if (categoryDocRef == null) {
                  if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Utilisateur non authentifié.')));
                  Navigator.of(dialogContext).pop();
                  return;
                }
                try {
                  await categoryDocRef.update({'nom': nouveauNom});
                  Navigator.of(dialogContext).pop();
                  _nomCategorieController.clear();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Catégorie renommée en "$nouveauNom".')));
                } catch (e) {
                  print("Erreur modification catégorie: $e");
                  if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur de modification: $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour supprimer.')));
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Supprimer la catégorie "${categorie.nom}" et toutes ses enveloppes ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () async {
                final categoryDocRef = _getUserCategoryDoc(categorie.id);
                if (categoryDocRef == null) {
                  if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Utilisateur non authentifié.')));
                  Navigator.of(dialogContext).pop();
                  return;
                }
                try {
                  await categoryDocRef.delete();
                  Navigator.of(dialogContext).pop();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Catégorie "${categorie.nom}" supprimée.')));
                } catch (e) {
                  print("Erreur suppression catégorie: $e");
                  Navigator.of(dialogContext).pop();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de suppression: $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour ajouter une enveloppe.')));
      return;
    }
    _nomEnveloppeController.clear();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Nouvelle Enveloppe pour "${categorie.nom}"'),
          content: TextField(
            controller: _nomEnveloppeController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nom de l'enveloppe"),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: <Widget>[
            TextButton(child: const Text('Annuler'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(child: const Text('Ajouter'), onPressed: () => _ajouterEnveloppe(categorie, dialogContext)),
          ],
        );
      },
    );
  }

  Future<void> _ajouterEnveloppe(Categorie categorie, BuildContext dialogContext) async {
    final nomEnveloppe = _nomEnveloppeController.text.trim();
    if (nomEnveloppe.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le nom de l'enveloppe ne peut pas être vide.")));
      return;
    }

    final categoryDocRef = _getUserCategoryDoc(categorie.id);
    if (categoryDocRef == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur non authentifié.')));
      Navigator.of(dialogContext).pop();
      return;
    }

    int defaultColorValue = Colors.blueGrey.value; // Une couleur par défaut plus neutre
    // Vous pouvez ajouter une logique plus avancée pour choisir une couleur,
    // par exemple, en fonction des enveloppes existantes ou un sélecteur de couleur.

    final nouvelleEnveloppe = EnveloppeTestData(
      id: DateTime.now().millisecondsSinceEpoch.toString() + nomEnveloppe.hashCode.toString(), // Un peu plus unique, mais UUID est mieux
      nom: nomEnveloppe,
      soldeActuel: 0.0,
      montantAlloue: 0.0,
      typeObjectif: TypeObjectif.aucun,
      couleurThemeValue: defaultColorValue,
      couleurSoldeCompteValue: defaultColorValue,
    );

    try {
      await categoryDocRef.update({
        'enveloppes': FieldValue.arrayUnion([nouvelleEnveloppe.toMap()])
      });
      Navigator.of(dialogContext).pop();
      _nomEnveloppeController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enveloppe "$nomEnveloppe" ajoutée à "${categorie.nom}".')));
    } catch (e) {
      print("Erreur ajout enveloppe: $e");
      if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout de l\'enveloppe: $e')));
    }
  }

// TODO: Implémenter _modifierEnveloppe et _supprimerEnveloppe

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget - Catégories')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Vérification de l'authentification..."),
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
            onPressed: _navigateToReorderScreen,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getUserCategoriesCollection()?.orderBy('nom').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Erreur Firestore Stream: ${snapshot.error}');
            return Center(child: Text('Erreur: ${snapshot.error}. Vérifiez les logs.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Aucune catégorie pour le moment.', style: TextStyle(fontSize: 18)),
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

          final List<Categorie> categories = snapshot.data!.docs
              .map((doc) => Categorie.fromFirestore(doc))
              .toList();

          final String nomMoisActuel = _getNomMoisActuel();
          final double totalObjectifsMensuels = _calculerTotalObjectifsMensuels(categories);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (totalObjectifsMensuels > 0 || categories.any((cat) => cat.enveloppes.any((env) => env.typeObjectif == TypeObjectif.mensuel)))
                Padding(
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
                            'Total Objectifs de ${nomMoisActuel.toUpperCase()}',
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
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(8.0).copyWith(
                      top: (totalObjectifsMensuels > 0 || categories.any((cat) => cat.enveloppes.any((env) => env.typeObjectif == TypeObjectif.mensuel))) ? 8.0 : 12.0,
                      bottom: 80.0), // Espace pour un éventuel FAB
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categorie = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    categorie.nom.toUpperCase(),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                                      tooltip: 'Ajouter une enveloppe à ${categorie.nom}',
                                      onPressed: () => _afficherDialogueAjoutEnveloppe(categorie),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (String value) {
                                        if (value == 'edit') _afficherDialogueModificationCategorie(categorie);
                                        else if (value == 'delete') _confirmerSuppressionCategorie(categorie);
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem<String>(value: 'edit', child: Text('Modifier nom')),
                                        const PopupMenuItem<String>(value: 'delete', child: Text('Supprimer catégorie')),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Card(
                            elevation: 2.0,
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                if (categorie.enveloppes.isNotEmpty)
                                  ...categorie.enveloppes.asMap().entries.map((entry) {
                                    EnveloppeTestData enveloppe = entry.value;
                                    return Column(
                                      children: [


                                        ListTile(
                                          leading: enveloppe.iconeCodePoint != null
                                              ? Icon(IconData(enveloppe.iconeCodePoint!, fontFamily: 'MaterialIcons'), color: Color(enveloppe.couleurThemeValue))
                                              : null, // Ajoutez une icône si disponible
                                          title: Text(enveloppe.nom),
                                          // subtitle: Text('Solde: ${currencyFormatter.format(enveloppe.soldeActuel)}'), // LIGNE SUPPRIMÉE OU COMMENTÉE
                                          trailing: _buildTrailingWidgetForEnveloppe(enveloppe, theme),
                                          onTap: () {
                                            print('Action pour enveloppe ${enveloppe.nom} (ID: ${enveloppe.id})');
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gestion de l\'enveloppe ${enveloppe.nom} non implémentée.')));
                                          },



                                          // TODO: Ajouter onLongPress pour modifier/supprimer enveloppe ici
                                        ),
                                        if (entry.key < categorie.enveloppes.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                                      ],
                                    );
                                  }).toList()
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                                    alignment: Alignment.center,
                                    child: const Text('Aucune enveloppe. Cliquez sur + pour en ajouter.', style: TextStyle(fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} // Fin de la classe _GestionCategoriesEnveloppesScreenState