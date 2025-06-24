//ecran_budget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mettez le chemin correct vers votre modèle de compte
import 'package:toutie_budget/models/compte_model.dart'; // VÉRIFIEZ CE CHEMIN

// --- Définitions des Modèles (si non importés d'ailleurs) ---
// Si ces modèles sont dans d'autres fichiers, assurez-vous de les importer correctement.
// Je les inclus ici pour que le code soit complet et compilable tel quel,
// mais il est préférable de les avoir dans leurs propres fichiers.

class EnveloppeModel {
  String id;
  String nom;
  IconData? icone;
  double montantBudgete;
  double montantAlloue;
  double depense;
  double disponible;
  String? messageSous;

  EnveloppeModel({
    required this.id,
    required this.nom,
    this.icone,
    this.montantBudgete = 0.0,
    this.montantAlloue = 0.0,
    this.depense = 0.0,
    this.disponible = 0.0,
    this.messageSous,
  });
}

class CategorieBudgetModel {
  String id;
  String nom;
  double alloueTotal;
  double depenseTotal;
  double disponibleTotal;
  String info;
  List<EnveloppeModel> enveloppes;

  CategorieBudgetModel({
    required this.id,
    required this.nom,
    this.alloueTotal = 0.0,
    this.depenseTotal = 0.0,
    this.disponibleTotal = 0.0,
    this.info = "",
    List<EnveloppeModel>? enveloppes,
  }) : enveloppes = enveloppes ?? [];
}
// --- Fin des définitions des Modèles ---

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
  bool _isLoading = true; // Pour les données non-streamées (catégories, etc.)

  // List<Compte> _comptesPourBandeaux = []; // Peut être enlevé si on utilise directement snapshot.data
  Stream<List<Compte>>? _comptesStream;

  int _nombreTransactionsARevoir = 0; // Donnée simulée
  List<CategorieBudgetModel> _categoriesDuBudget = []; // Donnée simulée
  Map<String, bool> _etatsDepliageCategories = {
  }; // Donnée simulée pour le dépliage

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _comptesStream = _getComptesStream();
    }
    _chargerDonneesBudgetNonStream(); // Charger les données simulées/non-streamées
  }

  Stream<List<Compte>>? _getComptesStream() {
    if (_currentUser == null) {
      return Stream.value([]); // Stream vide si pas d'utilisateur
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

    // SIMULATION: Remplacez par votre vraie logique de chargement pour catégories, etc.
    // Cette logique pourrait dépendre de _moisAnneeCourant
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simule un délai réseau

    _nombreTransactionsARevoir = 2; // Exemple
    _categoriesDuBudget = [ // Exemples de données simulées
      CategorieBudgetModel(
        id: 'cat1',
        nom: 'Alimentation',
        alloueTotal: 500,
        depenseTotal: 250,
        disponibleTotal: 250,
        info: 'Budget mensuel pour les courses',
        enveloppes: [
          EnveloppeModel(id: 'env1_1',
              nom: 'Supermarché',
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
              montantAlloue: 50,
              depense: 0,
              disponible: 50,
              icone: Icons.build),
        ],
      ),
    ];
    _etatsDepliageCategories =
        Map.fromIterable( // Initialise les états de dépliage
          _categoriesDuBudget,
          key: (item) => (item as CategorieBudgetModel).id,
          value: (
              item) => false, // Toutes les catégories sont repliées par défaut
        );
    // FIN SIMULATION

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
    _chargerDonneesBudgetNonStream(); // Recharge les données non-stream pour le nouveau mois
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
        // Recharge les données non-stream
        backgroundColor: const Color(0xFF1E1E1E),
        color: Colors.white,
        child: StreamBuilder<List<Compte>>(
          stream: _comptesStream,
          builder: (context, snapshotComptes) {
            bool streamComptesEnChargement = snapshotComptes.connectionState ==
                ConnectionState.waiting;

            // Afficher un loader si les données non-streamées chargent OU si le stream charge et n'a pas encore de données
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

            // Si _isLoading est false (données non-streamées prêtes)
            // et que le stream des comptes est vide (après chargement)
            // et qu'il n'y a pas de catégories, on pourrait afficher un message global "Commencez..."
            // Cependant, _buildCategoriesSection gère déjà un cas similaire.
            // On peut laisser _buildCategoriesSection afficher son message si nécessaire.

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ...comptesPourBandeaux
                    .where((compte) => compte.soldeActuel != 0)
                    .map((compte) {
                  return _buildReadyToAssignBanner(theme, compte);
                }).toList(),
                _buildReviewTransactionsBanner(theme),
                _buildCategoriesSection(theme, comptesPourBandeaux),
                // Passe les comptes du stream
                const SizedBox(height: 80),
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
                        backgroundColor: isCurrentlySelectedOnScreen
                            ? Theme
                            .of(context)
                            .primaryColor
                            : const Color(0xFF333333),
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
                          )
                      ),
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
                color: Colors.transparent,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat.yMMM('fr_FR').format(_moisAnneeCourant),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ) ?? const TextStyle(color: Colors.white,
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
            /* TODO */
          }),
      IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {
        /* TODO */
      }),
      IconButton(icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            /* TODO */
          }),
    ];
  }

  Widget _buildReadyToAssignBanner(ThemeData theme, Compte compte) {
    bool isOverAllocated = compte.soldeActuel < 0;
    double displayAmount = compte.soldeActuel.abs();
    String titleText = compte.nom.toUpperCase();
    Color bannerColor = compte.couleur;
    String subtitleText = isOverAllocated ? 'SUR-UTILISÉ' : 'DISPONIBLE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bannerColor,
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
          Expanded(
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
                  overflow: TextOverflow.ellipsis,
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
          Row(
            children: [
              if (isOverAllocated)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white.withOpacity(0.9),
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

  Widget _buildReviewTransactionsBanner(ThemeData theme) {
    if (_nombreTransactionsARevoir == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40), // Vert foncé
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
      child: InkWell(
        onTap: () {
          print('Bannière "Transactions à revoir" cliquée');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                const Icon(Icons.playlist_add_check_circle_outlined,
                    color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  '$_nombreTransactionsARevoir transactions à revoir',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Icon(
                Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, List<Compte> comptesActuels) {
    bool aucunCompteAvecSolde = comptesActuels
        .where((c) => c.soldeActuel != 0)
        .isEmpty;

    // _isLoading ici se réfère au chargement des données non-stream (catégories)
    if (_categoriesDuBudget.isEmpty && aucunCompteAvecSolde && !_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 60, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Commencez par créer des catégories',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                'Organisez votre budget en allouant des fonds à différentes catégories et enveloppes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer une catégorie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  print('Naviguer vers la création de catégorie');
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_categoriesDuBudget.isEmpty && !aucunCompteAvecSolde && !_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Center(
          child: Text(
            'Aucune catégorie budgétaire pour ce mois.\nCommencez par en ajouter une !',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Si _isLoading est vrai pour les catégories, on pourrait afficher un loader spécifique ici,
    // mais le loader global dans build() devrait déjà le couvrir.
    if (_isLoading) {
      return Padding( // Ou un simple SizedBox.shrink() si le loader global suffit
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: const Center(
            child: CircularProgressIndicator(color: Colors.white54)),
      );
    }


    return Column(
      children: _categoriesDuBudget.map((categorie) =>
          _buildCategorieItem(theme, categorie)).toList(),
    );
  }

  Widget _buildCategorieItem(ThemeData theme, CategorieBudgetModel categorie) {
    bool estDeplie = _etatsDepliageCategories[categorie.id] ?? false;
    double progression = 0;
    if (categorie.alloueTotal > 0) {
      progression = categorie.depenseTotal / categorie.alloueTotal;
    }
    progression = progression.clamp(0.0, 1.0);
    Color couleurProgression = Colors.green;
    if (progression > 0.85) couleurProgression = Colors.orange;
    if (progression >= 1.0 && categorie.depenseTotal > categorie.alloueTotal) {
      couleurProgression = Colors.red;
    }

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _etatsDepliageCategories[categorie.id] = !estDeplie;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0),
            color: Colors.grey[850],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        categorie.nom.toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${categorie.disponibleTotal.toStringAsFixed(2)} \$',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: couleurProgression,
                          fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      estDeplie ? Icons.keyboard_arrow_down : Icons
                          .keyboard_arrow_right,
                      color: Colors.white70,
                    ),
                  ],
                ),
                if (categorie.info.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categorie.info,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progression,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(couleurProgression),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ),
        if (estDeplie)
          Container(
            color: Colors.grey[900],
            child: Column(
              children: categorie.enveloppes.map((enveloppe) =>
                  _buildEnveloppeItem(theme, enveloppe)).toList(),
            ),
          ),
        Divider(height: 1, color: Colors.grey[700]),
      ],
    );
  }

  Widget _buildEnveloppeItem(ThemeData theme, EnveloppeModel enveloppe) {
    double progression = 0;
    if (enveloppe.montantAlloue > 0) {
      progression = enveloppe.depense / enveloppe.montantAlloue;
    }
    progression = progression.clamp(0.0, 1.0);
    Color couleurProgression = Colors.blueAccent;
    if (enveloppe.disponible < 0) {
      couleurProgression = Colors.redAccent;
    } else if (progression > 0.85) {
      couleurProgression = Colors.orangeAccent;
    }


    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('Enveloppe ${enveloppe.nom} cliquée');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: <Widget>[
                  if (enveloppe.icone != null) ...[
                    Icon(enveloppe.icone, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      enveloppe.nom,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${enveloppe.disponible.toStringAsFixed(2)} \$',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: couleurProgression, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (enveloppe.messageSous != null &&
                  enveloppe.messageSous!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(
                      left: enveloppe.icone != null ? 32 : 0),
                  child: Text(
                    enveloppe.messageSous!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400]),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(
                    left: enveloppe.icone != null ? 32 : 0),
                child: LinearProgressIndicator(
                  value: progression,
                  backgroundColor: Colors.grey[700]?.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(couleurProgression),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}