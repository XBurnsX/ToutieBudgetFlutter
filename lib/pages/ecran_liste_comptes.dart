import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart'; // Assurez-vous que ce chemin est correct et que compte_model.dart est celui que vous avez partagé
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Supposons que EcranCreationCompte est défini ailleurs et importé correctement
// import 'ecran_creation_compte.dart'; // Décommentez et ajustez le chemin si nécessaire

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
  }

  Compte _compteFromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    // 1. Gestion de la Couleur
    Color couleurCompte = Colors
        .blue; // Couleur par défaut si rien n'est trouvé ou erreur
    if (data['couleurHex'] is String) {
      String couleurHex = data['couleurHex'] as String;
      if (couleurHex.startsWith('#') &&
          (couleurHex.length == 7 || couleurHex.length == 9)) {
        try {
          String hexValue = couleurHex.substring(1);
          if (hexValue.length == 6) { // Format RRGGBB
            hexValue = 'FF$hexValue'; // Ajoute un canal alpha opaque par défaut
          }
          couleurCompte = Color(int.parse(hexValue, radix: 16));
        } catch (e) {
          debugPrint(
              "Erreur de parsing pour couleurHex ('$couleurHex') pour le compte ${doc
                  .id}: $e. Utilisation de la couleur par défaut.");
        }
      } else {
        debugPrint(
            "Format de couleurHex ('$couleurHex') inattendu pour le compte ${doc
                .id}. Utilisation de la couleur par défaut.");
      }
    } else if (data.containsKey('couleurValue') &&
        data['couleurValue'] is int) { // Ancien format potentiel pour rétrocompatibilité
      try {
        couleurCompte = Color(data['couleurValue'] as int);
      } catch (e) {
        debugPrint(
            "Erreur de parsing pour couleurValue ('${data['couleurValue']}') pour le compte ${doc
                .id}: $e. Utilisation de la couleur par défaut.");
      }
    } else {
      debugPrint(
          "Aucun champ de couleur valide ('couleurHex' ou 'couleurValue') trouvé pour le compte ${doc
              .id}. Utilisation de la couleur par défaut.");
    }

    // 2. Gestion de la Date de Création (doit être Timestamp pour correspondre au modèle Compte)
    Timestamp dateCreationPourConstructeur;
    if (data['dateCreation'] is Timestamp) {
      dateCreationPourConstructeur = data['dateCreation'] as Timestamp;
    } else if (data['dateCreation'] is String) {
      try {
        DateTime dt = DateTime.parse(data['dateCreation'] as String);
        dateCreationPourConstructeur = Timestamp.fromDate(dt);
      } catch (e) {
        debugPrint(
            "Erreur de parsing pour dateCreation String ('${data['dateCreation']}') pour le compte ${doc
                .id}: $e. Utilisation du timestamp actuel.");
        dateCreationPourConstructeur = Timestamp.now();
      }
    } else {
      debugPrint(
          "Champ dateCreation manquant ou de type inattendu pour le compte ${doc
              .id}. Utilisation du timestamp actuel.");
      dateCreationPourConstructeur = Timestamp.now();
    }

    // 3. Gestion des Soldes
    double soldeInitialLu = (data['soldeInitial'] as num?)?.toDouble() ?? 0.0;
    double soldeActuelLu = (data['soldeActuel'] as num?)?.toDouble() ??
        soldeInitialLu;

    // 4. Gestion de la Devise
    String deviseLue = data['devise'] as String? ??
        'CAD'; // Valeur par défaut 'CAD'

    return Compte(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom inconnu',
      type: TypeDeCompte.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == (data['type'] as String? ?? 'autre'),
        // Défaut à 'autre' si type est null/inconnu
        orElse: () {
          debugPrint(
              "Type de compte ('${data['type']}') inconnu ou manquant pour ${doc
                  .id}. Utilisation de 'autre' par défaut.");
          return TypeDeCompte.autre;
        },
      ),
      soldeInitial: soldeInitialLu,
      soldeActuel: soldeActuelLu,
      couleur: couleurCompte,
      dateCreation: dateCreationPourConstructeur,
      // Passe le Timestamp
      devise: deviseLue, // Passe la devise lue
    );
  }

  void _naviguerVersCreationCompte() {
    // Assurez-vous que EcranCreationCompte est importé et existe
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    // ).then((resultat) {
    //   if (resultat == true) { // ou une autre condition selon ce que retourne l'écran de création
    //     // Le StreamBuilder devrait se mettre à jour automatiquement si Firestore est modifié.
    //     debugPrint("Retour de la création de compte, mise à jour via StreamBuilder attendue.");
    //   }
    // });
    debugPrint(
        "_naviguerVersCreationCompte appelé. Implémentez la navigation si EcranCreationCompte est prêt.");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text("Chargement de l'utilisateur...",
                  style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('comptes')
          .orderBy(
          'nom') // Ou 'dateCreation' ou un autre champ pertinent pour le tri
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          debugPrint("Erreur Firestore Stream dans EcranListeComptes: ${snapshot
              .error}");
          debugPrintStack(stackTrace: snapshot.stackTrace);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    'Une erreur est survenue lors du chargement des comptes.\n${snapshot
                        .error}', textAlign: TextAlign.center),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold( // Un Scaffold ici peut être excessif si cet écran est déjà dans un Scaffold parent
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildComptesUI(context, theme,
              []); // Afficher l'UI avec une liste vide mais la structure
        }

        final List<Compte> tousLesComptes = snapshot.data!.docs.map((doc) {
          try {
            return _compteFromSnapshot(doc);
          } catch (e, stacktrace) {
            debugPrint("Erreur fatale lors du mapping du compte ${doc
                .id} dans StreamBuilder: $e");
            debugPrintStack(stackTrace: stacktrace);
            return null; // Retourner null pour filtrer plus tard
          }
        })
            .whereType<Compte>()
            .toList(); // Filtre les nulls si _compteFromSnapshot échoue et retourne null

        return _buildComptesUI(context, theme, tousLesComptes);
      },
    );
  }

  Widget _buildComptesUI(BuildContext context, ThemeData theme,
      List<Compte> tousLesComptes) {
    // Logique pour filtrer les comptes par type (utilisez les types de votre enum TypeDeCompte)
    List<Compte> getComptesCourants() =>
        tousLesComptes
            .where((c) =>
        c.type == TypeDeCompte.compteBancaire || c.type == TypeDeCompte.especes)
            .toList();
    List<Compte> getComptesDettes() =>
        tousLesComptes.where((c) =>
        c.type == TypeDeCompte.dette || c.type == TypeDeCompte.credit).toList();
    List<Compte> getComptesInvestissements() =>
        tousLesComptes
            .where((c) => c.type == TypeDeCompte.investissement)
            .toList();
    // Vous pouvez ajouter une section pour TypeDeCompte.autre si nécessaire

    // Logique pour calculer le solde total pour une liste de comptes
    double getSoldeTotal(List<Compte> comptes) =>
        comptes.fold(0.0, (sum, item) => sum + item.soldeActuel);

    final comptesCourants = getComptesCourants();
    final soldeTotalComptesCourants = getSoldeTotal(comptesCourants);
    final comptesDettes = getComptesDettes();
    final soldeTotalDettes = getSoldeTotal(comptesDettes);
    final comptesInvestissements = getComptesInvestissements();
    final soldeTotalInvestissements = getSoldeTotal(comptesInvestissements);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: 16.0, right: 8.0, bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Comptes',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: theme.colorScheme.primary, size: 28.0),
                    tooltip: 'Ajouter un compte',
                    onPressed: _naviguerVersCreationCompte,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 15.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        elevation: 2.0,
                      ),
                      onPressed: () {
                        debugPrint("Bouton Toutes les transactions cliqué");
                        // TODO: Naviguer vers l'écran de toutes les transactions
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Toutes les transactions', style: theme.textTheme
                              .titleMedium),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  _buildSectionDivider(context),
                  _buildSectionComptes(
                    context,
                    theme,
                    titreSection: 'Argent et Courant',
                    // Ajusté pour inclure espèces
                    comptes: comptesCourants,
                    soldeTotal: soldeTotalComptesCourants,
                    messageSiVide: 'Aucun compte courant ou d\'espèces.',
                    onCompteTap: (compte) {
                      debugPrint('Compte ${compte.nom} (type: ${compte
                          .typeDisplayName}) cliqué (ID: ${compte.id})');
                      // TODO: Naviguer vers les détails du compte
                    },
                  ),
                  _buildSectionDivider(context),
                  _buildSectionComptes(
                    context,
                    theme,
                    titreSection: 'Dettes et Crédits',
                    comptes: comptesDettes,
                    soldeTotal: soldeTotalDettes,
                    couleurSoldeNegatif: Colors.orangeAccent,
                    // Les dettes sont souvent "négatives"
                    messageSiVide: 'Aucune dette ou crédit enregistré.',
                    onCompteTap: (compte) {
                      debugPrint('Compte ${compte.nom} (type: ${compte
                          .typeDisplayName}) cliqué (ID: ${compte.id})');
                      // TODO: Naviguer vers les détails du compte
                    },
                    typeDeComptesAfficherNomType: true,
                  ),
                  _buildSectionDivider(context),
                  _buildSectionComptes(
                    context,
                    theme,
                    titreSection: 'Investissements',
                    comptes: comptesInvestissements,
                    soldeTotal: soldeTotalInvestissements,
                    couleurSoldePositif: Colors.purpleAccent[100],
                    messageSiVide: 'Aucun investissement enregistré.',
                    onCompteTap: (compte) {
                      debugPrint('Compte ${compte.nom} (type: ${compte
                          .typeDisplayName}) cliqué (ID: ${compte.id})');
                      // TODO: Naviguer vers les détails du compte
                    },
                  ),
                  const SizedBox(height: 24.0), // Espace en fin de liste
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    const double verticalPaddingValue = 12.0;
    return Column(
      children: [
        const SizedBox(height: verticalPaddingValue),
        Divider(
          color: Theme
              .of(context)
              .dividerColor
              .withOpacity(0.3),
          thickness: 1,
          height: 0,
          indent: 16,
          endIndent: 16,
        ),
        const SizedBox(height: verticalPaddingValue),
      ],
    );
  }

  Widget _buildSectionComptes(BuildContext context,
      ThemeData theme, {
        required String titreSection,
        required List<Compte> comptes,
        required double soldeTotal,
        Color? couleurSoldePositif, // Couleur si solde > 0
        Color? couleurSoldeNegatif, // Couleur si solde < 0
        Color? couleurSoldeZero, // Couleur si solde == 0
        required String messageSiVide,
        required Function(Compte) onCompteTap,
        bool typeDeComptesAfficherNomType = false,
      }) {
    Color couleurSoldeAffiche;
    if (soldeTotal == 0) {
      couleurSoldeAffiche =
          couleurSoldeZero ?? theme.colorScheme.onSurface.withOpacity(0.7);
    } else if (soldeTotal > 0) {
      couleurSoldeAffiche = couleurSoldePositif ?? Colors.greenAccent[400]!;
    } else {
      couleurSoldeAffiche = couleurSoldeNegatif ?? Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titreSection, style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
                Text(
                  '${(titreSection.contains('Dettes') && soldeTotal != 0
                      ? soldeTotal.abs()
                      : soldeTotal).toStringAsFixed(2)} \$',
                  // Affiche la devise du premier compte ou CAD par défaut
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: couleurSoldeAffiche),
                ),
              ],
            ),
          ),
          if (comptes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                String titreAAfficher = typeDeComptesAfficherNomType ? compte
                    .typeDisplayName : compte.nom;
                if (typeDeComptesAfficherNomType && compte.typeDisplayName !=
                    compte
                        .nom) { // Pour éviter "Dette - Ma Dette" -> "Ma Dette (Dette)"
                  titreAAfficher = "${compte.nom} (${compte.typeDisplayName})";
                }


                Color couleurSoldeCompteIndividuel;
                if (compte.type == TypeDeCompte.dette ||
                    compte.type == TypeDeCompte.credit) {
                  // Pour dettes/crédits, un solde de 0 est neutre. >0 signifie qu'on doit de l'argent (négatif pour nous).
                  // La couleur dépend si on veut montrer le montant dû (orange) ou le crédit (vert).
                  // Ici, on considère que si soldeActuel > 0 pour une dette, c'est "mauvais".
                  couleurSoldeCompteIndividuel = compte.soldeActuel == 0
                      ? (couleurSoldeZero ??
                      theme.colorScheme.onSurface.withOpacity(0.7))
                      : (compte.soldeActuel > 0 ? (couleurSoldeNegatif ??
                      Colors.orangeAccent) : (couleurSoldePositif ?? Colors
                      .greenAccent[400]!)); // Si solde < 0 (crédit en notre faveur)
                } else {
                  couleurSoldeCompteIndividuel = compte.soldeActuel == 0
                      ? (couleurSoldeZero ??
                      theme.colorScheme.onSurface.withOpacity(0.7))
                      : compte.soldeActuel > 0
                      ? (couleurSoldePositif ?? Colors.greenAccent[400]!)
                      : (couleurSoldeNegatif ?? Colors.redAccent);
                }

                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: compte.couleur,
                      child: Text(
                        compte.nom.isNotEmpty
                            ? compte.nom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                        titreAAfficher, style: theme.textTheme.titleMedium),
                    trailing: Text(
                      '${(compte.type == TypeDeCompte.dette &&
                          compte.soldeActuel != 0
                          ? compte.soldeActuel.abs()
                          : compte.soldeActuel).toStringAsFixed(2)} ${compte
                          .devise}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: couleurSoldeCompteIndividuel,
                          fontWeight: FontWeight.w500),
                    ),
                    onTap: () => onCompteTap(compte),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}