import 'package:flutter/material.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart';
import 'package:toutie_budget/models/compte_model.dart'; // Nécessaire pour la logique d'affichage initial

class BudgetCategoriesList extends StatefulWidget {
  final List<CategorieBudgetModel> categories;
  final List<
      Compte> comptesActuels; // Pour la logique d'affichage "Commencez..."
  final bool isLoading; // Pour afficher un indicateur de chargement si nécessaire

  const BudgetCategoriesList({
    super.key,
    required this.categories,
    required this.comptesActuels,
    required this.isLoading,
  });

  @override
  State<BudgetCategoriesList> createState() => _BudgetCategoriesListState();
}

class _BudgetCategoriesListState extends State<BudgetCategoriesList> {
  // L'état de dépliage est maintenant géré à l'intérieur de ce widget
  Map<String, bool> _etatsDepliageCategories = {};

  @override
  void initState() {
    super.initState();
    _initialiserEtatsDepliage();
  }

  @override
  void didUpdateWidget(covariant BudgetCategoriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la liste des catégories change, réinitialiser les états de dépliage
    // Cela évite de garder des états pour des catégories qui n'existent plus
    // ou d'en manquer pour de nouvelles.
    if (widget.categories.length != oldWidget.categories.length ||
        !widget.categories
            .every((cat) =>
            oldWidget.categories.any((oldCat) => oldCat.id == cat.id))) {
      _initialiserEtatsDepliage();
    }
  }

  void _initialiserEtatsDepliage() {
    _etatsDepliageCategories = Map.fromIterable(
      widget.categories,
      key: (item) => (item as CategorieBudgetModel).id,
      value: (item) =>
      _etatsDepliageCategories[(item as CategorieBudgetModel).id] ?? false,
      // Conserve l'état existant si possible, sinon false
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool aucunCompteAvecSolde = widget.comptesActuels
        .where((c) => c.soldeActuel != 0)
        .isEmpty;

    // ----- Logique d'affichage des messages ou du loader -----
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    if (widget.categories.isEmpty && aucunCompteAvecSolde) {
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
                  print(
                      'Naviguer vers la création de catégorie (depuis BudgetCategoriesList)');
                  // TODO: Idéalement, ce bouton devrait appeler un callback
                  // passé en paramètre pour gérer la navigation dans EcranBudget
                  // Exemple: widget.onCreerCategorie?.call();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (widget.categories.isEmpty && !aucunCompteAvecSolde) {
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

    // ----- Affichage de la liste des catégories -----
    return Column(
      children: widget.categories.map((categorie) =>
          _buildCategorieItem(theme, categorie)).toList(),
    );
  }

  // Les méthodes _buildCategorieItem et _buildEnveloppeItem sont copiées ici
  // depuis _EcranBudgetState, avec quelques ajustements minimes.

  Widget _buildCategorieItem(ThemeData theme, CategorieBudgetModel categorie) {
    bool estDeplie = _etatsDepliageCategories[categorie.id] ?? false;
    // La logique de calcul de progression, couleurDeBase, couleurBarreEtTexteDisponible
    // reste la même que dans EcranBudget.
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
      couleurBarreEtTexteDisponible =
          HSLColor.fromColor(couleurDeBase).withSaturation(0.7).withLightness(
              HSLColor
                  .fromColor(couleurDeBase)
                  .lightness * 0.9).toColor();
    } else if (progression > 0.85) {
      couleurBarreEtTexteDisponible =
          HSLColor.fromColor(couleurDeBase).withLightness((HSLColor
              .fromColor(couleurDeBase)
              .lightness * 0.85).clamp(0.0, 1.0)).toColor();
    }

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() { // setState est maintenant celui de _BudgetCategoriesListState
              _etatsDepliageCategories[categorie.id] = !estDeplie;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0),
            color: Colors.grey[850], // Ou la couleur de votre choix
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
            color: Colors.grey[900], // Ou la couleur de votre choix
            child: Column(
              children: categorie.enveloppes.map((enveloppe) {
                return _buildEnveloppeItem(theme, enveloppe, couleurDeBase);
              }).toList(),
            ),
          ),
        Divider(height: 1, color: Colors.grey[700]),
      ],
    );
  }

  Widget _buildEnveloppeItem(ThemeData theme, EnveloppeModel enveloppe,
      Color couleurCategorieParente) {
    // La logique de calcul de progression, couleurDeBaseEnveloppe, couleurBarreEtTexteDisponibleEnveloppe
    // reste la même que dans EcranBudget.
    double progression = 0;
    if (enveloppe.montantAlloue > 0) {
      progression = (enveloppe.depense / enveloppe.montantAlloue);
    }
    progression = progression.clamp(0.0, 1.0);

    Color couleurDeBaseEnveloppe = enveloppe.couleur ??
        HSLColor.fromColor(couleurCategorieParente).withLightness((HSLColor
            .fromColor(couleurCategorieParente)
            .lightness * 0.8).clamp(0.0, 1.0)).toColor();
    Color couleurBarreEtTexteDisponibleEnveloppe = couleurDeBaseEnveloppe;

    if (enveloppe.disponible < 0) {
      couleurBarreEtTexteDisponibleEnveloppe = Colors.redAccent[200]!;
    } else if (progression == 1.0) {
      couleurBarreEtTexteDisponibleEnveloppe =
          HSLColor
              .fromColor(couleurDeBaseEnveloppe)
              .withSaturation(0.6)
              .toColor();
    } else if (progression > 0.85) {
      couleurBarreEtTexteDisponibleEnveloppe =
          HSLColor.fromColor(couleurDeBaseEnveloppe).withLightness((HSLColor
              .fromColor(couleurDeBaseEnveloppe)
              .lightness * 0.9).clamp(0.0, 1.0)).toColor();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('Enveloppe ${enveloppe
              .nom} cliquée (depuis BudgetCategoriesList)');
          // TODO: Gérer la navigation/action, potentiellement via un callback
          // widget.onEnveloppeTap?.call(enveloppe);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: <Widget>[
                  if (enveloppe.icone != null) ...[
                    Icon(enveloppe.icone,
                        color: HSLColor.fromColor(couleurDeBaseEnveloppe)
                            .withAlpha(200)
                            .toColor(), size: 20),
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
                        color: couleurBarreEtTexteDisponibleEnveloppe,
                        fontWeight: FontWeight.w500),
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