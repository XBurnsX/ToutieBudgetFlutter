import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toutie_budget/models/categorie_budget_model.dart';
import 'package:toutie_budget/models/compte_model.dart';

// Assurez-vous que EnveloppePourAffichageBudget est importé (s'il vient d'un fichier séparé)
// et qu'il N'A PLUS messageSous
// import 'package:toutie_budget/pages/ecran_budget.dart' show EnveloppePourAffichageBudget;
import 'package:toutie_budget/pages/gestion_categories_enveloppes_screen.dart'
    show GestionCategoriesEnveloppesScreen; // Pour la navigation par défaut

// IMPORTS POUR ENVELOPPECARD
import 'package:toutie_budget/widgets/EnveloppeCard.dart'; // Ajustez le chemin
// Si TypeObjectif vient d'ailleurs et est nécessaire pour EnveloppeUIData (mais normalement EnveloppeCard gère son import)
// import 'package:toutie_budget/pages/gestion_categories_enveloppes_screen.dart' show TypeObjectif;


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
  final currencyFormatter = NumberFormat.currency(
      locale: 'fr_CA', symbol: '\$');

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

  Widget _buildCategorieItem(ThemeData theme, CategorieBudgetModel categorie) {
    Color couleurTexteDisponible = categorie.disponibleTotal >= 0
        ? (theme.brightness == Brightness.dark
        ? Colors.greenAccent[100]!
        : Colors.green[700]!)
        : (theme.brightness == Brightness.dark
        ? Colors.redAccent[100]!
        : Colors.red[700]!);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: Colors.black, // Couleur d'en-tête de catégorie
          child: Row(
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
            ],
          ),
        ),
        Container(
          color: Colors.grey[900], // Fond pour la section des enveloppes
          child: Column(
            children: categorie.enveloppes
                .asMap()
                .entries
                .map((entry) {
              int idx = entry.key;
              EnveloppePourAffichageBudget enveloppeVM = entry.value;

              // Créer l'objet EnveloppeUIData à partir de EnveloppePourAffichageBudget
              // Assurez-vous que EnveloppePourAffichageBudget a bien typeObjectif, montantCible, dateCible, ordre
              // et N'A PLUS messageSous
              final EnveloppeUIData uiData = EnveloppeUIData(
                id: enveloppeVM.id,
                nom: enveloppeVM.nom,
                iconeCodePoint: enveloppeVM.icone?.codePoint,
                soldeActuel: enveloppeVM.disponible,
                montantAlloue: enveloppeVM.montantAlloue,
                typeObjectif: enveloppeVM.typeObjectif,
                // CHAMP IMPORTANT
                montantCible: enveloppeVM.montantCible,
                // CHAMP IMPORTANT
                dateCible: enveloppeVM.dateCible,
                // CHAMP IMPORTANT
                couleurThemeValue: enveloppeVM.couleur.value,
                // Si vous avez un champ distinct pour couleurSoldeCompte dans EnveloppePourAffichageBudget, utilisez-le
                // sinon, décidez d'une valeur par défaut ou utilisez la même que couleurThemeValue
                couleurSoldeCompteValue: enveloppeVM.couleur.value,
                // Exemple: utiliser la même
                ordre: enveloppeVM.ordre ?? idx,
                // 'depense' n'est pas directement passé à EnveloppeUIData.
                // EnveloppeCard calcule ce dont il a besoin (comme le progrès)
                // à partir de soldeActuel et montantAlloue, ou vous pourriez ajouter
                // un champ 'depense' à EnveloppeUIData si EnveloppeCard en a besoin explicitement.
              );

              return EnveloppeCard(
                enveloppe: uiData,
                onTap: () {
                  print('Enveloppe ${uiData.nom} (ID: ${uiData
                      .id}) cliquée (via EnveloppeCard)');
                  // TODO: Implémenter la navigation ou l'action au clic sur l'enveloppe
                },
                // Si vous voulez un Divider entre chaque carte, vous pouvez l'ajouter ici
                // ou gérer le padding/margin dans EnveloppeCard lui-même.
                // Exemple :
                // child: Column(children: [ EnveloppeCard(...), if (idx < categorie.enveloppes.length -1) Divider() ])
              );
            }).toList(),
          ),
        ),
        Divider(height: 1, color: Colors.grey[700]),
        // Séparateur entre les catégories
      ],
    );
  }

// CETTE MÉTHODE EST MAINTENANT OBSOLÈTE ET DEVRAIT ÊTRE SUPPRIMÉE OU COMPLÈTEMENT COMMENTÉE
/*
  Widget _buildEnveloppeItem(ThemeData theme,
      EnveloppePourAffichageBudget enveloppe, // <<--- 'enveloppe' ici est le type qui n'a plus 'messageSous'
      Color couleurDeBasePourEnveloppe) {
    // ... (ancienne logique de calcul de progression etc.)

    // L'ERREUR VIENT DE LA LIGNE SUIVANTE DANS VOTRE CODE PARTAGÉ:
    // if (enveloppe.messageSous != null &&
    // enveloppe.messageSous!.isNotEmpty) ...[

    // TOUT LE CONTENU DE CETTE MÉTHODE DEVRAIT ÊTRE SUPPRIMÉ
    // PUISQUE EnveloppeCard FAIT LE TRAVAIL

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('Enveloppe ${enveloppe
              .nom} cliquée (depuis BudgetCategoriesList - ANCIENNE METHODE)');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // ... ancienne Row ...
              ),
              // LE BLOC QUI CAUSE L'ERREUR :
              // if (enveloppe.messageSous != null &&
              //     enveloppe.messageSous!.isNotEmpty) ...[
              //   const SizedBox(height: 5),
              //   Padding(
              //     padding: EdgeInsets.only(
              //         left: enveloppe.icone != null ? 32 : 0),
              //     child: Text(
              //       enveloppe.messageSous!, // <--- ICI EST L'ACCÈS AU CHAMP INEXISTANT
              //       style: theme.textTheme.bodySmall
              //           ?.copyWith(color: Colors.grey[400], fontSize: 11.5),
              //     ),
              //   ),
              // ],
              const SizedBox(height: 7),
              Padding(
                // ... ancien LinearProgressIndicator ...
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
}