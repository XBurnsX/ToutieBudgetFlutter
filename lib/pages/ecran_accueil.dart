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
    const EcranListeComptes(),
    PageStatistiques(),
  ];

  // Titres pour l'AppBar correspondants aux pages principales
  static const List<String> _titresAppBar = <String>[
    'Budget',
    'Compte',
    'Statistiques',
  ];
  void _naviguerVersCreationCompte() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    ).then((resultat) {
      // Optionnel : Gérer le résultat si EcranCreationCompte retourne quelque chose
      // Par exemple, si un nouveau compte a été créé, vous pourriez vouloir
      // forcer un rafraîchissement de EcranListeComptes.
      // Cela dépendra de comment vous gérez l'état des comptes (plus tard).
      if (resultat == true) { // Supposons que true signifie qu'un compte a été ajouté
        // Pour l'instant, on ne fait rien de spécial ici, car EcranListeComptes
        // devrait se reconstruire si ses propres données changent.
        // Si EcranListeComptes a besoin d'être explicitement notifié,
        // une solution de gestion d'état plus avancée serait utile.
        print("Retour de l'écran de création de compte, un compte pourrait avoir été ajouté.");
      }
    });
  }
  void _auChangementOnglet(int index) {
    if (index == 2) { // Si c'est le bouton "Nouvelle Transaction"
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EcranAjoutTransaction()),
      ).then((_) {
        // ...
      });
      return;
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