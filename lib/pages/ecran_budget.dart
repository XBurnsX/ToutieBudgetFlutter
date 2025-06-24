// lib/pages/ecran_budget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

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
  DateTime _moisAnneeCourant = DateTime(DateTime.now().year, DateTime.now().month, 1);

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
    // ... votre code existant pour charger les données
    // (Assurez-vous qu'il est fonctionnel ou qu'il contient des données de test)
    if (!mounted) return;

    // Simulation et réinitialisation des données (TEMPORAIRE)
    setState(() {
      _montantPretAPlacer = 123.45;
      _nombreTransactionsARevoir = 2;
      _categoriesDuBudget = [ /* ... vos données de test ... */ ];
      _etatsDepliageCategories = { /* ... vos états de dépliage ... */ };
    });
  }

  void _moisPrecedent() {
    setState(() {
      _moisAnneeCourant = DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month - 1, 1);
    });
    _chargerDonneesBudget();
  }

  void _moisSuivant() {
    setState(() {
      _moisAnneeCourant = DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month + 1, 1);
    });
    _chargerDonneesBudget();
  }

  // --- 1. PLACEZ LA MÉTHODE _handleDateTap ICI ---
  void _handleDateTap() async {
    final DateTime? picked = await _showCustomMonthYearPicker(context);

    if (picked != null && (picked.year != _moisAnneeCourant.year || picked.month != _moisAnneeCourant.month)) {
      setState(() {
        _moisAnneeCourant = DateTime(picked.year, picked.month, 1);
      });
      _chargerDonneesBudget(); // Recharge les données pour le nouveau mois/année
    }
  }

  // --- 2. PLACEZ LA MÉTHODE _showCustomMonthYearPicker ICI ---
  Future<DateTime?> _showCustomMonthYearPicker(BuildContext context) async {
    DateTime tempPickedDate = _moisAnneeCourant;

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            // Initialisation de la liste des noms de mois DANS le builder pour
            // qu'elle se mette à jour si l'année change.
            List<String> moisNoms = List.generate(12, (index) {
              // Utilise la locale 'fr_FR' pour obtenir les noms des mois en français
              // Assurez-vous que initializeDateFormatting('fr_FR', null); a été appelé dans main().
              return DateFormat.MMM('fr_FR').format(DateTime(tempPickedDate.year, index + 1));
            });


            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E), // Couleur de fond du dialogue
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      stfSetState(() { // Mettre à jour l'état du dialogue
                        tempPickedDate = DateTime(tempPickedDate.year - 1, tempPickedDate.month);
                      });
                    },
                  ),
                  Text(
                    DateFormat.y('fr_FR').format(tempPickedDate), // Affiche l'année
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      stfSetState(() { // Mettre à jour l'état du dialogue
                        tempPickedDate = DateTime(tempPickedDate.year + 1, tempPickedDate.month);
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
                  itemCount: moisNoms.length, // Toujours 12 mois
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 mois par ligne pour un look plus compact
                    childAspectRatio: 2,   // Ratio largeur/hauteur des boutons de mois
                    mainAxisSpacing: 8,    // Espace vertical entre les boutons
                    crossAxisSpacing: 8,   // Espace horizontal entre les boutons
                  ),
                  itemBuilder: (BuildContext itemContext, int index) {
                    final moisDateTime = DateTime(tempPickedDate.year, index + 1);
                    // Vérifie si ce mois est le mois actuellement sélectionné ET affiché sur l'écran principal
                    bool isCurrentlySelectedOnScreen = moisDateTime.month == _moisAnneeCourant.month && moisDateTime.year == _moisAnneeCourant.year;
                    // Vérifie si ce mois est celui qui est "hovered" ou "pré-sélectionné" dans le picker
                    // Pour l'instant, pas de notion de "hover" distincte, on se base sur le mois de tempPickedDate
                    // bool isMonthInPickerSelected = moisDateTime.month == tempPickedDate.month;


                    return ElevatedButton( // Utiliser ElevatedButton pour un style plus visible
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentlySelectedOnScreen
                            ? Theme.of(context).primaryColor // Couleur primaire si c'est le mois actif à l'écran
                            : const Color(0xFF333333), // Couleur de fond pour les autres mois
                        foregroundColor: Colors.white, // Couleur du texte
                        padding: EdgeInsets.zero, // Pas de padding interne pour que le texte soit centré
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                          moisNoms[index], // Le nom du mois ex: 'janv.'
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isCurrentlySelectedOnScreen ? FontWeight.bold : FontWeight.normal,
                          )
                      ),
                      onPressed: () {
                        // Pop avec la date construite à partir de l'année du picker et du mois cliqué
                        Navigator.pop(dialogContext, DateTime(tempPickedDate.year, index + 1, 1));
                      },
                    );
                  },
                ),
              ),
              // On ne met pas de 'actions' pour ne pas avoir de boutons OK/Annuler
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ... votre code de Scaffold ...
      appBar: AppBar(
        // ... votre code d'AppBar ...
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
            if (_montantPretAPlacer != 0)
              _buildReadyToAssignBanner(theme),
            _buildReviewTransactionsBanner(theme),
            _buildCategoriesSection(theme),
            const SizedBox(height: 80),
          ],
        ),
      ),
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
              // --- 3. MODIFIEZ L'APPEL onTap ICI ---
              onTap: _handleDateTap, // Appelle la nouvelle méthode de gestion
              child: Container(
                color: Colors.transparent, // Pour une meilleure zone de clic
                padding: EdgeInsets.zero, // Ou un léger padding si besoin
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
                "Aucune catégorie budgétaire.",
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