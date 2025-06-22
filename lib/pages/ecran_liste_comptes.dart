import 'package:flutter/material.dart';
import 'package:toutie_budget/models/compte_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Pas besoin d'initialiser _tousLesComptes ici, car StreamBuilder s'en chargera
  }

  // Les getters pour filtrer et calculer les soldes fonctionneront
  // sur la liste des comptes fournie par le StreamBuilder.

  // Helper pour construire un Compte depuis un DocumentSnapshot
  Compte _compteFromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    // S'assurer que les noms des champs correspondent à ceux dans Firestore
    // et que votre modèle Compte a un constructeur ou une factory correspondante.
    return Compte(
      id: doc.id,
      nom: data['nom'] ?? 'Nom inconnu',
      // Assurez-vous que la conversion du type de String vers enum est robuste
      type: TypeDeCompte.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == (data['type'] ?? 'compteBancaire'),
        orElse: () =>
        TypeDeCompte
            .compteBancaire, // Valeur par défaut si non trouvé ou invalide
      ),
      solde: (data['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      // Utiliser soldeActuel ou soldeInitial
      // Si vous avez un champ couleurValue dans votre modèle et Firestore :
      couleurValue: data['couleurValue'] as int? ??
          Colors.blue.value, // Valeur par défaut
      // dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(), // Si vous stockez et utilisez la date
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      // Cas où l'utilisateur n'est pas (encore) connecté
      // Peut arriver brièvement au démarrage ou si la session expire.
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

    // Le StreamBuilder devient le widget racine pour la partie dynamique du corps
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('comptes')
          .orderBy('nom') // Ou 'dateCreation', etc.
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          print("Erreur Firestore Stream: ${snapshot.error}");
          return Scaffold(
              body: Center(
                  child: Text('Une erreur est survenue: ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // L'utilisateur est connecté mais n'a aucun compte.
          // On peut afficher la structure de la page avec des messages "Aucun compte".
          // Ou un message unique invitant à créer un compte.
          // Pour cet exemple, je vais réutiliser votre structure avec des listes vides.
          final List<Compte> tousLesComptes = []; // Liste vide
          return _buildComptesUI(context, theme, tousLesComptes);
        }

        // Transformer les documents Firestore en une liste d'objets Compte
        final List<Compte> tousLesComptes = snapshot.data!.docs.map(
            _compteFromSnapshot).toList();

        // Maintenant, passez cette liste à une méthode qui construit l'UI
        return _buildComptesUI(context, theme, tousLesComptes);
      },
    );
  }

  // Nouvelle méthode pour construire l'interface utilisateur des comptes
  // afin de ne pas dupliquer la logique dans le StreamBuilder
  Widget _buildComptesUI(BuildContext context, ThemeData theme,
      List<Compte> tousLesComptes) {
    // Vos getters existants fonctionneront maintenant sur la liste `tousLesComptes`
    // qui est passée en argument, et qui vient de Firestore.
    List<Compte> getComptesCourants() {
      return tousLesComptes.where((compte) =>
      compte.type == TypeDeCompte.compteBancaire).toList();
    }
    List<Compte> getComptesDettes() {
      return tousLesComptes
          .where((compte) =>
          compte.type == TypeDeCompte.dette ||
          compte.type == TypeDeCompte.credit) // <--- MODIFICATION ICI
          .toList();
    }
    List<Compte> getComptesInvestissements() {
      return tousLesComptes.where((compte) =>
      compte.type == TypeDeCompte.investissement).toList();
    }

    double getSoldeTotalComptesCourants() {
      return getComptesCourants().fold(0.0, (sum, item) => sum + item.solde);
    }
    double getSoldeTotalDettes(List<Compte> comptesDettes) { // Assurez-vous de passer la liste filtrée
      return comptesDettes.fold(0.0, (sum, item) => sum + item.solde);
    }
    double getSoldeTotalInvestissements() {
      return getComptesInvestissements().fold(
          0.0, (sum, item) => sum + item.solde);
    }

    final comptesCourants = getComptesCourants();
    final soldeTotalComptesCourants = getSoldeTotalComptesCourants();
    final comptesDettes = getComptesDettes(); // Appeler avec la liste complète
    final soldeTotalDettes = getSoldeTotalDettes(comptesDettes);
    final comptesInvestissements = getComptesInvestissements();
    final soldeTotalInvestissements = getSoldeTotalInvestissements();


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
              child: Container(/* ... Votre bandeau Toutes les transactions ... */
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
          // ... Vos Dividers et Paddings ...
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Theme
                .of(context)
                .dividerColor,
                thickness: 1,
                height: 20,
                indent: 16,
                endIndent: 16),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),

          // SECTION "ARGENT COMPTANT"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(/* ... Titre Argent Comptant ... */
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Argent Comptant',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold)),
                    Text(
                      '${soldeTotalComptesCourants.toStringAsFixed(2)} \$',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: soldeTotalComptesCourants >= 0 ? Colors
                              .greenAccent[400] : Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                if (comptesCourants.isEmpty)
                  Padding(/* ... Aucun compte ... */
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('Aucun compte de ce type.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comptesCourants.length,
                    itemBuilder: (context, index) {
                      final compte = comptesCourants[index];
                      return Card(
                        // Utilisez la couleur du compte ici si vous le souhaitez
                        // color: compte.couleur.withOpacity(0.1), // Exemple
                        child: ListTile(
                          leading: CircleAvatar( // Exemple d'utilisation de la couleur
                            backgroundColor: compte.couleur,
                            child: Text(compte.nom.isNotEmpty ? compte.nom[0]
                                .toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(compte.nom, style: theme.textTheme
                              .titleMedium),
                          trailing: Text(
                            '${compte.solde.toStringAsFixed(2)} \$',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: compte.solde >= 0 ? theme.colorScheme
                                    .onSurface : Colors.redAccent),
                          ),
                          onTap: () {
                            print('Compte ${compte.nom} cliqué (ID: ${compte
                                .id})');
                            // TODO: Naviguer vers les détails/transactions du compte
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 25.0),
              ],
            ),
          ),
          // ... Vos Dividers et Paddings ...
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Theme
                .of(context)
                .dividerColor,
                thickness: 1,
                height: 20,
                indent: 16,
                endIndent: 16),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),

          // --- SECTION DETTES ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row( // Titre Dettes
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dettes', // Le titre de la section reste "Dettes"
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${soldeTotalDettes.toStringAsFixed(2)} \$', // Ceci inclura maintenant les soldes des crédits
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: soldeTotalDettes == 0 ? theme.colorScheme.onSurface : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                if (comptesDettes.isEmpty) // Ce message s'affichera si aucun compte de type dette OU credit n'existe
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                        child: Text(
                          'Aucune dette ou crédit enregistré.', // Vous pouvez ajuster le message
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        )),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comptesDettes.length, // La liste inclut maintenant les crédits
                    itemBuilder: (context, index) {
                      final compte = comptesDettes[index]; // Peut être un Compte de type 'dette' ou 'credit'
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundColor: compte.couleur,
                              child: Text(
                                  compte.nom.isNotEmpty
                                      ? compte.nom[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white))),
                          title: Text(compte.nom, style: theme.textTheme.titleMedium),
                          trailing: Text(
                            '${compte.solde.toStringAsFixed(2)} \$',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: compte.solde == 0
                                  ? theme.colorScheme.onSurface
                                  : Colors.orangeAccent, // Style cohérent pour dettes et crédits
                            ),
                          ),
                          onTap: () {
                            print('Compte ${compte.type.toString().split('.').last} ${compte.nom} cliqué (ID: ${compte.id})');

                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 25.0),
              ],
            ),
          ),
          // ... Vos Dividers et Paddings ...
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Theme
                .of(context)
                .dividerColor,
                thickness: 1,
                height: 20,
                indent: 16,
                endIndent: 16),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),

          // --- SECTION INVESTISSEMENTS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(/* ... Titre Investissements ... */
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Investissements',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold)),
                    Text(
                      '${soldeTotalInvestissements.toStringAsFixed(2)} \$',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: soldeTotalInvestissements == 0
                              ? theme.colorScheme.onSurface
                              : (soldeTotalInvestissements > 0 ? Colors
                              .greenAccent[400] : Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                if (comptesInvestissements.isEmpty)
                  Padding(/* ... Aucun investissement ... */
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text(
                        'Aucun investissement enregistré.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comptesInvestissements.length,
                    itemBuilder: (context, index) {
                      final compte = comptesInvestissements[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: compte.couleur,
                              child: Text(compte.nom.isNotEmpty ? compte.nom[0]
                                  .toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white))),
                          title: Text(compte.nom, style: theme.textTheme
                              .titleMedium),
                          trailing: Text(
                            '${compte.solde.toStringAsFixed(2)} \$',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: compte.solde == 0 ? theme.colorScheme
                                    .onSurface : (compte.solde > 0 ? Colors
                                    .greenAccent[400] : Colors.redAccent)),
                          ),
                          onTap: () {
                            print('Compte d\'investissement ${compte
                                .nom} cliqué (ID: ${compte.id})');
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}