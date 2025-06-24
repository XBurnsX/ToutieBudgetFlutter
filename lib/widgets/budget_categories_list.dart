import 'package:flutter/material.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart'; // Contient List<EnveloppePourAffichageBudget>
import 'package:toutie_budget/models/compte_model.dart';

// Importez EnveloppePourAffichageBudget depuis ecran_budget.dart ou son propre fichier modèle
import 'package:toutie_budget/pages/ecran_budget.dart'
    show EnveloppePourAffichageBudget;
import 'package:toutie_budget/pages/gestion_categories_enveloppes_screen.dart'
    show GestionCategoriesEnveloppesScreen;

// import 'package:intl/intl.dart'; // Décommentez si vous utilisez currencyFormatter

class BudgetCategoriesList extends StatefulWidget {
  final List<CategorieBudgetModel> categories;
  final List<Compte> comptesActuels;
  final bool isLoading;
  final VoidCallback? onCreerCategorieDemandee;
  final DateTime moisAnneeCourant; // Ajoutez ceci

  const BudgetCategoriesList({
    super.key,
    required this.categories,
    required this.comptesActuels,
    required this.isLoading,
    required this.moisAnneeCourant, // Et ici
    this.onCreerCategorieDemandee,
  });

  @override
  State<BudgetCategoriesList> createState() => _BudgetCategoriesListState();
}

class _BudgetCategoriesListState extends State<BudgetCategoriesList> {
  Map<String, bool> _etatsDepliageCategories = {};

  // final currencyFormatter = NumberFormat.currency(locale: 'fr_CA', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _initialiserEtatsDepliage();
  }

  @override
  void didUpdateWidget(covariant BudgetCategoriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories.length != oldWidget.categories.length ||
        !widget.categories.every((cat) =>
            oldWidget.categories.any((oldCat) => oldCat.id == cat.id)) ||
        widget.moisAnneeCourant != oldWidget
            .moisAnneeCourant // Si le mois change, on pourrait vouloir réinitialiser l'état de dépliage
    ) {
      _initialiserEtatsDepliage();
    }
  }

  void _initialiserEtatsDepliage() {
    // Si le mois change, on force la réinitialisation à 'fermé'
    // Sinon, on conserve l'état existant si possible.
    // Vous pouvez ajuster cette logique selon le comportement souhaité.
    bool forcerFermeture = _etatsDepliageCategories.isNotEmpty &&
        (widget.categories.isNotEmpty &&
            !_etatsDepliageCategories.containsKey(widget.categories.first
                .id)); // Heuristique simple pour détecter un changement majeur de données
    // ou si le mois a changé (déjà géré dans didUpdateWidget)

    if (forcerFermeture) {
      _etatsDepliageCategories = {
        for (var categorie in widget.categories)
          categorie.id: false,
        // Tout fermer si les catégories changent drastiquement ou le mois
      };
    } else {
      _etatsDepliageCategories = {
        for (var categorie in widget.categories)
          categorie.id: _etatsDepliageCategories[categorie.id] ?? false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool aucunCompteAvecSoldeInitialement = widget.comptesActuels
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
        subtitle: 'Organisez votre budget en allouant des fonds à différentes catégories et enveloppes.',
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
                () { // Utilisez le callback s'il est fourni
              Navigator.push(
                context,
                MaterialPageRoute(builder: (
                    context) => const GestionCategoriesEnveloppesScreen()),
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
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                textStyle: theme.textTheme.labelLarge,
              ),
              onPressed: onButtonPressed ?? () {
                print(
                    '$buttonLabel cliqué (action par défaut dans BudgetCategoriesList)');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorieItem(ThemeData theme, CategorieBudgetModel categorie) {
    bool estDeplie = _etatsDepliageCategories[categorie.id] ?? false;
    double progression = 0;
    if (categorie.alloueTotal > 0) {
      progression = categorie.depenseTotal / categorie.alloueTotal;
    }
    progression = progression.clamp(0.0, 1.0);

    Color couleurDeBase = categorie.couleur;
    Color couleurBarreEtTexteDisponible = couleurDeBase;

    if (categorie.disponibleTotal < 0) {
      couleurBarreEtTexteDisponible = Colors.red[400]!;
    } else if (progression == 1.0) {
      couleurBarreEtTexteDisponible = HSLColor.fromColor(couleurDeBase)
          .withSaturation(0.7)
          .withLightness(HSLColor
          .fromColor(couleurDeBase)
          .lightness * 0.9)
          .toColor();
    } else if (progression > 0.85) {
      couleurBarreEtTexteDisponible = HSLColor.fromColor(couleurDeBase)
          .withLightness((HSLColor
          .fromColor(couleurDeBase)
          .lightness * 0.85).clamp(0.0, 1.0))
          .toColor();
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
                          color: couleurBarreEtTexteDisponible,
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
                  backgroundColor: couleurDeBase.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      couleurBarreEtTexteDisponible),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ),
        if (estDeplie)
          Container(
            color: Colors.grey[900],
            child: Column(
              // categorie.enveloppes est maintenant List<EnveloppePourAffichageBudget>
              children: categorie.enveloppes.map((enveloppeAffichee) {
                return _buildEnveloppeItem(
                    theme, enveloppeAffichee, couleurDeBase);
              }).toList(),
            ),
          ),
        Divider(height: 1, color: Colors.grey[700]),
      ],
    );
  }

  // MODIFIÉ: Le paramètre `enveloppe` est maintenant de type EnveloppePourAffichageBudget
  Widget _buildEnveloppeItem(ThemeData theme,
      EnveloppePourAffichageBudget enveloppe,
      Color couleurCategorieParente) {
    double progression = 0;
    if (enveloppe.montantAlloue >
        0) { // Utilise enveloppe.montantAlloue de EnveloppePourAffichageBudget
      progression = (enveloppe.depense /
          enveloppe.montantAlloue); // Utilise enveloppe.depense
    }
    progression = progression.clamp(0.0, 1.0);

    // La couleur de l'enveloppe vient directement de EnveloppePourAffichageBudget
    Color couleurDeBaseEnveloppe = enveloppe.couleur;
    Color couleurBarreEtTexteDisponibleEnveloppe = couleurDeBaseEnveloppe;

    // Utilise enveloppe.disponible de EnveloppePourAffichageBudget
    if (enveloppe.disponible < 0) {
      couleurBarreEtTexteDisponibleEnveloppe = Colors.redAccent[200]!;
    } else if (progression == 1.0) {
      couleurBarreEtTexteDisponibleEnveloppe =
          HSLColor.fromColor(couleurDeBaseEnveloppe)
              .withSaturation(0.6)
              .toColor();
    } else if (progression > 0.85) {
      couleurBarreEtTexteDisponibleEnveloppe =
          HSLColor.fromColor(couleurDeBaseEnveloppe)
              .withLightness((HSLColor
              .fromColor(couleurDeBaseEnveloppe)
              .lightness * 0.9).clamp(0.0, 1.0))
              .toColor();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('Enveloppe ${enveloppe
              .nom} cliquée (depuis BudgetCategoriesList)');
          // TODO: Gérer la navigation/action, potentiellement via un callback
          // Exemple: widget.onEnveloppeTap?.call(enveloppe); // Si vous ajoutez un tel callback
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: <Widget>[
                  // Utilise enveloppe.icone de EnveloppePourAffichageBudget
                  if (enveloppe.icone != null) ...[
                    Icon(enveloppe.icone,
                        color: HSLColor.fromColor(couleurDeBaseEnveloppe)
                            .withAlpha(200)
                            .toColor(),
                        size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    // Utilise enveloppe.nom de EnveloppePourAffichageBudget
                    child: Text(
                      enveloppe.nom,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Utilise enveloppe.disponible de EnveloppePourAffichageBudget
                  Text(
                    '${enveloppe.disponible.toStringAsFixed(2)} \$',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: couleurBarreEtTexteDisponibleEnveloppe,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              // Utilise enveloppe.messageSous de EnveloppePourAffichageBudget
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
                  backgroundColor: couleurDeBaseEnveloppe.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      couleurBarreEtTexteDisponibleEnveloppe),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}