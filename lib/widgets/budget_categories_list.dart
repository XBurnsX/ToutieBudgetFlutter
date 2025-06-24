import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart';
import 'package:toutie_budget/models/compte_model.dart';
import 'package:toutie_budget/pages/ecran_budget.dart'
    show EnveloppePourAffichageBudget;
import 'package:toutie_budget/pages/gestion_categories_enveloppes_screen.dart'
    show GestionCategoriesEnveloppesScreen;

class BudgetCategoriesList extends StatefulWidget {
  final List<CategorieBudgetModel> categories;
  final List<Compte> comptesActuels;
  final bool isLoading;
  final VoidCallback? onCreerCategorieDemandee;
  final DateTime moisAnneeCourant;

  const BudgetCategoriesList({
    super.key,
    required this.categories,
    required this.comptesActuels,
    required this.isLoading,
    required this.moisAnneeCourant,
    this.onCreerCategorieDemandee,
  });

  @override
  State<BudgetCategoriesList> createState() => _BudgetCategoriesListState();
}

class _BudgetCategoriesListState extends State<BudgetCategoriesList> {
  // Map<String, bool> _etatsDepliageCategories = {}; // PLUS NÉCESSAIRE
  final currencyFormatter = NumberFormat.currency(
      locale: 'fr_CA', symbol: '\$');

  @override
  void initState() {
    super.initState();
    // _initialiserEtatsDepliage(); // PLUS NÉCESSAIRE
  }

  @override
  void didUpdateWidget(covariant BudgetCategoriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La logique de _initialiserEtatsDepliage n'est plus nécessaire si on ne déplie/replie plus
    // if (widget.categories.length != oldWidget.categories.length ||
    //     !widget.categories.every((cat) =>
    //         oldWidget.categories.any((oldCat) => oldCat.id == cat.id)) ||
    //     widget.moisAnneeCourant != oldWidget.moisAnneeCourant) {
    //   _initialiserEtatsDepliage();
    // }
  }

  // void _initialiserEtatsDepliage() { ... } // MÉTHODE PLUS NÉCESSAIRE

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool aucunCompteAvecSoldeInitialement =
        widget.comptesActuels
            .where((c) => c.soldeActuel != 0)
            .isEmpty;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    if (widget.categories.isEmpty && aucunCompteAvecSoldeInitialement) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.category_outlined,
        title: 'Commencez par créer des catégories',
        subtitle:
        'Organisez votre budget en allouant des fonds à différentes catégories et enveloppes.',
        buttonLabel: 'Créer une catégorie',
        onButtonPressed: widget.onCreerCategorieDemandee,
      );
    }

    if (widget.categories.isEmpty && !aucunCompteAvecSoldeInitialement) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.add_box_outlined,
        title: 'Aucune catégorie budgétaire',
        subtitle: 'Ajoutez des catégories pour commencer à répartir vos fonds.',
        buttonLabel: 'CRÉEZ VOTRE PREMIÈRE CATÉGORIE',
        onButtonPressed: widget.onCreerCategorieDemandee ??
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const GestionCategoriesEnveloppesScreen()),
              );
            },
      );
    }

    return Column(
      children: widget.categories
          .map((categorie) => _buildCategorieItem(theme, categorie))
          .toList(),
    );
  }

  Widget _buildEmptyState({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    // ... (aucun changement ici)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: theme.textTheme.labelLarge,
              ),
              onPressed: onButtonPressed ??
                      () {
                    print(
                        '$buttonLabel cliqué (action par défaut dans BudgetCategoriesList)');
                  },
            ),
          ],
        ),
      ),
    );
  }

  // MODIFICATIONS APPLIQUÉES ICI
  Widget _buildCategorieItem(ThemeData theme, CategorieBudgetModel categorie) {
    // bool estDeplie = _etatsDepliageCategories[categorie.id] ?? false; // PLUS NÉCESSAIRE

    Color couleurTexteDisponible = categorie.disponibleTotal >= 0
        ? (theme.brightness == Brightness.dark
        ? Colors.greenAccent[100]!
        : Colors.green[700]!)
        : (theme.brightness == Brightness.dark ? Colors.redAccent[100]! : Colors
        .red[700]!);

    return Column( // Garde le Column pour le Divider
      children: [
        Container( // Ce Container est l'en-tête de la catégorie
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: Colors.black,
          child: Row( // L'en-tête est maintenant une simple Row
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Disponible",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(categorie.disponibleTotal),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: couleurTexteDisponible,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // L'icône de flèche pour déplier/replier est supprimée
              // const SizedBox(width: 8),
              // Icon( ... ),
            ],
          ),
        ),
        // Les enveloppes sont maintenant toujours affichées
        Container(
          color: Colors.grey[900], // Fond pour la section des enveloppes
          child: Column(
            children: categorie.enveloppes.map((enveloppeAffichee) {
              return _buildEnveloppeItem(
                  theme, enveloppeAffichee, enveloppeAffichee.couleur);
            }).toList(),
          ),
        ),
        Divider(height: 1, color: Colors.grey[700]),
      ],
    );
  }

  Widget _buildEnveloppeItem(ThemeData theme,
      EnveloppePourAffichageBudget enveloppe,
      Color couleurDeBasePourEnveloppe) {
    // ... (aucun changement dans _buildEnveloppeItem)
    double progression = 0;
    if (enveloppe.montantAlloue > 0) {
      progression = (enveloppe.depense / enveloppe.montantAlloue);
    }
    progression = progression.clamp(0.0, 1.0);

    Color couleurBarreEtTexteDisponibleEnveloppe = couleurDeBasePourEnveloppe;

    if (enveloppe.disponible < 0) {
      couleurBarreEtTexteDisponibleEnveloppe = Colors.redAccent[100]!;
    } else if (progression == 1.0 && enveloppe.disponible == 0) {
      couleurBarreEtTexteDisponibleEnveloppe =
          HSLColor.fromColor(couleurDeBasePourEnveloppe)
              .withSaturation(0.5)
              .withLightness(HSLColor
              .fromColor(couleurDeBasePourEnveloppe)
              .lightness * 0.7)
              .toColor();
    } else if (progression > 0.85) {
      couleurBarreEtTexteDisponibleEnveloppe =
          HSLColor.fromColor(couleurDeBasePourEnveloppe)
              .withLightness((HSLColor
              .fromColor(couleurDeBasePourEnveloppe)
              .lightness * 0.85).clamp(0.0, 1.0))
              .toColor();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('Enveloppe ${enveloppe
              .nom} cliquée (depuis BudgetCategoriesList)');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (enveloppe.icone != null) ...[
                    Icon(enveloppe.icone,
                        color: HSLColor
                            .fromColor(couleurDeBasePourEnveloppe)
                            .withAlpha(220)
                            .toColor(),
                        size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      enveloppe.nom,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormatter.format(enveloppe.disponible),
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: couleurBarreEtTexteDisponibleEnveloppe,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
              if (enveloppe.messageSous != null &&
                  enveloppe.messageSous!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Padding(
                  padding: EdgeInsets.only(
                      left: enveloppe.icone != null ? 32 : 0),
                  child: Text(
                    enveloppe.messageSous!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[400], fontSize: 11.5),
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Padding(
                padding: EdgeInsets.only(
                    left: enveloppe.icone != null ? 32 : 0),
                child: LinearProgressIndicator(
                  value: progression,
                  backgroundColor: couleurDeBasePourEnveloppe.withOpacity(0.20),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      couleurBarreEtTexteDisponibleEnveloppe),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}