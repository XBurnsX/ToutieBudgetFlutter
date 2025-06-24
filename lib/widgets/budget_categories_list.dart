import 'package:flutter/material.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart';
import 'package:toutie_budget/models/compte_model.dart';
import '../pages/gestion_categories_enveloppes_screen.dart';
import '../pages/test_enveloppe_screen.dart';
// import 'package:intl/intl.dart'; // Décommentez si vous utilisez currencyFormatter

class BudgetCategoriesList extends StatefulWidget {
  final List<CategorieBudgetModel> categories;
  final List<Compte> comptesActuels;
  final bool isLoading;
  final VoidCallback? onCreerCategorieDemandee; // Callback pour demander la création

  const BudgetCategoriesList({
    super.key,
    required this.categories,
    required this.comptesActuels,
    required this.isLoading,
    this.onCreerCategorieDemandee, // Accepter le callback
  });

  @override
  State<BudgetCategoriesList> createState() => _BudgetCategoriesListState();
}

class _BudgetCategoriesListState extends State<BudgetCategoriesList> {
  Map<String, bool> _etatsDepliageCategories = {};

  // final currencyFormatter = NumberFormat.currency(locale: 'fr_CA', symbol: '\$'); // Définissez votre formateur ici si besoin

  @override
  void initState() {
    super.initState();
    _initialiserEtatsDepliage();
  }

  @override
  void didUpdateWidget(covariant BudgetCategoriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories.length != oldWidget.categories.length ||
        !widget.categories.every(
                (cat) =>
                oldWidget.categories.any((oldCat) => oldCat.id == cat.id))) {
      _initialiserEtatsDepliage();
    }
  }

  void _initialiserEtatsDepliage() {
    // Conserve l'état existant si possible, sinon initialise à false
    _etatsDepliageCategories = {
      for (var categorie in widget.categories)
        categorie.id: _etatsDepliageCategories[categorie.id] ?? false,
    };
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

    // Cas 1: Aucune catégorie ET aucun compte avec solde (tout début)
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

    // Cas 2: Aucune catégorie MAIS des comptes avec solde existent
    if (widget.categories.isEmpty && !aucunCompteAvecSoldeInitialement) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.add_box_outlined,
        title: 'Aucune catégorie budgétaire',
        subtitle: 'Ajoutez des catégories pour commencer à répartir vos fonds.',
        buttonLabel: 'CREEZ VOTRE PREMIERE CATEGORIE', // Optionnel: changez le label
        onButtonPressed: () {
          // ------ MODIFICATION ICI ------
          Navigator.push(
            context,
            // Pointe maintenant vers TestEnveloppeVisuelScreen
            // qui se trouve dans votre fichier test_enveloppe_screen.dart
            MaterialPageRoute(builder: (context) => const GestionCategoriesEnveloppesScreen()),
          );
        },
        // onButtonPressed: widget.onCreerCategorieDemandee, // Ancienne action
      );
    }

    // ----- Affichage de la liste des catégories -----
    return Column(
      children: widget.categories
          .map((categorie) => _buildCategorieItem(theme, categorie))
          .toList(),
    );
  } // Widget helper pour les états vides pour éviter la répétition
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
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          .withLightness(
          (HSLColor
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
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Colors.grey[850], // Couleur de fond pour la catégorie
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
                      // currencyFormatter.format(categorie.disponibleTotal), // Utilisez ceci si vous avez intl
                      '${categorie.disponibleTotal.toStringAsFixed(2)} \$',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: couleurBarreEtTexteDisponible,
                          fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      estDeplie
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: Colors.white70,
                    ),
                  ],
                ),
                if (categorie.info.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categorie.info,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
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
            // Couleur de fond pour les enveloppes dépliées
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
    double progression = 0;
    if (enveloppe.montantAlloue > 0) {
      progression = (enveloppe.depense / enveloppe.montantAlloue);
    }
    progression = progression.clamp(0.0, 1.0);

    Color couleurDeBaseEnveloppe = enveloppe.couleur ??
        HSLColor.fromColor(couleurCategorieParente)
            .withLightness(
            (HSLColor
                .fromColor(couleurCategorieParente)
                .lightness * 0.8)
                .clamp(0.0, 1.0))
            .toColor();
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
          HSLColor.fromColor(couleurDeBaseEnveloppe)
              .withLightness(
              (HSLColor
                  .fromColor(couleurDeBaseEnveloppe)
                  .lightness * 0.9)
                  .clamp(0.0, 1.0))
              .toColor();
    }

    return Material( // Permet d'avoir un effet InkWell sur une couleur de fond personnalisée
      color: Colors.transparent, // Le Container parent gère la couleur de fond
      child: InkWell(
        onTap: () {
          print('Enveloppe ${enveloppe
              .nom} cliquée (depuis BudgetCategoriesList)');
          // TODO: Gérer la navigation/action, potentiellement via un callback
          // Exemple: widget.onEnveloppeTap?.call(enveloppe);
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
                            .withAlpha(200) // Un peu transparent pour l'icône
                            .toColor(),
                        size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      enveloppe.nom,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    // currencyFormatter.format(enveloppe.disponible), // Utilisez ceci si vous avez intl
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
                  padding:
                  EdgeInsets.only(left: enveloppe.icone != null ? 32 : 0),
                  // Aligne avec le texte si icône
                  child: Text(
                    enveloppe.messageSous!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[400]),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Padding(
                padding:
                EdgeInsets.only(left: enveloppe.icone != null ? 32 : 0),
                // Aligne avec le texte si icône
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