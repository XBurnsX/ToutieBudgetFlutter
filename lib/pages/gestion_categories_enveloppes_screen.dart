import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/EnveloppeCard.dart'; // ASSUREZ-VOUS QUE CE CHEMIN EST CORRECT ET CONTIENT EnveloppeTestData et TypeObjectif

// import './reorder_screen.dart'; // Décommentez lorsque la page de réorganisation existera

class Categorie {
  String id;
  String nom;
  List<EnveloppeTestData> enveloppes;

  Categorie({
    required this.id,
    required this.nom,
    List<EnveloppeTestData>? enveloppes,
  }) : enveloppes = enveloppes ?? [];
}

class GestionCategoriesEnveloppesScreen extends StatefulWidget {
  const GestionCategoriesEnveloppesScreen({Key? key}) : super(key: key);

  @override
  State<GestionCategoriesEnveloppesScreen> createState() =>
      _GestionCategoriesEnveloppesScreenState();
}

class _GestionCategoriesEnveloppesScreenState
    extends State<GestionCategoriesEnveloppesScreen> {
  // <--- DÉBUT DE LA CLASSE STATE

  final currencyFormatter =
  NumberFormat.currency(locale: 'fr_CA', symbol: '\$');

  final List<Categorie> _categories = [];

  final TextEditingController _nomCategorieController = TextEditingController();
  final TextEditingController _nomEnveloppeController = TextEditingController();

  // Pas de méthode initState ou dispose nécessaire pour ces contrôleurs s'ils sont
  // utilisés uniquement dans des dialogues qui gèrent leur propre cycle de vie.
  // Cependant, si les contrôleurs étaient membres de la classe pour un TextField
  // directement dans le widget build de cet écran, initState et dispose seraient nécessaires.

  double _calculerTotalObjectifsMensuels() {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    double total = 0.0;
    for (var categorie in _categories) {
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
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    return DateFormat('MMMM', 'fr_FR').format(DateTime.now());
  }

  void _ajouterCategorie() {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    if (_nomCategorieController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le nom de la catégorie ne peut pas être vide.')),
      );
      return;
    }
    setState(() {
      final nouvelleCategorie = Categorie(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        nom: _nomCategorieController.text.trim(),
      );
      _categories.add(nouvelleCategorie);
      _nomCategorieController.clear();
    });
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _afficherDialogueAjoutCategorie() {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
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
                _ajouterCategorie();
              },
            ),
          ],
        );
      },
    );
  }

  void _ajouterEnveloppe(Categorie categorie) {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    if (_nomEnveloppeController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Le nom de l'enveloppe ne peut pas être vide.")),
      );
      return;
    }
    setState(() {
      int defaultColorValue = Colors.grey.value;
      if (categorie.enveloppes.isNotEmpty) {
        defaultColorValue = categorie.enveloppes.first.couleurThemeValue;
      } else if (_categories.isNotEmpty &&
          _categories.first.enveloppes.isNotEmpty) {
        defaultColorValue =
            _categories.first.enveloppes.first.couleurThemeValue;
      }

      final nouvelleEnveloppe = EnveloppeTestData(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        nom: _nomEnveloppeController.text.trim(),
        soldeActuel: 0.0,
        montantAlloue: 0.0,
        typeObjectif: TypeObjectif.aucun,
        couleurThemeValue: defaultColorValue,
        couleurSoldeCompteValue: defaultColorValue,
      );
      categorie.enveloppes.add(nouvelleEnveloppe);
      _nomEnveloppeController.clear();
    });
    Navigator.of(context).pop();
  }

  void _afficherDialogueAjoutEnveloppe(Categorie categorie) {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
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
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () => _ajouterEnveloppe(categorie),
            ),
          ],
        );
      },
    );
  }

  void _navigateToReorderScreen() {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    print('Navigation vers la page de réorganisation demandée.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page de réorganisation non implémentée.')),
    );
  }

  @override
  void dispose() {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    _nomCategorieController.dispose();
    _nomEnveloppeController.dispose();
    super.dispose();
  }

  Widget _buildTrailingWidgetForEnveloppe(EnveloppeTestData enveloppe,
      ThemeData theme) {
    // <--- CETTE MÉTHODE EST MAINTENANT DANS LA CLASSE
    bool aUnObjectifDefini = enveloppe.typeObjectif != TypeObjectif.aucun &&
        enveloppe.montantCible != null &&
        enveloppe.montantCible! > 0;

    if (aUnObjectifDefini) {
      String objectifStr =
          'Obj: ${currencyFormatter.format(enveloppe.montantCible)}';
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
          print(
              'Naviguer pour définir/modifier l\'objectif pour ${enveloppe
                  .nom}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Définition d\'objectif pour ${enveloppe
                        .nom} non implémentée.')),
          );
        },
        child: Text('Ajouter objectif',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: theme.textTheme.bodySmall?.fontSize)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // <--- LA MÉTHODE BUILD EST ICI, DANS LA CLASSE
    final theme = Theme.of(context);
    final String nomMoisActuel = _getNomMoisActuel();
    final double totalObjectifsMensuels = _calculerTotalObjectifsMensuels();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
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
          if (totalObjectifsMensuels > 0 ||
              _categories.any((cat) =>
                  cat.enveloppes.any((env) =>
                  env.typeObjectif == TypeObjectif.mensuel)))
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
              child: Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Objectifs de ${nomMoisActuel
                            .substring(0, 1)
                            .toUpperCase()}${nomMoisActuel.substring(1)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(totalObjectifsMensuels),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _categories.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Aucune catégorie pour le moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Créer une catégorie'),
                      onPressed: _afficherDialogueAjoutCategorie,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(8.0).copyWith(
                  top: (totalObjectifsMensuels > 0 ||
                      _categories.any((cat) =>
                          cat.enveloppes
                              .any((env) =>
                          env.typeObjectif == TypeObjectif.mensuel)))
                      ? 8.0
                      : 12.0,
                  bottom: 80.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final categorie = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              categorie.nom,
                              style:
                              theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline,
                                      color: theme.colorScheme.primary),
                                  tooltip:
                                  'Ajouter une enveloppe à ${categorie.nom}',
                                  onPressed: () {
                                    _afficherDialogueAjoutEnveloppe(
                                        categorie);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  tooltip:
                                  'Options pour ${categorie.nom}',
                                  onPressed: () {
                                    print(
                                        'Options pour ${categorie.nom}');
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Options pour ${categorie
                                                  .nom} non implémentées.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Card(
                        elevation: 2.0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        margin:
                        const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            if (categorie.enveloppes.isNotEmpty)
                              ...categorie.enveloppes
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                int idx = entry.key;
                                EnveloppeTestData enveloppe = entry.value;
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(enveloppe.nom),
                                      trailing:
                                      _buildTrailingWidgetForEnveloppe(
                                          enveloppe, theme),
                                      onTap: () {
                                        print(
                                            'Voir/Modifier détails de ${enveloppe
                                                .nom}');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Détails de ${enveloppe
                                                      .nom} non implémentés.')),
                                        );
                                      },
                                    ),
                                    if (idx <
                                        categorie.enveloppes.length - 1)
                                      const Divider(
                                          height: 1,
                                          indent: 16,
                                          endIndent: 16),
                                  ],
                                );
                              }).toList()
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 24.0),
                                alignment: Alignment.center,
                                child: Text(
                                  'Aucune enveloppe dans cette catégorie.\nCliquez sur + pour en ajouter une.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.hintColor),
                                ),
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
      ),
    );
  }
} // <--- FIN DE LA CLASSE _GestionCategoriesEnveloppesScreenState. ASSUREZ-VOUS QUE C'EST LA TOUTE DERNIÈRE ACCOLADE DU FICHIER.