import 'package:flutter/material.dart';
import 'ecran_ajout_transaction.dart';
import 'ecran_creation_compte.dart.dart';
import 'ecran_liste_comptes.dart';


// --- Pages de contenu factices (nous les mettrons dans des fichiers séparés plus tard) ---
class PageBudget extends StatelessWidget {
  const PageBudget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Contenu de la page Budget'));
  }
}

class PageStatistiques extends StatelessWidget {
  const PageStatistiques({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Contenu de la page Statistiques'));
  }
}

// Un widget simple pour les actions qui ne changent pas la page principale
class PageActionSpeciale extends StatelessWidget {
  final String messageAction;
  const PageActionSpeciale({super.key, required this.messageAction});

  @override
  Widget build(BuildContext context) {
    print(messageAction); // Affiche le message dans la console quand cette "page" est sélectionnée
    return const SizedBox.shrink(); // Ne prend pas de place visible
  }
}
// --- Fin des pages de contenu factices ---

class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  int _indiceSelectionne = 0; // Onglet actif, commence par Budget (index 0)

  static const List<Widget> _optionsDesPagesPrincipales = <Widget>[
    PageBudget(),
    EcranListeComptes(),
    PageStatistiques(),
  ];

  // Titres pour l'AppBar correspondants aux pages principales
  static const List<String> _titresAppBar = <String>[
    'Budget',
    'Compte',
    'Statistiques',
  ];
  List<String> _nomsDesComptesActuels = [
    "Compte Courant",
    "Épargne",
    "Carte de Crédit Perso",
    // ... autres comptes réels
  ];
  void _naviguerVersCreationCompte() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    ).then((resultat) {
      if (resultat == true) {
        print("Retour de l'écran de création de compte, un compte pourrait avoir été ajouté.");
        // TODO: Rafraîchir _nomsDesComptesActuels si un nouveau compte a été ajouté
        // Cela dépendra de comment vous gérez l'état global de vos comptes.
        // Si EcranCreationCompte ajoute à une base de données, vous devrez peut-être recharger ici.
        // setState(() { _chargerComptes(); }); // Par exemple
      }
    });
  }
  void _auChangementOnglet(int index) {
    if (index == 2) { // Si c'est le bouton "Nouvelle Transaction"
      // --- C'EST ICI LA MODIFICATION ---
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EcranAjoutTransaction(
            comptesExistants: _nomsDesComptesActuels, // PASSER LA LISTE ICI
          ),
        ),
      ).then((transactionAjoutee) {
        if (transactionAjoutee == true) {
          // Une transaction a été ajoutée.
          // Vous pourriez vouloir rafraîchir des données ici si nécessaire (ex: soldes, liste de transactions)
          print("Retour de l'écran d'ajout de transaction : une transaction a été ajoutée.");
          // Si une transaction a créé un nouveau compte de dette, vous pourriez aussi vouloir
          // rafraîchir _nomsDesComptesActuels.
          // setState(() { _chargerComptes(); }); // Par exemple
        }
      });
      return; // Ne pas changer l'onglet sélectionné
    }

    int nouvelIndicePrincipal = index;
    if (index > 2) {
      nouvelIndicePrincipal = index - 1;
    }

    setState(() {
      _indiceSelectionne = nouvelIndicePrincipal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool estSurOngletComptes = _indiceSelectionne == 1;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_titresAppBar[_indiceSelectionne]}'),
        centerTitle: true,
        actions: <Widget>[
          // Afficher le bouton "+" uniquement si l'onglet "Compte" est sélectionné
          if (estSurOngletComptes) // Condition pour afficher le bouton
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter un compte',
              onPressed: _naviguerVersCreationCompte,
            ),
        ],
      ),
      body: Center(
        child: _optionsDesPagesPrincipales.elementAt(_indiceSelectionne),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Compte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), // Icône pour Nouvelle Transaction
            label: 'Nouveau',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
        // currentIndex est un peu délicat ici car notre bouton "Nouveau" n'a pas de page principale correspondante.
        // On va le gérer pour que l'onglet visuellement sélectionné soit correct.
        // Si _indiceSelectionne est pour Budget (0) ou Compte (1), c'est direct.
        // Si _indiceSelectionne est pour Stats (2 dans _optionsDesPagesPrincipales),
        // alors l'index visuel dans la barre est 3.
        currentIndex: _indiceSelectionne >= 2 ? _indiceSelectionne + 1 : _indiceSelectionne,
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        onTap: _auChangementOnglet,
        type: BottomNavigationBarType.fixed, // Pour que tous les labels soient visibles
      ),
    );
  }
}