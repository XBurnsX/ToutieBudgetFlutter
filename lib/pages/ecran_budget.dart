import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toutie_budget/models/compte_model.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart';
import 'package:toutie_budget/widgets/transactions_review_banner.dart';
import 'package:toutie_budget/widgets/budget_categories_list.dart';
import 'budget/ecran_virer_argent.dart';
import 'gestion_categories_enveloppes_screen.dart'
    show Categorie, EnveloppeTestData, TypeObjectif, GestionCategoriesEnveloppesScreen; // Assurez-vous d'importer GestionCategoriesEnveloppesScreen


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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Compte>>? _comptesStream;
  Stream<List<CategorieBudgetModel>>? _categoriesStream;

  int _nombreTransactionsARevoir = 0;
  bool _isLoadingDonneesAnnexes = true;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          if (_currentUser != null) {
            _comptesStream = _getComptesStream();
            _categoriesStream = _getCategoriesBudgetStream();
            _chargerDonneesAnnexes();
          } else {
            _comptesStream = Stream.value([]);
            _categoriesStream = Stream.value([]);
            _nombreTransactionsARevoir = 0;
            _isLoadingDonneesAnnexes = false;
          }
        });
      }
    });

    if (_currentUser != null) {
      _comptesStream = _getComptesStream();
      _categoriesStream = _getCategoriesBudgetStream();
      _chargerDonneesAnnexes();
    } else {
      _isLoadingDonneesAnnexes = false;
    }
  }

  Stream<List<Compte>>? _getComptesStream() {
    if (_currentUser == null) return Stream.value([]);
    // TODO: Filtrer par _moisAnneeCourant si nécessaire
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('comptes')
        .orderBy('nom')
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        try {
          return Compte.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>);
        } catch (e, stacktrace) {
          print(
              "Stream Comptes - ERREUR parsing doc ${doc.id}: $e\n$stacktrace");
          return null;
        }
      }).whereType<Compte>().toList();
    });
  }

  // MODIFIÉ: Renommée et type de retour changé
  EnveloppePourAffichageBudget _creerViewModelEnveloppePourListe(
      EnveloppeTestData enveloppeSource,
      ) {
    double alloue = enveloppeSource.montantAlloue;
    double soldeActuel = enveloppeSource.soldeActuel;
    double depense = alloue - soldeActuel;
    if (depense < 0) {
      depense = 0;
    }
    double disponible = soldeActuel;

    // PAS DE CALCUL DE messageSous ICI

    return EnveloppePourAffichageBudget(
      id: enveloppeSource.id,
      nom: enveloppeSource.nom,
      montantAlloue: alloue,
      disponible: disponible,
      depense: depense,
      couleur: Color(enveloppeSource.couleurThemeValue),
      icone: enveloppeSource.iconeCodePoint != null
          ? IconData(enveloppeSource.iconeCodePoint!, fontFamily: 'MaterialIcons')
          : null,
      typeObjectif: enveloppeSource.typeObjectif,   // CORRIGÉ : Transférer la valeur
      montantCible: enveloppeSource.montantCible,   // CORRIGÉ : Transférer la valeur
      // dateCible: enveloppeSource.dateCible,    // Transférez si EnveloppePourAffichageBudget en a besoin directement
      // ET si EnveloppeTestData le fournit déjà correctement typé.
      // PAS DE messageSousObjectif ICI
    );
  }

  CategorieBudgetModel _transformerCategorieFirestoreEnModel(
      Categorie categorieFirestore, // categorieFirestore est de type Categorie de gestion_categories...
      ) {
    Color couleurPourLaVueCategorie;
    if (categorieFirestore.enveloppes.isNotEmpty &&
        // Assurez-vous que EnveloppeTestData a bien un champ couleurThemeValue
        categorieFirestore.enveloppes.first.couleurThemeValue != null) {
      couleurPourLaVueCategorie = Color(categorieFirestore.enveloppes.first.couleurThemeValue!);
    } else {
      couleurPourLaVueCategorie = Colors.blueGrey[700]!; // Couleur par défaut
    }

    List<EnveloppePourAffichageBudget> enveloppesPourAffichage = [];
    double alloueTotalCat = 0;
    double depenseTotalCat = 0;
    double disponibleTotalCat = 0;

    for (var enveloppeSource in categorieFirestore.enveloppes) {
      // Crée le ViewModel pour l'enveloppe. Les calculs de dépense/disponible sont DANS _creerViewModelEnveloppePourListe
      EnveloppePourAffichageBudget enveloppeVM = _creerViewModelEnveloppePourListe(
        enveloppeSource,
        // On ne passe plus de dépenses ici, elles sont calculées à partir de enveloppeSource.soldeActuel
        // On ne passe plus la couleur catégorie parente ici
        // On ne passe plus moisAnneeCourant ici si non utilisé directement dans _creerViewModelEnveloppePourListe
      );
      enveloppesPourAffichage.add(enveloppeVM);

      alloueTotalCat += enveloppeVM.montantAlloue;
      depenseTotalCat += enveloppeVM.depense;
      disponibleTotalCat += enveloppeVM.disponible;
    }

    // Alternative pour disponibleTotalCat pour être cohérent avec les enveloppes :
    // disponibleTotalCat = alloueTotalCat - depenseTotalCat;
    // Cependant, si disponible est directement le soldeActuel, alors sommer les soldes actuels est aussi correct.
    // Pour l'instant, sommer les 'disponible' des VMs est plus direct.

    return CategorieBudgetModel(
      id: categorieFirestore.id,
      nom: categorieFirestore.nom,
      couleur: couleurPourLaVueCategorie,
      info: '${enveloppesPourAffichage.length} enveloppe${enveloppesPourAffichage.length > 1 ? "s" : ""}', // Exemple d'info
      alloueTotal: alloueTotalCat,
      depenseTotal: depenseTotalCat,
      disponibleTotal: disponibleTotalCat,
      enveloppes: enveloppesPourAffichage,
    );
  }

  Stream<List<CategorieBudgetModel>>? _getCategoriesBudgetStream() {
    if (_currentUser == null) return Stream.value([]);
    // Pas besoin de dépendre de _transactionsStream pour l'instant avec cette approche simplifiée

    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('categories') // Ou la collection où vous stockez les données mensuelles
        .orderBy('nom')
        .snapshots()
        .map((snapshot) { // Pas besoin d'asyncMap si on ne récupère pas d'autres données ici
      if (snapshot.docs.isEmpty) {
        return <CategorieBudgetModel>[];
      }
      return snapshot.docs.map((doc) {
        try {
          final categorieFirestore = Categorie.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>);
          // Appelle la version simplifiée de _transformerCategorieFirestoreEnModel
          return _transformerCategorieFirestoreEnModel(categorieFirestore);
        } catch (e, stacktrace) {
          print("Stream Catégories - ERREUR mapping doc ${doc.id}: $e");
          print("Stream Catégories - Stacktrace: $stacktrace");
          return null;
        }
      }).whereType<CategorieBudgetModel>().toList();
    });
  }

  Future<void> _chargerDonneesAnnexes() async {
    if (!mounted || _currentUser == null) {
      if (mounted) setState(() => _isLoadingDonneesAnnexes = false);
      return;
    }

    if (mounted) setState(() => _isLoadingDonneesAnnexes = true);

    // TODO: Vraie logique de chargement pour _nombreTransactionsARevoir
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _nombreTransactionsARevoir = 3; // Exemple
      _isLoadingDonneesAnnexes = false;
    });
  }

  void _actualiserStreamsEtDonneesAnnexes() {
    if (_currentUser != null && mounted) {
      setState(() {
        _comptesStream = _getComptesStream();
        _categoriesStream = _getCategoriesBudgetStream();
      });
      _chargerDonneesAnnexes();
    }
  }

  void _moisPrecedent() {
    if (!mounted) return;
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month - 1, 1);
    });
    _actualiserStreamsEtDonneesAnnexes();
  }

  void _moisSuivant() {
    if (!mounted) return;
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month + 1, 1);
    });
    _actualiserStreamsEtDonneesAnnexes();
  }

  void _handleDateTap() async {
    if (!mounted) return;
    final DateTime? picked = await _showCustomMonthYearPicker(context);
    if (picked != null && (picked.year != _moisAnneeCourant.year ||
        picked.month != _moisAnneeCourant.month)) {
      if (!mounted) return;
      setState(() {
        _moisAnneeCourant = DateTime(picked.year, picked.month, 1);
      });
      _actualiserStreamsEtDonneesAnnexes();
    }
  }

  void _naviguerVersGestionCategories() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const GestionCategoriesEnveloppesScreen()),
    ).then((_) {
      if (mounted) {
        // Les streams devraient se mettre à jour automatiquement si Firestore est modifié.
        // Un rafraîchissement explicite est rarement nécessaire si les données streamées changent.
        // _actualiserStreamsEtDonneesAnnexes(); // Décommentez seulement si absolument nécessaire
      }
    });
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Veuillez vous connecter pour voir et gérer votre budget.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implémenter la navigation vers l'écran de connexion
                    print("Navigation vers l'écran de connexion demandée.");
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary),
                  child: const Text(
                      "Se connecter", style: TextStyle(color: Colors.white)),
                )
              ],
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
        onRefresh: () async {
          if (_currentUser != null) {
            _actualiserStreamsEtDonneesAnnexes();
          }
        },
        backgroundColor: const Color(0xFF1E1E1E),
        color: Colors.white,
        child: StreamBuilder<List<Compte>>(
          stream: _comptesStream,
          builder: (context, snapshotComptes) {
            return StreamBuilder<List<CategorieBudgetModel>>(
              stream: _categoriesStream,
              builder: (context, snapshotCategories) {
                bool isWaitingForData = (_isLoadingDonneesAnnexes ||
                    (snapshotComptes.connectionState ==
                        ConnectionState.waiting && !snapshotComptes.hasData) ||
                    (snapshotCategories.connectionState ==
                        ConnectionState.waiting &&
                        !snapshotCategories.hasData));

                if (isWaitingForData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshotComptes.hasError) {
                  print("Erreur StreamBuilder comptes: ${snapshotComptes
                      .error}\n${snapshotComptes.stackTrace}");
                  return Center(child: Text('Erreur chargement comptes.',
                      style: TextStyle(color: Colors.red[300])));
                }
                if (snapshotCategories.hasError) {
                  print("Erreur StreamBuilder catégories: ${snapshotCategories
                      .error}\n${snapshotCategories.stackTrace}");
                  return Center(child: Text('Erreur chargement catégories.',
                      style: TextStyle(color: Colors.red[300])));
                }

                List<Compte> comptesActuels = snapshotComptes.data ?? [];
                List<
                    CategorieBudgetModel> categoriesPourListe = snapshotCategories
                    .data ?? [];

                return ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    if (comptesActuels.isNotEmpty)
                      ...comptesActuels.map((compte) =>
                          _buildReadyToAssignBanner(theme, compte)).toList()
                    else
                      if (snapshotComptes.connectionState ==
                          ConnectionState.active)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0,
                              vertical: 10.0),
                          child: Text(
                              "Aucun compte trouvé. Créez-en un pour commencer !",
                              style: TextStyle(color: Colors.white70)),
                        ),

                    if (_nombreTransactionsARevoir > 0)
                      TransactionsReviewBanner(
                        count: _nombreTransactionsARevoir,
                        onTap: () {
                          print('Bannière "Transactions à revoir" cliquée');
                          // TODO: Naviguer vers l'écran de révision
                        },
                      ),

                    BudgetCategoriesList(
                      categories: categoriesPourListe,
                      comptesActuels: comptesActuels,
                      isLoading: false,
                      // Géré par les StreamBuilders externes
                      onCreerCategorieDemandee: _naviguerVersGestionCategories,
                      moisAnneeCourant: _moisAnneeCourant,
                    ),

                    const SizedBox(height: 80),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<DateTime?> _showCustomMonthYearPicker(BuildContext context) async {
    DateTime tempPickedDate = _moisAnneeCourant;
    final ThemeData theme = Theme.of(context); // Récupérer le thème ici

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            List<String> moisNoms = List.generate(12, (index) =>
                DateFormat.MMM('fr_FR').format(
                    DateTime(tempPickedDate.year, index + 1)));

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () =>
                        stfSetState(() =>
                        tempPickedDate = DateTime(tempPickedDate.year - 1,
                            tempPickedDate.month)),
                  ),
                  Text(DateFormat.y('fr_FR').format(tempPickedDate),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () =>
                        stfSetState(() =>
                        tempPickedDate = DateTime(tempPickedDate.year + 1,
                            tempPickedDate.month)),
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
                    childAspectRatio: 1.8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (BuildContext itemContext, int index) {
                    final moisDateTime = DateTime(
                        tempPickedDate.year, index + 1);
                    bool isCurrentlySelectedOnScreen = moisDateTime.month ==
                        _moisAnneeCourant.month &&
                        moisDateTime.year == _moisAnneeCourant.year;
                    bool isSelectedInPicker = moisDateTime.month ==
                        tempPickedDate.month;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelectedInPicker ? theme.colorScheme
                            .primary : (isCurrentlySelectedOnScreen
                            ? theme.colorScheme.secondary.withOpacity(0.5)
                            : const Color(0xFF333333)),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        moisNoms[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: isSelectedInPicker ||
                            isCurrentlySelectedOnScreen
                            ? FontWeight.bold
                            : FontWeight.normal),
                      ),
                      onPressed: () =>
                          Navigator.pop(dialogContext,
                              DateTime(tempPickedDate.year, index + 1, 1)),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                      'ANNULER', style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                TextButton(
                  child: Text(
                      'OK', style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: () =>
                      Navigator.pop(dialogContext, DateTime(
                      tempPickedDate.year, tempPickedDate.month, 1)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomAppBarTitle(ThemeData theme) {
    return Container(
      width: double.infinity,
      // Le padding horizontal peut être ajusté pour contrôler l'espacement par rapport aux bords de l'AppBar
      padding: const EdgeInsets.symmetric(horizontal: 30.0), // Ajusté de 0.0 à 8.0 ou 16.0
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // MODIFIÉ: pour aligner à gauche
        children: [
          // Laisser les IconButton pour précédent/suivant ici si vous les voulez toujours visibles
          // IconButton(icon: Icon(Icons.chevron_left, color: Colors.white), onPressed: _currentUser != null ? _moisPrecedent : null),

          // Le GestureDetector prendra la place nécessaire
          GestureDetector(
            onTap: _currentUser != null ? _handleDateTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.yMMM('fr_FR').format(_moisAnneeCourant),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ) ??
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                    // textAlign: TextAlign.left, // Plus nécessaire avec MainAxisAlignment.start sur la Row parente
                  ),
                  if (_currentUser != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                  ]
                ],
              ),
            ),
          ),
          // Laisser les IconButton pour précédent/suivant ici si vous les voulez toujours visibles
          // IconButton(icon: Icon(Icons.chevron_right, color: Colors.white), onPressed: _currentUser != null ? _moisSuivant : null),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(ThemeData theme) {
    print(">>> EcranBudget - _buildAppBarActions - _currentUser: $_currentUser");
    return [
      if (_currentUser != null)
        IconButton( // Premier IconButton conditionnel
          icon: const Icon(Icons.multiple_stop, color: Colors.white),
          tooltip: 'Virer de l\'argent entre enveloppes',
          onPressed: () {
            print(">>> BOUTON 'Virer de l'argent' DANS AppBar EST PRESSÉ <<<");
            if (!mounted) {
              print(">>> EcranBudget - WARNING: Tentative de navigation alors que le widget n'est pas monté !");
              return;
            }
            try {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  print(">>> MaterialPageRoute - BUILDER pour EcranVirerArgent EST APPELÉ <<<");
                  return const EcranVirerArgent();
                }),
              ).then((_) {
                print(">>> EcranVirerArgent A ÉTÉ POPPED (fermé) et est revenu à EcranBudget <<<");
              }).catchError((error) {
                print(">>> ERREUR PENDANT OU APRÈS LA NAVIGATION vers EcranVirerArgent: $error <<<");
              });
              print(">>> APPEL À Navigator.push(...) pour EcranVirerArgent TERMINÉ (pas d'erreur synchrone immédiate) <<<");
            } catch (e, s) {
              print(">>> ERREUR SYNCHRONE FATALE LORS DE LA TENTATIVE DE NAVIGUER vers EcranVirerArgent: $e\nStackTrace: $s <<<");
            }
          },
        ), // <-- La virgule est implicite ici si un autre élément suit, mais c'est bien

      if (_currentUser != null)
        IconButton( // Deuxième IconButton conditionnel
          icon: const Icon(Icons.category_outlined, color: Colors.white),
          tooltip: 'Gérer les catégories et enveloppes',
          onPressed: _naviguerVersGestionCategories,
        ), // <-- Virgule ici car un autre élément suit

      IconButton( // Widget inconditionnel
        icon: const Icon(Icons.menu, color: Colors.white),
        tooltip: _currentUser != null ? 'Menu principal' : 'Options',
        onPressed: () {
          final scaffoldState = Scaffold.maybeOf(context);
          if (scaffoldState?.hasEndDrawer ?? false) {
            scaffoldState!.openEndDrawer();
          } else {
            print("Pas d'endDrawer défini.");
            // TODO: Logique alternative si pas de drawer
          }
        },
      ), // <-- Virgule optionnelle ici si c'est le dernier élément
    ];
  }

  Widget _buildReadyToAssignBanner(ThemeData theme, Compte compte) {
    bool isOverAllocated = compte.soldeActuel < 0;
    double displayAmount = compte.soldeActuel.abs();
    String titleText = compte.nom.toUpperCase();
    Color bannerColor = compte
        .couleur; // Assurez-vous que Compte a un champ `couleur` de type Color
    String subtitleText = compte.soldeActuel < 0 ? 'DÉCOUVERT' : 'SOLDE ACTUEL';

    Color textColor = ThemeData.estimateBrightnessForColor(bannerColor) ==
        Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2)),
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
                  style: theme.textTheme.labelLarge?.copyWith(color: textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitleText, style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.9))),
              ],
            ),
          ),
          Row(
            children: [
              if (isOverAllocated)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.warning_amber_rounded,
                      color: textColor.withOpacity(0.9), size: 20),
                ),
              Text(
                '${displayAmount.toStringAsFixed(2)} \$',
                style: theme.textTheme.titleLarge?.copyWith(color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}