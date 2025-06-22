import 'package:flutter/material.dart';
import 'ecran_ajout_transaction.dart';
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
    // Pour l'instant, on retourne juste un widget vide,
    // car l'action sera gérée dans _auChangementOnglet
    // Si vous vouliez afficher quelque chose temporairement, vous pourriez le faire ici.
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

  // Liste des widgets (pages principales) à afficher.
  // L'action "Nouvelle Transaction" est gérée différemment.
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

  void _auChangementOnglet(int index) {
    // Les index de la BottomNavigationBar seront :
    // 0: Budget
    // 1: Compte
    // 2: Nouvelle Transaction (action spéciale)
    // 3: Statistiques

    if (index == 2) { // Si c'est le bouton "Nouvelle Transaction"
      // print('Action : Ouvrir l\'écran Nouvelle Transaction'); // Vous pouvez garder ce print
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EcranAjoutTransaction()), // <<< MODIFIÉ ICI
      ).then((_) {
        // Optionnel: Code à exécuter après le retour de EcranAjoutTransaction
        // Par exemple, rafraîchir la liste des transactions si une nouvelle a été ajoutée.
        // Pour l'instant, on ne fait rien de spécial au retour.
        // Il est important de ne pas appeler setState ici directement si cela
        // change l'onglet actif, car l'utilisateur s'attend à revenir sur l'onglet
        // où il était.
      });
      return; // On sort pour ne pas changer l'onglet principal
    }

    // Pour les autres boutons, on ajuste l'indice pour correspondre à _optionsDesPagesPrincipales
    int nouvelIndicePrincipal = index;
    if (index > 2) { // Si l'index est 3 (Statistiques), il correspond à l'index 2 dans _optionsDesPagesPrincipales
      nouvelIndicePrincipal = index - 1;
    }

    setState(() {
      _indiceSelectionne = nouvelIndicePrincipal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_titresAppBar[_indiceSelectionne]}'),
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