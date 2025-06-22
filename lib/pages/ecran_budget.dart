import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importez vos modèles si nécessaire
// import 'package:toutie_budget/models/compte_model.dart';
// import 'package:toutie_budget/models/categorie_budget_model.dart';
// import 'package:toutie_budget/models/enveloppe_model.dart';

class EcranBudget extends StatefulWidget {
  const EcranBudget({super.key});

  @override
  State<EcranBudget> createState() => _EcranBudgetState();
}

class _EcranBudgetState extends State<EcranBudget> {
  DateTime _moisAnneeCourant = DateTime.now();

  // bool _showCategories = true; // Utilisé si vous réintroduisez le sélecteur Categories/Spotlight

  @override
  void initState() {
    super.initState();
    // Initialiser les données si nécessaire
  }

  // --- MÉTHODES POUR LA GESTION DE LA DATE ---
  void _moisPrecedent() {
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month - 1, 1);
    });
  }

  void _moisSuivant() {
    setState(() {
      _moisAnneeCourant =
          DateTime(_moisAnneeCourant.year, _moisAnneeCourant.month + 1, 1);
    });
  }

  void _showDatePickerDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _moisAnneeCourant,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _moisAnneeCourant) {
      setState(() {
        _moisAnneeCourant = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        // Couleur de fond de l'AppBar
        elevation: 0,
        // Pas d'ombre sous l'AppBar
        automaticallyImplyLeading: false,
        // Enlève le bouton "retour" si pas nécessaire
        titleSpacing: 0,
        // Enlève l'espacement par défaut du titre
        title: _buildCustomAppBarTitle(theme),
        actions: _buildAppBarActions(theme),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Si le texte "Budget" persiste, il est probablement ici ou dans un widget parent non visible dans ce fichier.
          // Utilisez le Flutter Inspector pour le localiser.

          // Bandeau "Ready to Assign"
          _buildReadyToAssignBanner(theme),

          // Bandeau "Review X transaction"
          _buildReviewTransactionsBanner(theme),

          // Sections de Catégories / Enveloppes
          _buildCategoriesSection(theme),
          // Si vous réintroduisez un sélecteur pour Spotlight :
          // if (_showCategories)
          //   _buildCategoriesSection(theme)
          // else
          //   _buildSpotlightSection(theme),

          const SizedBox(height: 80),
          // Espace en bas
        ],
      ),
    );
  }

  // Widget pour le contenu du titre de l'AppBar (Sélecteur de Mois/Année)
  Widget _buildCustomAppBarTitle(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: _moisPrecedent,
            tooltip: 'Mois précédent',
            splashRadius: 24, // Rayon de l'effet d'encre
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showDatePickerDialog,
              child: Container(
                color: Colors.transparent,
                // Permet au GestureDetector de fonctionner sur toute la zone
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
          IconButton(
            icon: const Icon(
                Icons.chevron_right, color: Colors.white, size: 28),
            onPressed: _moisSuivant,
            tooltip: 'Mois suivant',
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  // Widget pour les actions à droite de l'AppBar
  List<Widget> _buildAppBarActions(ThemeData theme) {
    return [
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Icône Recherche cliquée (TODO)')),
          );
        },
        tooltip: 'Rechercher',
      ),
      IconButton(
        icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Icône Profil cliquée (TODO)')),
          );
        },
        tooltip: 'Profil',
      ),
      // Exemple de PopupMenuButton si vous avez besoin de plus d'options:
      // PopupMenuButton<String>(
      //   icon: const Icon(Icons.more_vert, color: Colors.white),
      //   tooltip: 'Plus d\'options',
      //   onSelected: (String value) {
      //     // Logique pour l'élément sélectionné
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Option sélectionnée: $value')),
      //     );
      //   },
      //   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      //     const PopupMenuItem<String>(
      //       value: 'option1',
      //       child: Text('Option 1'),
      //     ),
      //     const PopupMenuItem<String>(
      //       value: 'option2',
      //       child: Text('Option 2'),
      //     ),
      //   ],
      // ),
    ];
  }

  // 4. Bandeau "Ready to Assign"
  Widget _buildReadyToAssignBanner(ThemeData theme) {
    double montantPretAPlacer = 114.65; // TODO: Remplacer par les vraies données

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      // Ajout d'un peu de padding en haut
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bandeau Prêt à Placer cliqué (TODO)')),
          );
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF6CC53A),
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
              Text(
                "${montantPretAPlacer.toStringAsFixed(2)}\$",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Prêt à Placer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 5. Bandeau "Review X transaction"
  Widget _buildReviewTransactionsBanner(ThemeData theme) {
    int nombreTransactionsARevoir = 1; // TODO: Remplacer par les vraies données

    if (nombreTransactionsARevoir == 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bandeau Transactions à Revoir cliqué (TODO)')),
        );
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16
                ) ?? const TextStyle(color: Colors.white, fontSize: 16),
                children: <TextSpan>[
                  const TextSpan(text: 'Revoir '),
                  TextSpan(
                    text: '$nombreTransactionsARevoir',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: nombreTransactionsARevoir > 1
                      ? ' transactions'
                      : ' transaction'),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 6. & 7. Section des Catégories et Enveloppes
  Widget _buildCategoriesSection(ThemeData theme) {
    // TODO: Alimenter par des données réelles
    final List<Map<String, dynamic>> categoriesFactices = [
      {
        'nom': 'Paiements Carte de Crédit',
        'info': 'Disponible pour Paiement',
        'enveloppes': [
          {
            'nom': 'Visa XYZ',
            'montant': 0.00,
            'couleurBulle': Colors.grey[400],
            'couleurTexteBulle': Colors.black,
            'messageSous': null,
            'icone': null,
            'barreProgression': 0.0,
            'couleurBarre': Colors.transparent
          },
        ],
        'estDepliee': true, // TODO: Gérer cet état dynamiquement
      },
      {
        'nom': 'Dépenses Obligatoires',
        'info': 'Disponible à Dépenser',
        'enveloppes': [
          {
            'nom': 'Loyer',
            'montant': 1250.00,
            'couleurBulle': Colors.green[300],
            'couleurTexteBulle': Colors.black,
            'messageSous': 'Objectif: 1250\$',
            'icone': Icons.home_work_outlined,
            'barreProgression': 1.0,
            'couleurBarre': Colors.greenAccent
          },
          {
            'nom': 'Affirm',
            'montant': 0.00,
            'couleurBulle': Colors.orange[600],
            'couleurTexteBulle': Colors.black,
            'messageSous': '42.88\$ de plus requis avant le 19',
            'icone': Icons.payment,
            'barreProgression': 0.5,
            'couleurBarre': Colors.orangeAccent
          },
          {
            'nom': 'Chômage',
            'montant': 0.00,
            'couleurBulle': Colors.grey[400],
            'couleurTexteBulle': Colors.black,
            'messageSous': null,
            'icone': Icons.eco,
            'barreProgression': 0.0,
            'couleurBarre': Colors.transparent
          },
        ],
        'estDepliee': true, // TODO: Gérer cet état dynamiquement
      }
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: categoriesFactices.map((categorieData) {
          return _buildCategorieItem(theme, categorieData);
        }).toList(),
      ),
    );
  }

  Widget _buildCategorieItem(ThemeData theme,
      Map<String, dynamic> categorieData) {
    bool estDepliee = categorieData['estDepliee'] ??
        false; // TODO: Lier à un état réel

    return Column(
      children: [
        InkWell(
          onTap: () {
            // TODO: Logique pour déplier/replier la catégorie.
            // Vous devrez gérer l'état 'estDepliee' pour chaque catégorie.
            // Par exemple, en utilisant un Map<String, bool> dans le _EcranBudgetStat_e
            // où la clé est l'ID de la catégorie et la valeur est son état de dépliage.
            // Puis, dans setState, vous mettez à jour cette map.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                  'Catégorie ${categorieData['nom']} cliquée (TODO: déplier/replier)')),
            );
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
                    categorieData['nom'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ) ?? const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Text(
                  categorieData['info'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ) ?? TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.grey,
            height: 0.5,
            thickness: 0.5,
            indent: 16,
            endIndent: 16),
        if (estDepliee)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: (categorieData['enveloppes'] as List<
                  Map<String, dynamic>>).map((enveloppeData) {
                return _buildEnveloppeItem(theme, enveloppeData);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEnveloppeItem(ThemeData theme,
      Map<String, dynamic> enveloppeData) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Enveloppe ${enveloppeData['nom']} cliquée (TODO)')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (enveloppeData['icone'] != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                        enveloppeData['icone'], color: Colors.white, size: 20),
                  )
                else
                  const SizedBox(width: 32),
                // Espace si pas d'icône pour aligner le texte
                Expanded(
                  child: Text(
                    enveloppeData['nom'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 16
                    ) ?? const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Container(
                  height: 32,
                  constraints: const BoxConstraints(minWidth: 70),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: enveloppeData['couleurBulle'] ?? Colors.grey[400],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Center(
                    child: Text(
                      "${(enveloppeData['montant'] as double).toStringAsFixed(
                          2)}\$",
                      style: TextStyle(
                        color: enveloppeData['couleurTexteBulle'] ??
                            Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Barre de progression
            if (enveloppeData['barreProgression'] != null &&
                (enveloppeData['barreProgression'] as double) > 0.0)
              Padding(
                  padding: EdgeInsets.only(top: 6.0,
                      left: (enveloppeData['icone'] != null ? 32.0 : 0.0)),
                  child: Container(
                    height: 3,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      // Piste de la barre (optionnel, pour montrer où la barre va se remplir)
                      // color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1.5)
                    ),
                    child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth *
                                  (enveloppeData['barreProgression'] as double)
                                      .clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                  color: enveloppeData['couleurBarre'] ??
                                      Colors.greenAccent,
                                  borderRadius: BorderRadius.circular(1.5)
                              ),
                            ),
                          );
                        }
                    ),
                  )
              ),
            // Message sous l'enveloppe
            if (enveloppeData['messageSous'] != null)
              Padding(
                padding: EdgeInsets.only(top: 4.0,
                    left: (enveloppeData['icone'] != null ? 32.0 : 0.0)),
                child: Text(
                  enveloppeData['messageSous'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ) ?? TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ),
            const SizedBox(height: 8.0), // Espace avant le séparateur
            const Divider(color: Colors.grey,
                height: 0.5,
                thickness: 0.5,
                indent: 0,
                endIndent: 0),
          ],
        ),
      ),
    );
  }

// Placeholder pour la vue "Spotlight" - à décommenter et implémenter si vous ajoutez un sélecteur
/*
  Widget _buildSpotlightSection(ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Vue Spotlight (À implémenter)',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
  */
}