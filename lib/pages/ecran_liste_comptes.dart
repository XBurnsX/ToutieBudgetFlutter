import 'package:flutter/material.dart';

// --- MODÈLES DE DONNÉES SPÉCIFIQUES À CET ÉCRAN OU PARTAGÉS ---
enum TypeDeCompte {
  compteBancaire, // Sera notre "Compte Courant" / "Argent Comptant"
  dette,
  investissement,
}

class Compte {
  String id;
  String nom;
  TypeDeCompte type;
  double solde;

  Compte({
    required this.id,
    required this.nom,
    required this.type,
    required this.solde,
  });
}

// --- L'ÉCRAN LUI-MÊME ---
class EcranListeComptes extends StatefulWidget {
  const EcranListeComptes({super.key});

  @override
  State<EcranListeComptes> createState() => _EcranListeComptesState();
}

class _EcranListeComptesState extends State<EcranListeComptes> {
  final List<Compte> _tousLesComptes = [
    Compte(id: 'c1', nom: 'Compte Chèque Principal', type: TypeDeCompte.compteBancaire, solde: 1250.75),
    Compte(id: 'c2', nom: 'Compte Épargne Avenir', type: TypeDeCompte.compteBancaire, solde: 5300.00),
    Compte(id: 'd1', nom: 'Prêt Étudiant', type: TypeDeCompte.dette, solde: -8750.00),
    Compte(id: 'i1', nom: 'CELI Investissements', type: TypeDeCompte.investissement, solde: 12000.00),
    Compte(id: 'c3', nom: 'Petite Caisse', type: TypeDeCompte.compteBancaire, solde: 150.00),
  ];

  // Filtrer les comptes pour la section "Compte Courant"
  List<Compte> get _comptesCourants {
    return _tousLesComptes.where((compte) => compte.type == TypeDeCompte.compteBancaire).toList();
  }

  // Calculer le solde total des comptes courants
  double get _soldeTotalComptesCourants {
    return _comptesCourants.fold(0.0, (sum, item) => sum + item.solde);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Note: L'AppBar affichée sera celle de EcranAccueil si EcranListeComptes
    // est un onglet de EcranAccueil. Le titre 'Comptes' devrait venir
    // de la logique de _titresAppBar dans EcranAccueil.

    return Scaffold(
      // Si EcranListeComptes avait son propre AppBar dédié (poussé comme une nouvelle route):

      body: ListView( // Utiliser ListView pour permettre le défilement
        children: <Widget>[
          const SizedBox(height: 15.0),
          // BANDEAU "TOUTES LES TRANSACTIONS"
          Material(
            color: theme.cardColor,
            child: InkWell(
              onTap: () {
                print("Bandeau Toutes les transactions cliqué");
                // TODO: Naviguer vers l'écran de toutes les transactions
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Toutes les transactions',
                      style: theme.textTheme.titleMedium,
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // PADDING SOUS LE BANDEAU "TOUTES LES TRANSACTIONS"
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0), // Ajustez la hauteur du padding
          ),

          // SECTION "COMPTE COURANT" / "ARGENT COMPTANT"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITRE DE LA SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Argent Comptant', // Ou "Comptes Courants"
                      style: theme.textTheme.titleLarge?.copyWith(
                        // fontSize: 18, // Si vous voulez une taille spécifique pour les titres de section
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_soldeTotalComptesCourants.toStringAsFixed(2)} \$',
                      style: theme.textTheme.titleLarge?.copyWith(
                        // fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _soldeTotalComptesCourants >= 0 ? Colors.greenAccent[400] : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0), // Petit espace avant la liste des comptes

                // LISTE DES COMPTES COURANTS
                if (_comptesCourants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                        child: Text(
                          'Aucun compte de ce type.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        )
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true, // Important dans un ListView parent
                    physics: const NeverScrollableScrollPhysics(), // Important dans un ListView parent
                    itemCount: _comptesCourants.length,
                    itemBuilder: (context, index) {
                      final compte = _comptesCourants[index];
                      return Card( // Chaque compte dans une Card
                        // margin: const EdgeInsets.symmetric(vertical: 4.0), // Déjà dans le thème de la Card
                        child: ListTile(
                          title: Text(compte.nom, style: theme.textTheme.titleMedium),
                          trailing: Text(
                            '${compte.solde.toStringAsFixed(2)} \$',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: compte.solde >= 0 ? theme.colorScheme.onSurface : Colors.redAccent,
                            ),
                          ),
                          onTap: () {
                            // TODO: Naviguer vers les détails du compte ou les transactions de ce compte
                            print('Compte ${compte.nom} cliqué');
                          },
                        ),
                      );
                    },
                  ),

                // PADDING SUPPLÉMENTAIRE EN HAUTEUR AVANT LA PROCHAINE SECTION (SI NÉCESSAIRE)
                const SizedBox(height: 24.0), // Ajustez cette hauteur
              ],
            ),
          ),

          // TODO: Ajouter ici les autres sections (Crédit, Prêts, Investissement)
          // en suivant une structure similaire (Titre de section + Liste de comptes)

        ],
      ),
      // Le FAB est hérité de l'EcranAccueil ou peut être défini ici si nécessaire
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // TODO: Naviguer vers un écran de création de compte
      //     print("Ajouter un nouveau compte depuis EcranListeComptes");
      //   },
      //   child: const Icon(Icons.add),
      //   tooltip: 'Ajouter un compte',
      // ),
    );
  }
}