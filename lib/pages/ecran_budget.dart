import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toutie_budget/models/compte_model.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart'; // VÉRIFIEZ CE CHEMIN
import 'package:toutie_budget/widgets/transactions_review_banner.dart';
import 'package:toutie_budget/widgets/budget_categories_list.dart';

class EcranBudget extends StatefulWidget {
  const EcranBudget({super.key});

  @override
  State<EcranBudget> createState() => _EcranBudgetState();
}

class _EcranBudgetState extends State<EcranBudget> {
  DateTime _moisAnneeCourant = DateTime(DateTime
      .now()
      .year, DateTime
      .now()
      .month, 1);
  User? _currentUser;
  bool _isLoading = true; // Pour les données non-streamées (catégories, nombre à revoir)

  Stream<List<Compte>>? _comptesStream;

  int _nombreTransactionsARevoir = 0;
  List<CategorieBudgetModel> _categoriesDuBudget = [];

  // _etatsDepliageCategories a été supprimé d'ici

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _comptesStream = _getComptesStream();
    }
    _chargerDonneesBudgetNonStream();
  }

  Stream<List<Compte>>? _getComptesStream() {
    if (_currentUser == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('comptes')
        .orderBy('nom')
        .snapshots()
        .map((querySnapshot) {
      print(
          "Mise à jour du stream des comptes reçue. Nombre de documents: ${querySnapshot
              .docs.length}");
      final comptes = querySnapshot.docs.map((doc) {
        try {
          return Compte.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>);
        } catch (e, stacktrace) {
          print("Stream - ERREUR lors du mapping du document ${doc.id}: $e");
          print("Stream - Stacktrace: $stacktrace");
          return null;
        }
      }).whereType<Compte>().toList();
      return comptes;
    });
  }

  Future<void> _chargerDonneesBudgetNonStream() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Simuler un délai de chargement
    await Future.delayed(const Duration(milliseconds: 500));

    // Simuler des données
    _nombreTransactionsARevoir = 2; // Exemple
    _categoriesDuBudget = [
      CategorieBudgetModel(
        id: 'cat1',
        nom: 'Alimentation',
        couleur: Colors.orangeAccent,
        alloueTotal: 500,
        depenseTotal: 250,
        disponibleTotal: 250,
        info: 'Budget mensuel pour les courses',
        enveloppes: [
          EnveloppeModel(id: 'env1_1',
              nom: 'Supermarché',
              couleur: Colors.orange[700],
              montantAlloue: 400,
              depense: 200,
              disponible: 200,
              icone: Icons.shopping_cart),
          EnveloppeModel(id: 'env1_2',
              nom: 'Restaurants',
              montantAlloue: 100,
              depense: 50,
              disponible: 50,
              icone: Icons.restaurant),
        ],
      ),
      CategorieBudgetModel(
        id: 'cat2',
        nom: 'Transport',
        couleur: Colors.lightBlueAccent,
        alloueTotal: 150,
        depenseTotal: 70,
        disponibleTotal: 80,
        info: 'Carburant et entretien',
        enveloppes: [
          EnveloppeModel(id: 'env2_1',
              nom: 'Essence',
              montantAlloue: 100,
              depense: 70,
              disponible: 30,
              icone: Icons.local_gas_station),
          EnveloppeModel(id: 'env2_2',
              nom: 'Maintenance',
              couleur: Colors.blueGrey[300],
              montantAlloue: 50,
              depense: 0,
              disponible: 50,
              icone: Icons.build),
        ],
      ),
      CategorieBudgetModel(
          id: 'cat3',
          nom: 'Loisirs',
          couleur: Colors.greenAccent[400]!,
          alloueTotal: 200,
          depenseTotal: 210,
          disponibleTotal: -10,
          info: 'Activités et sorties',
          enveloppes: [
            EnveloppeModel(id: 'env3_1',
                nom: 'Cinéma',
                montantAlloue: 50,
                depense: 60,
                disponible: -10,
                icone: Icons.theaters),
          ]),
    ];
    // L'initialisation de _etatsDepliageCategories a été supprimée d'ici

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _moisPrecedent() {
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month - 1, 1);
    });
    _chargerDonneesBudgetNonStream();
  }

  void _moisSuivant() {
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month + 1, 1);
    });
    _chargerDonneesBudgetNonStream();
  }

  void _handleDateTap() async {
    final DateTime? picked = await _showCustomMonthYearPicker(context);
    if (picked != null && (picked.year != _moisAnneeCourant.year ||
        picked.month != _moisAnneeCourant.month)) {
      setState(() {
        _moisAnneeCourant = DateTime(picked.year, picked.month, 1);
      });
      _chargerDonneesBudgetNonStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          titleSpacing: 0,
          title: _buildCustomAppBarTitle(theme),
          actions: _buildAppBarActions(theme),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Veuillez vous connecter pour voir votre budget.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        titleSpacing: 0,
        title: _buildCustomAppBarTitle(theme),
        actions: _buildAppBarActions(theme),
      ),
      body: RefreshIndicator(
        onRefresh: _chargerDonneesBudgetNonStream,
        backgroundColor: const Color(0xFF1E1E1E),
        color: Colors.white,
        child: StreamBuilder<List<Compte>>(
          stream: _comptesStream,
          builder: (context, snapshotComptes) {
            bool streamComptesEnChargement = snapshotComptes.connectionState ==
                ConnectionState.waiting;

            if (_isLoading ||
                (streamComptesEnChargement && !snapshotComptes.hasData)) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshotComptes.hasError) {
              print("Erreur du StreamBuilder pour les comptes: ${snapshotComptes
                  .error}");
              return Center(child: Text('Erreur de chargement des comptes.',
                  style: TextStyle(color: Colors.red[300])));
            }

            List<Compte> comptesPourBandeaux = snapshotComptes.data ?? [];

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // Section 1: Bandeaux "Prêt à placer"
                ...comptesPourBandeaux
                    .where((compte) => compte.soldeActuel != 0)
                    .map((compte) {
                  return _buildReadyToAssignBanner(theme, compte);
                }).toList(),

                // Section 2: Bandeau "Transactions à revoir" (Widget externe)
                TransactionsReviewBanner(
                  count: _nombreTransactionsARevoir,
                  onTap: () {
                    print('Bannière "Transactions à revoir" cliquée');
                    // TODO: Implémentez la navigation ou l'action désirée
                  },
                ),

                // Section 3: Section des catégories (Widget externe)
                BudgetCategoriesList(
                  categories: _categoriesDuBudget,
                  comptesActuels: comptesPourBandeaux,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 80), // Espace en bas
              ],
            );
          },
        ),
      ),
    );
  }

  Future<DateTime?> _showCustomMonthYearPicker(BuildContext context) async {
    DateTime tempPickedDate = _moisAnneeCourant;

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            List<String> moisNoms = List.generate(12, (index) {
              return DateFormat.MMM('fr_FR').format(
                  DateTime(tempPickedDate.year, index + 1));
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      stfSetState(() {
                        tempPickedDate = DateTime(
                            tempPickedDate.year - 1, tempPickedDate.month);
                      });
                    },
                  ),
                  Text(
                    DateFormat.y('fr_FR').format(tempPickedDate),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      stfSetState(() {
                        tempPickedDate = DateTime(
                            tempPickedDate.year + 1, tempPickedDate.month);
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: moisNoms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (BuildContext itemContext, int index) {
                    final moisDateTime = DateTime(
                        tempPickedDate.year, index + 1);
                    bool isCurrentlySelectedOnScreen = moisDateTime.month ==
                        _moisAnneeCourant.month &&
                        moisDateTime.year == _moisAnneeCourant.year;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentlySelectedOnScreen ? Theme
                            .of(context)
                            .primaryColor : const Color(0xFF333333),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                          moisNoms[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isCurrentlySelectedOnScreen ? FontWeight
                                .bold : FontWeight.normal,
                          )),
                      onPressed: () {
                        Navigator.pop(dialogContext,
                            DateTime(tempPickedDate.year, index + 1, 1));
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomAppBarTitle(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: _handleDateTap,
              child: Container(
                color: Colors.transparent, // Pour une meilleure zone de clic
                padding: EdgeInsets.zero, // Ajustez si nécessaire
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // Pour que la Row ne prenne que la place nécessaire
                  children: [
                    Text(
                      DateFormat.yMMM('fr_FR').format(_moisAnneeCourant),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        // Taille de police légèrement réduite pour la propreté
                        fontWeight: FontWeight.bold,
                      ) ??
                          const TextStyle(color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                        Icons.arrow_drop_down, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(ThemeData theme) {
    return [
      IconButton(icon: const Icon(Icons.category_outlined, color: Colors.white),
          onPressed: () {
            /* TODO: Naviguer vers la gestion des catégories/modèles */
          }),
      IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {
        /* TODO: Ouvrir un drawer ou menu principal */
      }),
      IconButton(icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            /* TODO: Options supplémentaires */
          }),
    ];
  }

  Widget _buildReadyToAssignBanner(ThemeData theme, Compte compte) {
    bool isOverAllocated = compte.soldeActuel < 0;
    double displayAmount = compte.soldeActuel.abs();
    String titleText = compte.nom.toUpperCase();
    Color bannerColor = compte.couleur; // Utilisation de la couleur du compte
    String subtitleText = isOverAllocated ? 'SUR-UTILISÉ' : 'DISPONIBLE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bannerColor, // Appliquer la couleur du compte
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded( // Pour s'assurer que le texte ne déborde pas si le nom du compte est long
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titleText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow
                      .ellipsis, // Gérer les textes trop longs
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Row( // Pour garder l'icône et le montant ensemble
            children: [
              if (isOverAllocated)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white.withOpacity(0.9),
                    // Couleur de l'icône d'avertissement
                    size: 20,
                  ),
                ),
              Text(
                '${displayAmount.toStringAsFixed(2)} \$',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
// Les méthodes _buildCategoriesSection, _buildCategorieItem, _buildEnveloppeItem ont été déplacées
// vers budget_categories_list.dart
}