import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart'; // Assurez-vous que ce chemin est correct
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ecran_creation_compte.dart.dart';

// --- IMPORT DE VOTRE PAGE DE CRÉATION DE COMPTE ---
// Assurez-vous que ce chemin est correct et que le fichier existe
// Par exemple:
// import 'package:toutie_budget/pages/creation_compte/ecran_creation_compte.dart';
// Ou si dans le même dossier (moins probable pour une structure de projet propre):


// --- L'ÉCRAN LUI-MÊME ---
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

  // Helper pour construire un Compte depuis un DocumentSnapshot
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
      couleurValue: data['couleurValue'] as int? ??
          Colors.blue.value, // Utilisation de couleurValue
      // dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
    );
  }

  // --- MÉTHODE DE NAVIGATION VERS L'ÉCRAN DE CRÉATION ---
  void _naviguerVersCreationCompte() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (
          context) => const EcranCreationCompte()), // Utilise EcranCreationCompte importé
    ).then((resultat) {
      // Le StreamBuilder devrait gérer la mise à jour automatiquement
      // si un compte est ajouté dans Firestore.
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

        // Si l'utilisateur est connecté mais n'a aucun compte,
        // _buildComptesUI sera appelé avec une liste vide et affichera
        // les messages "Aucun compte" dans les sections.
        // Le FAB sera toujours présent pour ajouter le premier compte.
        final List<Compte> tousLesComptes = snapshot.data?.docs.map(
            _compteFromSnapshot).toList() ?? [];

        return _buildComptesUI(context, theme, tousLesComptes);
      },
    );
  }

  // Nouvelle méthode pour construire l'interface utilisateur des comptes
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
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 15.0),
          Material(
            color: theme.cardColor,
            child: InkWell(
              onTap: () {
                print("Bandeau Toutes les transactions cliqué");
                // TODO: Naviguer vers l'écran de toutes les transactions
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Toutes les transactions',
                        style: theme.textTheme.titleMedium),
                    Icon(Icons.chevron_right,
                        color: theme.textTheme.titleMedium?.color),
                  ],
                ),
              ),
            ),
          ),
          _buildSectionDivider(context),

          // SECTION "ARGENT COMPTANT"
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
              // TODO: Naviguer vers les détails/transactions du compte
            },
          ),
          _buildSectionDivider(context),

          // --- SECTION DETTES ---
          _buildSectionComptes(
            context,
            theme,
            titreSection: 'Dettes',
            comptes: comptesDettes,
            soldeTotal: soldeTotalDettes,
            couleurSoldePositif: Colors.orangeAccent,
            // Souvent affiché comme positif (ex: limite de crédit)
            couleurSoldeZero: theme.colorScheme.onSurface,
            couleurSoldeNegatif: Colors.orangeAccent,
            // Ou une autre couleur pour les dettes
            messageSiVide: 'Aucune dette ou crédit enregistré.',
            onCompteTap: (compte) {
              print('Compte ${compte.type
                  .toString()
                  .split('.')
                  .last} ${compte.nom} cliqué (ID: ${compte.id})');
              // TODO: Naviguer vers les détails/transactions du compte de dette/crédit
            },
            typeDeComptesAfficherNomType: true, // Pour afficher "Dette" ou "Crédit" avant le nom
          ),
          _buildSectionDivider(context),

          // --- SECTION INVESTISSEMENTS ---
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
              print('Compte d\'investissement ${compte.nom} cliqué (ID: ${compte
                  .id})');
              // TODO: Naviguer vers les détails/transactions du compte d'investissement
            },
          ),
          const SizedBox(height: 80),
          // Espace pour le FAB ne pas masquer le dernier élément
        ],
      ),
      // --- AJOUT DU FLOATINGACTIONBUTTON ---
      floatingActionButton: FloatingActionButton(
        onPressed: _naviguerVersCreationCompte,
        tooltip: 'Ajouter un compte',
        backgroundColor: theme.colorScheme.primary,
        // Couleur du thème pour le FAB
        child: const Icon(Icons.add, color: Colors.white), // Icône blanche
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .endFloat, // Position par défaut
    );
  }

  // Helper widget pour les diviseurs de section
  Widget _buildSectionDivider(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
        // Espace avant
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Divider(
            color: Theme
                .of(context)
                .dividerColor
                .withOpacity(0.5),
            thickness: 2,
            // Un peu plus fin peut-être
            height: 20,
            indent: 16,
            endIndent: 16,
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
        // Espace après
      ],
    );
  }

  // Helper widget pour construire une section de comptes (factorisation)
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
      // Padding horizontal pour la section
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding( // Padding pour le titre de la section
            padding: const EdgeInsets.only(
                left: 0.0, right: 0.0, top: 8.0, bottom: 8.0),
            // Ajusté le padding pour le titre
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
          // const SizedBox(height: 8.0), // Peut-être pas nécessaire si le padding du titre est suffisant
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
                  couleurSoldeCompte = theme.colorScheme
                      .onSurface; // Gris pour dettes/crédits à zéro
                } else if (compte.type == TypeDeCompte.dette ||
                    compte.type == TypeDeCompte.credit) {
                  couleurSoldeCompte = Colors
                      .orangeAccent; // Orange pour dettes/crédits non nuls
                } else if (compte.solde >= 0) {
                  couleurSoldeCompte = theme.colorScheme
                      .onSurface; // Couleur par défaut pour positif ou vert
                } else {
                  couleurSoldeCompte = Colors.redAccent; // Rouge pour négatif
                }


                return Card(
                  elevation: 2.0,
                  // Petite ombre subtile
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  // Espace entre les cards
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: compte.couleur,
                      // Utilisation de la couleur du compte
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
          // Espace en bas de la section
        ],
      ),
    );
  }
}

// Extension pour capitaliser la première lettre (utilisée pour le nom du type de compte)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}


// --- PLACEHOLDER POUR EcranCreationCompte ---
// Vous devriez avoir votre propre page bien sûr, mais pour que ce fichier soit testable
// si vous n'avez pas encore lié le vrai fichier EcranCreationCompte.
// Si vous avez votre fichier `ecran_creation_compte.dart` fonctionnel,
// vous pouvez supprimer ce placeholder et vous assurer que l'import en haut est correct.

// class EcranCreationCompte extends StatelessWidget {
//   const EcranCreationCompte({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Créer un Nouveau Compte (Placeholder)'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Formulaire de création de compte ici.'),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 // Simule la création et retourne true
//                 Navigator.pop(context, true);
//               },
//               child: const Text('Simuler la création et retourner'),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }