// lib/pages/ecran_liste_comptes.dart
import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart'; // Assurez-vous que ce chemin est correct
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pour le formatage
import 'ecran_creation_compte.dart';
// Import de l'écran de création de compte (si vous l'utilisez)
// import 'ecran_creation_compte.dart'; // Ajustez le chemin si nécessaire

class EcranListeComptes extends StatefulWidget {
  const EcranListeComptes({super.key});

  @override
  State<EcranListeComptes> createState() => _EcranListeComptesState();
}

class _EcranListeComptesState extends State<EcranListeComptes> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté au démarrage
      // Peut-être naviguer vers un écran de connexion.
      // Pour l'instant, on laisse le build gérer l'affichage d'un message.
      debugPrint(
          "EcranListeComptes: Aucun utilisateur connecté à l'initialisation.");
    }
  }

  // La méthode _compteFromSnapshot a été SUPPRIMÉE d'ici.
  // Nous utilisons Compte.fromSnapshot directement depuis le modèle.

  void _naviguerVersCreationCompte() {
    // Assurez-vous que EcranCreationCompte est correctement défini et importé
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    ).then((resultat) {
      // Le `StreamBuilder` devrait se mettre à jour automatiquement si Firestore est modifié
      // par EcranCreationCompte.
      // Vous pouvez afficher un message si EcranCreationCompte retourne une valeur spécifique.
      if (resultat == true && mounted) { // Vérifiez que le widget est toujours monté
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar() // Enlève les snackbars précédents pour éviter l'empilement
          ..showSnackBar(const SnackBar(
            content: Text("Nouveau compte ajouté avec succès !"),
            backgroundColor: Colors.green,
          ));
      }
      debugPrint("Retour de EcranCreationCompte avec résultat : $resultat");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mes Comptes")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 50, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "Veuillez vous connecter pour voir vos comptes.",
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                // Optionnellement, un bouton pour se connecter/s'inscrire
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<
        Map<String, dynamic>>>( // Type explicite pour QuerySnapshot
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('comptes')
          .orderBy('nom')
          .snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          debugPrint("ERREUR Firestore Stream dans EcranListeComptes: ${snapshot
              .error}");
          debugPrintStack(stackTrace: snapshot.stackTrace);
          return Scaffold(
            appBar: AppBar(title: const Text("Mes Comptes")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erreur de chargement des comptes.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold( // Fournit une structure pendant le chargement
            appBar: AppBar(title: const Text("Mes Comptes")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Afficher l'UI principale mais avec un état vide pour les comptes
          return _buildComptesUI(context, theme, []);
        }

        final List<Compte> tousLesComptes = snapshot.data!.docs.map((doc) {
          try {
            // Utilisation de la méthode statique centralisée du modèle Compte
            return Compte.fromSnapshot(doc);
          } catch (e, stacktrace) {
            debugPrint(
                "ERREUR MAPPING Compte dans EcranListeComptes pour doc ${doc
                    .id}: $e");
            debugPrintStack(stackTrace: stacktrace);
            // Vous pourriez vouloir un Compte "invalide" ou le filtrer.
            // Retourner null et filtrer est une option.
            return null;
          }
        })
            .whereType<Compte>()
            .toList(); // Filtre les nulls si fromSnapshot échoue et retourne null

        return _buildComptesUI(context, theme, tousLesComptes);
      },
    );
  }

  Widget _buildComptesUI(BuildContext context, ThemeData theme,
      List<Compte> tousLesComptes) {
    // Calcul des soldes et filtrage des comptes
    List<Compte> getComptesParTypes(List<TypeDeCompte> types) =>
        tousLesComptes.where((c) => types.contains(c.type)).toList();

    double getSoldeTotal(List<Compte> comptes) =>
        comptes.fold(0.0, (sum, item) => sum + item.soldeActuel);

    final comptesCourantsEtEspeces = getComptesParTypes(
        [TypeDeCompte.compteBancaire, TypeDeCompte.especes]);
    final soldeTotalCourantsEtEspeces = getSoldeTotal(comptesCourantsEtEspeces);

    final comptesDettesEtCredits = getComptesParTypes(
        [TypeDeCompte.dette, TypeDeCompte.credit]);
    final soldeTotalDettesEtCredits = getSoldeTotal(comptesDettesEtCredits);

    final comptesInvestissements = getComptesParTypes(
        [TypeDeCompte.investissement]);
    final soldeTotalInvestissements = getSoldeTotal(comptesInvestissements);

    final comptesAutres = getComptesParTypes([TypeDeCompte.autre]);
    final soldeTotalAutres = getSoldeTotal(comptesAutres);


    return Scaffold(
      // AppBar est maintenant géré par le StreamBuilder pour les états d'erreur/chargement
      // Si vous voulez un AppBar constant, déplacez-le hors du StreamBuilder
      // et mettez le StreamBuilder dans le `body` du Scaffold.
      // Pour cet exemple, je le laisse implicite que l'UI de la liste a son propre AppBar.
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 16.0, left: 16.0, right: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Mes Comptes',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: theme.colorScheme.primary, size: 30.0),
                    tooltip: 'Ajouter un compte',
                    onPressed: _naviguerVersCreationCompte,
                  ),
                ],
              ),
            ),
            // Si vous avez un bouton "Toutes les transactions"
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  // Ou une autre couleur de votre thème
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  elevation: 1.0,
                ),
                onPressed: () {
                  debugPrint("Bouton Toutes les transactions cliqué");
                  // TODO: Naviguer vers l'écran de toutes les transactions
                },
                icon: const Icon(Icons.list_alt_outlined),
                label: Text('Toutes les transactions',
                    style: theme.textTheme.titleMedium),
              ),
            ),
            Expanded(
              child: tousLesComptes.isEmpty
                  ? _buildEmptyStateComptes(theme)
                  : ListView(
                padding: const EdgeInsets.only(top: 8.0),
                children: <Widget>[
                  if (comptesCourantsEtEspeces.isNotEmpty ||
                      true) // Toujours afficher la section
                    _buildSectionComptes(
                      context, theme,
                      titreSection: 'Argent et Courant',
                      comptes: comptesCourantsEtEspeces,
                      soldeTotal: soldeTotalCourantsEtEspeces,
                      messageSiVide: 'Aucun compte courant ou d\'espèces.',
                      onCompteTap: (compte) => _onCompteTap(compte, context),
                    ),

                  if (comptesDettesEtCredits.isNotEmpty || true)
                    _buildSectionComptes(
                      context, theme,
                      titreSection: 'Dettes et Crédits',
                      comptes: comptesDettesEtCredits,
                      soldeTotal: soldeTotalDettesEtCredits,
                      couleurSoldeNegatif: Colors.orangeAccent,
                      messageSiVide: 'Aucune dette ou carte de crédit.',
                      onCompteTap: (compte) => _onCompteTap(compte, context),
                      typeDeComptesAfficherNomType: true,
                    ),

                  if (comptesInvestissements.isNotEmpty || true)
                    _buildSectionComptes(
                      context, theme,
                      titreSection: 'Investissements',
                      comptes: comptesInvestissements,
                      soldeTotal: soldeTotalInvestissements,
                      couleurSoldePositif: Colors.purpleAccent[100],
                      messageSiVide: 'Aucun investissement.',
                      onCompteTap: (compte) => _onCompteTap(compte, context),
                    ),

                  if (comptesAutres
                      .isNotEmpty) // N'afficher "Autres" que s'il y en a
                    _buildSectionComptes(
                      context, theme,
                      titreSection: 'Autres Comptes',
                      comptes: comptesAutres,
                      soldeTotal: soldeTotalAutres,
                      messageSiVide: 'Aucun autre type de compte.',
                      onCompteTap: (compte) => _onCompteTap(compte, context),
                      typeDeComptesAfficherNomType: true,
                    ),

                  const SizedBox(height: 70.0),
                  // Espace pour le FAB si présent dans un parent
                ],
              ),
            ),
          ],
        ),
      ),
      // Le FAB a été retiré, car le bouton "Ajouter" est maintenant dans l'AppBar-like Row.
      // Si vous voulez un FAB flottant, vous pouvez le remettre ici.
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _naviguerVersCreationCompte,
      //   label: const Text('Nouveau Compte'),
      //   icon: const Icon(Icons.add),
      // ),
    );
  }

  Widget _buildEmptyStateComptes(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.account_balance_wallet_outlined, size: 70,
                color: Colors.grey[500]),
            const SizedBox(height: 20),
            Text(
              'Aucun compte pour le moment',
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Appuyez sur le bouton "+" en haut pour ajouter votre premier compte.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un compte'),
              onPressed: _naviguerVersCreationCompte,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCompteTap(Compte compte, BuildContext context) {
    debugPrint(
        'Compte cliqué: ${compte.nom} (ID: ${compte.id}), Couleur: ${compte
            .couleur}');
    // TODO: Naviguer vers l'écran de détails du compte si nécessaire
    // Navigator.push(context, MaterialPageRoute(builder: (context) => EcranDetailsCompte(compte: compte)));
  }

  Widget _buildSectionDivider(BuildContext context) {
    // Non utilisé actuellement mais gardé si besoin
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        color: Theme
            .of(context)
            .dividerColor
            .withOpacity(0.5),
        thickness: 1,
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
    );
  }

  Widget _buildSectionComptes(BuildContext context, ThemeData theme, {
    required String titreSection,
    required List<Compte> comptes,
    required double soldeTotal,
    Color? couleurSoldePositif,
    Color? couleurSoldeNegatif,
    Color? couleurSoldeZero,
    required String messageSiVide,
    required Function(Compte) onCompteTap,
    bool typeDeComptesAfficherNomType = false,
  }) {
    final currencyFormat = NumberFormat.currency(
        locale: 'fr_CA', symbol: '\$', decimalDigits: 2);

    Color couleurSoldeAffiche;
    if (soldeTotal == 0) {
      couleurSoldeAffiche = couleurSoldeZero ??
          theme.textTheme.bodyMedium!.color!.withOpacity(0.8);
    } else if (soldeTotal > 0) {
      couleurSoldeAffiche = couleurSoldePositif ?? Colors.green.shade600;
    } else {
      couleurSoldeAffiche = couleurSoldeNegatif ?? Colors.red.shade600;
    }

    // Si la section est vide et que nous avons un message pour cela, on l'affiche.
    // Ajout d'une condition pour ne pas afficher la section du tout si elle est vide ET que ce n'est pas la section "Argent et Courant" ou "Dettes et Crédits"
    // (pour ces dernières, on veut potentiellement afficher le titre même si vide)
    bool estSectionPrincipaleVide = titreSection == 'Argent et Courant' ||
        titreSection == 'Dettes et Crédits';
    if (comptes.isEmpty && !estSectionPrincipaleVide) {
      return const SizedBox
          .shrink(); // Ne rien afficher si la section optionnelle est vide
    }


    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titreSection, style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600)),
              Text(
                currencyFormat.format(
                    titreSection.contains('Dettes') && soldeTotal != 0
                        ? soldeTotal.abs()
                        : soldeTotal),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: couleurSoldeAffiche),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          if (comptes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: Center(
                  child: Text(messageSiVide,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600]))
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comptes.length,
              itemBuilder: (context, index) {
                final compte = comptes[index];
                String titreAAfficher = compte.nom;
                if (typeDeComptesAfficherNomType) {
                  titreAAfficher = "${compte.nom} (${compte.typeDisplayName})";
                }

                // Log pour vérifier la couleur de chaque compte dans la liste
                debugPrint("LISTE_COMPTES - Affichage Compte: ${compte
                    .nom}, Couleur lue pour CircleAvatar: ${compte.couleur}");

                Color couleurSoldeCompteIndividuel;
                if (compte.type == TypeDeCompte.dette ||
                    compte.type == TypeDeCompte.credit) {
                  couleurSoldeCompteIndividuel = compte.soldeActuel == 0
                      ? (couleurSoldeZero ??
                      theme.textTheme.bodyMedium!.color!.withOpacity(0.8))
                      : (compte.soldeActuel > 0 ? (couleurSoldeNegatif ??
                      Colors.orange.shade700) : (couleurSoldePositif ??
                      Colors.green.shade600));
                } else {
                  couleurSoldeCompteIndividuel = compte.soldeActuel == 0
                      ? (couleurSoldeZero ??
                      theme.textTheme.bodyMedium!.color!.withOpacity(0.8))
                      : compte.soldeActuel > 0
                      ? (couleurSoldePositif ?? Colors.green.shade600)
                      : (couleurSoldeNegatif ?? Colors.red.shade600);
                }

                return Card(
                  elevation: 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    leading: CircleAvatar(
                        backgroundColor: compte.couleur.withOpacity(0.2),
                        // Couleur du compte avec opacité
                        child: CircleAvatar( // Cercle intérieur pour couleur pleine
                          backgroundColor: compte.couleur,
                          radius: 16, // Légèrement plus petit
                          child: Text(
                            compte.nom.isNotEmpty
                                ? compte.nom[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: compte.couleur.computeLuminance() > 0.5
                                    ? Colors.black87
                                    : Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                    ),
                    title: Text(titreAAfficher,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500)),
                    subtitle: typeDeComptesAfficherNomType ? null : Text(
                        compte.typeDisplayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600])),
                    trailing: Text(
                      currencyFormat.format(compte.type == TypeDeCompte.dette &&
                          compte.soldeActuel != 0
                          ? compte.soldeActuel.abs()
                          : compte.soldeActuel),
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: couleurSoldeCompteIndividuel,
                          fontWeight: FontWeight.w500),
                    ),
                    onTap: () => onCompteTap(compte),
                  ),
                );
              },
            ),
          const Divider(height: 24, thickness: 0, color: Colors.transparent),
          // Espaceur de section
        ],
      ),
    );
  }
}