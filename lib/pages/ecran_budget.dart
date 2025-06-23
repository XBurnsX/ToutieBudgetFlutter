// lib/pages/ecran_budget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Définitions des Modèles ---
class CategorieBudgetModel {
  final String id;
  final String nom;
  final String info;
  final List<EnveloppeModel> enveloppes;

  CategorieBudgetModel({
    required this.id,
    required this.nom,
    required this.info,
    required this.enveloppes,
  });
}

class EnveloppeModel {
  final String id;
  final String nom;
  final double montantAlloue;
  final double montantBudgete;
  final String? messageSous;
  final IconData? icone;

  EnveloppeModel({
    required this.id,
    required this.nom,
    required this.montantAlloue,
    this.montantBudgete = 0.0,
    this.messageSous,
    this.icone,
  });
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

  double _montantPretAPlacer = 0.0;
  int _nombreTransactionsARevoir = 0;
  List<CategorieBudgetModel> _categoriesDuBudget = [];
  Map<String, bool> _etatsDepliageCategories = {};

  @override
  void initState() {
    super.initState();
    _chargerDonneesBudget();
  }

  Future<void> _chargerDonneesBudget() async {
    // TODO: Implémenter le chargement des données réelles ici
    if (!mounted) return;

    // Simulation et réinitialisation des données
    setState(() {
      _montantPretAPlacer = 0.00;
      _nombreTransactionsARevoir = 0;
      _categoriesDuBudget = []; // Commence avec une liste vide
      _etatsDepliageCategories = {}; // Réinitialise l'état de dépliage

      // --- TEMPORAIRE: Pour voir la structure avec des données de test minimales ---
      // Décommentez et adaptez ceci si vous voulez tester l'UI avec quelques données
      // avant de connecter Firebase.
      /*
      _montantPretAPlacer = 123.45;
      _nombreTransactionsARevoir = 2;
      _categoriesDuBudget = [
        CategorieBudgetModel(
          id: 'cat_depenses_oblig',
          nom: 'Dépenses Obligatoires',
          info: 'Objectifs',
          enveloppes: [
            EnveloppeModel(id: 'env_loyer', nom: 'Loyer', montantAlloue: 500.0, montantBudgete: 1000.0, icone: Icons.home_work_outlined, messageSous: "500.00\$ requis"),
            EnveloppeModel(id: 'env_internet', nom: 'Internet', montantAlloue: 50.0, montantBudgete: 50.0, icone: Icons.wifi),
          ]
        ),
        CategorieBudgetModel(
          id: 'cat_loisirs',
          nom: 'Loisirs',
          info: 'Disponible',
          enveloppes: [
            EnveloppeModel(id: 'env_cine', nom: 'Cinéma', montantAlloue: 25.0, montantBudgete: 50.0, icone: Icons.theaters),
          ]
        ),
        CategorieBudgetModel(
          id: 'cat_vide_test',
          nom: 'Catégorie Vide',
          info: 'Aucune enveloppe',
          enveloppes: []
        )
      ];
      // Initialiser l'état de dépliage (ex: tout déplié pour le test)
      _etatsDepliageCategories = {
        for (var categorie in _categoriesDuBudget) categorie.id: true,
      };
      */
      // --- FIN TEMPORAIRE ---
    });
  }

  void _moisPrecedent() {
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month - 1, 1);
    });
    _chargerDonneesBudget();
  }

  void _moisSuivant() {
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month + 1, 1);
    });
    _chargerDonneesBudget();
  }

  void _showDatePickerDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _moisAnneeCourant,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && (picked.year != _moisAnneeCourant.year ||
        picked.month != _moisAnneeCourant.month)) {
      setState(() {
        _moisAnneeCourant = DateTime(picked.year, picked.month, 1);
      });
      _chargerDonneesBudget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        // leading: IconButton( // <--- SUPPRIMER OU COMMENTER CETTE LIGNE
        //   icon: const Icon(Icons.more_horiz, color: Colors.white),
        //   onPressed: () {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Menu More Horiz (leading - TODO)')),
        //     );
        //   },
        //   tooltip: 'Plus d\'options (leading)',
        // ),
        titleSpacing: 0,
        title: _buildCustomAppBarTitle(theme),
        actions: _buildAppBarActions(theme),
      ),
      body: RefreshIndicator(
        onRefresh: _chargerDonneesBudget,
        backgroundColor: const Color(0xFF1E1E1E),
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (_montantPretAPlacer != 0) // S'affiche si positif OU négatif
              _buildReadyToAssignBanner(theme),
            // ^^^^^ --- FIN DE LA MODIFICATION --- ^^^^^
            _buildReviewTransactionsBanner(theme),
            _buildCategoriesSection(theme),
            const SizedBox(height: 80), // !!! ATTENTION !!! Hauteur du bandeau pret a placer
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBarTitle(ThemeData theme) {
    return Container(
      width: double.infinity,
      // Si vous voulez qu'il touche le bord de l'écran (ou le leading s'il y en avait un),
      // mettez ce padding à zéro ou à une petite valeur.
      padding: const EdgeInsets.symmetric(horizontal: 25.0), // Était 16.0
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // <--- CHANGEZ CECI DE .center À .start
        children: [
          // Le Flexible n'est peut-être plus aussi crucial si vous alignez au début,
          // mais ne nuit pas. Vous pourriez aussi l'enlever et laisser le GestureDetector directement.
          Flexible(
            child: GestureDetector(
              onTap: _showDatePickerDialog,
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.zero, // Padding autour du texte du mois (si vous le voulez collé)
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.center, // N'est plus nécessaire si le parent est .start
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
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 24,
                    ),
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
      IconButton(
        icon: const Icon(Icons.border_color, color: Colors.white), // 1. Catégories
        onPressed: () {
          // TODO: Implémenter l'action pour voir/gérer les catégories
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gestion des Catégories (TODO)')),
          );
        },
        tooltip: 'Catégories',
      ),
      IconButton(
        icon: const Icon(Icons.menu, color: Colors.white), // 2. Menu
        onPressed: () {
          // TODO: Implémenter l'action pour le menu principal
          // Par exemple, ouvrir un Drawer: Scaffold.of(context).openEndDrawer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonction secondaire (TODO)')),
          );
        },
        tooltip: 'Menu',
      ),
      IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white), // 3. More Horiz
        onPressed: () {
          // TODO: Implémenter l'action pour le menu "More Horiz" (ex: options supplémentaires)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parametres (TODO)')),
          );
        },
        tooltip: 'Plus d\'options',
      ),
    ];
  }

  Widget _buildReadyToAssignBanner(ThemeData theme) {
    // Si le montant est exactement 0, on ne retourne rien (la condition dans build() le gère déjà,
    // mais une double vérification ici ne fait pas de mal ou on peut la retirer si on est sûr de l'appelant).
    // Pour cet exemple, je vais supposer que l'appelant (build()) gère déjà le cas == 0.

    Color bannerColor;
    String title;
    IconData? leadingIcon; // Icône optionnelle pour le cas négatif

    if (_montantPretAPlacer > 0) {
      bannerColor = const Color(0xFF6CC53A); // Vert pour positif
      title = "Prêt à Placer";
      leadingIcon = null; // Pas d'icône spécifique pour le positif, ou une icône de "check" si vous voulez
    } else { // _montantPretAPlacer < 0
      bannerColor = Colors.red[600]!; // Rouge pour négatif
      title = "Sur-alloué"; // Ou "À Couvrir", "Déficit", etc.
      leadingIcon = Icons.warning_amber_rounded; // Icône d'avertissement
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: InkWell(
        onTap: () {
          // L'action peut être différente si le montant est négatif
          if (_montantPretAPlacer > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prêt à Placer cliqué (TODO)')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Montant sur-alloué cliqué (TODO)')),
            );
          }
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          height: 64, // Vous pourriez vouloir ajuster la hauteur si l'icône prend plus de place
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Section de gauche (Montant et potentiellement icône)
              Row(
                children: [
                  if (leadingIcon != null) // Affiche l'icône seulement si elle est définie (pour le cas négatif)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(leadingIcon, color: Colors.white, size: 28),
                    ),
                  Text(
                    // Afficher la valeur absolue pour le montant, le signe est géré par la couleur/texte
                    "${_montantPretAPlacer.abs().toStringAsFixed(2)}\$",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32, // Ajustez si l'icône prend trop de place
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Section de droite (Titre et chevron)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title, // Titre dynamique
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: const Icon(
                        Icons.chevron_right, color: Colors.white, size: 20),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewTransactionsBanner(ThemeData theme) {
    if (_nombreTransactionsARevoir == 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transactions à Revoir cliquées (TODO)')),
        );
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white, fontSize: 16) ??
                    const TextStyle(color: Colors.white, fontSize: 16),
                children: <TextSpan>[
                  const TextSpan(text: 'Revoir '),
                  TextSpan(
                    text: '$_nombreTransactionsARevoir',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _nombreTransactionsARevoir > 1
                      ? ' transactions'
                      : ' transaction'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    if (_categoriesDuBudget.isEmpty && _nombreTransactionsARevoir == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                  Icons.category_outlined, color: Colors.white38, size: 48),
              const SizedBox(height: 16),
              Text(
                "Aucune catégorie budgétaire pour ce mois.",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Commencez par créer des catégories et des enveloppes pour organiser votre budget.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: _categoriesDuBudget.map((categorie) {
          return _buildCategorieItem(theme, categorie);
        }).toList(),
      ),
    );
  }

  Widget _buildCategorieItem(ThemeData theme, CategorieBudgetModel categorie) {
    bool estDepliee = _etatsDepliageCategories[categorie.id] ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _etatsDepliageCategories[categorie.id] = !estDepliee;
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  estDepliee ? Icons.keyboard_arrow_down : Icons
                      .keyboard_arrow_right,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categorie.nom,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ) ??
                        const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                  ),
                ),
                Text(
                  categorie.info,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ) ??
                      TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.white24,
            height: 0.5,
            thickness: 0.5,
            indent: 16,
            endIndent: 16),
        if (estDepliee)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                if (categorie.enveloppes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Center(
                      child: Text(
                        "Aucune enveloppe dans cette catégorie.",
                        style: TextStyle(color: Colors.white.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                            fontSize: 14),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8.0, left: 8, right: 8),
                    child: Column(
                      children: categorie.enveloppes.map((enveloppe) {
                        return _buildEnveloppeItem(theme, enveloppe);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEnveloppeItem(ThemeData theme, EnveloppeModel enveloppe) {
    double progression = 0.0;
    Color couleurBulle = Colors.grey[700]!;
    Color couleurTexteBulle = Colors.white;
    Color couleurBarre = Colors.transparent;

    if (enveloppe.montantBudgete > 0) {
      progression =
          (enveloppe.montantAlloue / enveloppe.montantBudgete).clamp(0.0, 1.0);
      if (enveloppe.montantAlloue >= enveloppe.montantBudgete) {
        couleurBulle = Colors.green[400]!;
        couleurTexteBulle = Colors.black87;
        couleurBarre = Colors.greenAccent[400]!;
      } else if (enveloppe.montantAlloue > 0) {
        couleurBulle = Colors.orange[600]!;
        couleurTexteBulle = Colors.white;
        couleurBarre = Colors.orangeAccent[400]!;
      } else {
        couleurBulle = Colors.red[400]!;
        couleurTexteBulle = Colors.white;
        couleurBarre = Colors.redAccent[100]!.withOpacity(0.7);
      }
    } else {
      if (enveloppe.montantAlloue > 0) {
        couleurBulle = Colors.blue[300]!;
        couleurTexteBulle = Colors.black87;
      } else if (enveloppe.montantAlloue < 0) {
        couleurBulle = Colors.red[400]!;
        couleurTexteBulle = Colors.white;
      }
    }

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Enveloppe "${enveloppe.nom}" cliquée (TODO)')),
        );
      },
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  child: enveloppe.icone != null
                      ? Icon(enveloppe.icone, color: Colors.white70, size: 20)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    enveloppe.nom,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white, fontSize: 15) ??
                        const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                Container(
                  height: 30,
                  constraints: const BoxConstraints(minWidth: 70),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: couleurBulle,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Center(
                    child: Text(
                      "${enveloppe.montantAlloue.toStringAsFixed(2)}\$",
                      style: TextStyle(
                        color: couleurTexteBulle,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (progression > 0.0 && enveloppe.montantBudgete > 0)
              Padding(
                padding: EdgeInsets.only(top: 8.0, left: 40.0, right: 8.0),
                child: Container(
                  height: 4,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2)
                  ),
                  child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * progression,
                            decoration: BoxDecoration(
                              color: couleurBarre,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }
                  ),
                ),
              ),
            if (enveloppe.messageSous != null &&
                enveloppe.messageSous!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    top: (progression > 0.0 && enveloppe.montantBudgete > 0)
                        ? 6.0
                        : 8.0, left: 40.0, right: 8.0),
                child: Text(
                  enveloppe.messageSous!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6), fontSize: 11) ??
                      TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}