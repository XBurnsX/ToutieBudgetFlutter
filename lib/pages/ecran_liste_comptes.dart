import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ecran_creation_compte.dart.dart';

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
    return Compte(
      id: doc.id,
      nom: data['nom'] ?? 'Nom inconnu',
      type: TypeDeCompte.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == (data['type'] ?? 'compteBancaire'),
        orElse: () => TypeDeCompte.compteBancaire,
      ),
      solde: (data['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      couleurValue: data['couleurValue'] as int? ?? Colors.blue.value,
    );
  }

  void _naviguerVersCreationCompte() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    ).then((resultat) {
      if (resultat == true) {
        print(
            "Retour de la création de compte, mise à jour via StreamBuilder attendue.");
      }
    });
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
          .orderBy('nom')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          print("Erreur Firestore Stream: ${snapshot.error}");
          return Scaffold(body: Center(
              child: Text('Une erreur est survenue: ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final List<Compte> tousLesComptes = snapshot.data?.docs.map(
            _compteFromSnapshot).toList() ?? [];

        return _buildComptesUI(context, theme, tousLesComptes);
      },
    );
  }

  Widget _buildComptesUI(BuildContext context, ThemeData theme,
      List<Compte> tousLesComptes) {
    List<Compte> getComptesCourants() =>
        tousLesComptes
            .where((c) => c.type == TypeDeCompte.compteBancaire)
            .toList();
    List<Compte> getComptesDettes() =>
        tousLesComptes.where((c) =>
    c.type == TypeDeCompte.dette || c.type == TypeDeCompte.credit).toList();
    List<Compte> getComptesInvestissements() =>
        tousLesComptes
            .where((c) => c.type == TypeDeCompte.investissement)
            .toList();
    double getSoldeTotal(List<Compte> comptes) =>
        comptes.fold(0.0, (sum, item) => sum + item.solde);

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
                  Text(
                    'Comptes',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: theme.colorScheme.primary, size: 28.0),
                    tooltip: 'Ajouter un compte',
                    onPressed: _naviguerVersCreationCompte,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15.0),
            Expanded(
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // ! padding entre Compte / Transaction
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface, // Couleur de fond du bouton, peut être theme.cardColor ou autre
                        foregroundColor: theme.colorScheme.onSurface, // Couleur du texte et de l'icône
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0), // Padding interne du bouton
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2.0,
                        // minimumSize: const Size(double.infinity, 50), // LIGNE MODIFIÉE/SUPPRIMÉE
                      ),
                      onPressed: () {
                        print("Bouton Toutes les transactions cliqué");
                        // TODO: Naviguer vers l'écran de toutes les transactions
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Important pour que le Row ne s'étende pas inutilement
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ceci aura moins d'effet si le Row est min
                        children: <Widget>[
                          Text(
                            'Toutes les transactions',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8), // Petit espace entre texte et icône
                          Icon(
                            Icons.chevron_right,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0), // ! Padding entre Toute les transaction et les comptes
                  _buildSectionDivider(context),
                  _buildSectionComptes(
                    context,
                    theme,
                    titreSection: 'Argent Comptant',
                    comptes: comptesCourants,
                    soldeTotal: soldeTotalComptesCourants,
                    couleurSoldePositif: Colors.greenAccent[400],
                    couleurSoldeNegatif: Colors.redAccent,
                    messageSiVide: 'Aucun compte de ce type.',
                    onCompteTap: (compte) {
                      print('Compte ${compte.nom} cliqué (ID: ${compte.id})');
                    },
                  ),
                  const SizedBox(height: 10.0), // ! Padding entre Argent Comptant / Divider
                  _buildSectionDivider(context),
                  const SizedBox(height: 10.0), // ! Padding entre Divider et les dettes
                  _buildSectionComptes(
                    context,
                    theme,
                    titreSection: 'Dettes',
                    comptes: comptesDettes,
                    soldeTotal: soldeTotalDettes,
                    couleurSoldePositif: Colors.orangeAccent,
                    couleurSoldeZero: theme.colorScheme.onSurface,
                    couleurSoldeNegatif: Colors.orangeAccent,
                    messageSiVide: 'Aucune dette ou crédit enregistré.',
                    onCompteTap: (compte) {
                      print('Compte ${compte.type
                          .toString()
                          .split('.')
                          .last} ${compte.nom} cliqué (ID: ${compte.id})');
                    },
                    typeDeComptesAfficherNomType: true,
                  ),
                  const SizedBox(height: 10.0), // ! Padding entre Argent Dettes / Divider
                  _buildSectionDivider(context),
                  const SizedBox(height: 10.0), // ! Padding entre Divider et les investissement
                  _buildSectionComptes(
                    context,
                    theme,
                    titreSection: 'Investissements',
                    comptes: comptesInvestissements,
                    soldeTotal: soldeTotalInvestissements,
                    couleurSoldePositif: Colors.greenAccent[400],
                    couleurSoldeNegatif: Colors.redAccent,
                    messageSiVide: 'Aucun investissement enregistré.',
                    onCompteTap: (compte) {
                      print('Compte d\'investissement ${compte
                          .nom} cliqué (ID: ${compte.id})');
                    },
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    const double verticalPaddingValue = 8.0;
    return Column(
      children: [
        const SizedBox(height: verticalPaddingValue),
        Divider(
          color: Theme
              .of(context)
              .dividerColor
              .withOpacity(0.5),
          thickness: 2,
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
        Color? couleurSoldePositif,
        Color? couleurSoldeNegatif,
        Color? couleurSoldeZero,
        required String messageSiVide,
        required Function(Compte) onCompteTap,
        bool typeDeComptesAfficherNomType = false,
      }) {
    Color couleurSoldeAffiche;
    if (soldeTotal == 0) {
      couleurSoldeAffiche = couleurSoldeZero ?? theme.colorScheme.onSurface;
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
            padding: const EdgeInsets.only(
                left: 0.0, right: 0.0, top: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titreSection, style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
                Text(
                  '${soldeTotal.toStringAsFixed(2)} \$',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: couleurSoldeAffiche),
                ),
              ],
            ),
          ),
          if (comptes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text(messageSiVide,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey))),
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
                  titreAAfficher = "${compte.type
                      .toString()
                      .split('.')
                      .last
                      .capitalize()} - ${compte.nom}";
                }

                Color couleurSoldeCompte;
                if (compte.solde == 0 && (compte.type == TypeDeCompte.dette ||
                    compte.type == TypeDeCompte.credit)) {
                  couleurSoldeCompte = theme.colorScheme.onSurface;
                } else if (compte.type == TypeDeCompte.dette ||
                    compte.type == TypeDeCompte.credit) {
                  couleurSoldeCompte = Colors.orangeAccent;
                } else if (compte.solde >= 0) {
                  couleurSoldeCompte = theme.colorScheme.onSurface;
                } else {
                  couleurSoldeCompte = Colors.redAccent;
                }

                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: compte.couleur,
                      child: Text(compte.nom.isNotEmpty
                          ? compte.nom[0].toUpperCase()
                          : '?', style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                        titreAAfficher, style: theme.textTheme.titleMedium),
                    trailing: Text(
                      '${compte.solde.toStringAsFixed(2)} \$',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: couleurSoldeCompte,
                          fontWeight: FontWeight.w500),
                    ),
                    onTap: () => onCompteTap(compte),
                  ),
                );
              },
            ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}