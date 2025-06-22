// lib/pages/ecran_accueil.dart
// (Assurez-vous que le chemin d'accès au fichier est correct dans votre projet)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORTATION POUR FIREBASE AUTH

// Assurez-vous que les chemins vers vos autres écrans sont corrects
import 'ecran_ajout_transaction.dart';
import 'ecran_creation_compte.dart.dart';
import 'ecran_liste_comptes.dart';

// --- Pages de contenu factices (vous pouvez les garder ou les déplacer) ---
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
// --- Fin des pages de contenu factices ---

class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  int _indiceSelectionne = 0; // Onglet actif, commence par Budget (index 0)
  User? _currentUser; // Pour stocker l'utilisateur Firebase connecté
  bool _isSigningIn = false; // Pour gérer l'état de chargement de la connexion

  // Méthode pour gérer la connexion anonyme
  Future<void> _performAnonymousSignIn() async {
    if (mounted) {
      setState(() {
        _isSigningIn = true;
      });
    }

    // Vérifier si un utilisateur est déjà connecté (par exemple, d'une session précédente)
    if (FirebaseAuth.instance.currentUser != null) {
      print("EcranAccueil: User already signed in. UID: ${FirebaseAuth.instance
          .currentUser!.uid}");
      if (mounted) {
        setState(() {
          _currentUser = FirebaseAuth.instance.currentUser;
          _isSigningIn = false;
        });
      }
      return;
    }

    // Si aucun utilisateur n'est connecté, tenter une connexion anonyme
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("EcranAccueil: Successfully signed in anonymously.");
      if (userCredential.user != null) {
        if (mounted) {
          setState(() {
            _currentUser = userCredential.user;
            // _isSigningIn sera mis à false dans le bloc finally
          });
        }
        print("EcranAccueil: User ID (UID): ${userCredential.user!.uid}");
      }
    } on FirebaseAuthException catch (e) {
      print("EcranAccueil: Firebase Auth Exception: ${e.message} (Code: ${e
          .code})");
      if (e.code == "operation-not-allowed") {
        print(
            "IMPORTANT: Anonymous auth hasn't been enabled for this project in the Firebase console.");
        // Vous pourriez vouloir afficher une erreur plus visible à l'utilisateur ici,
        // par exemple en mettant à jour une variable d'état pour afficher un message d'erreur spécifique.
      }
      // Gérer d'autres erreurs spécifiques si nécessaire
    } catch (e) {
      print("EcranAccueil: Unexpected error during anonymous sign-in: $e");
      // Gérer l'erreur, peut-être afficher un message
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn =
          false; // Assurer que l'indicateur de chargement s'arrête
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _performAnonymousSignIn(); // Appel de la fonction de connexion lors de l'initialisation
  }

  // Définition des pages principales pour la navigation
  // Note: Vous pourriez vouloir passer l'UID à ces pages si elles en ont besoin pour charger des données
  static List<Widget> _getOptionsDesPagesPrincipales(User? currentUser) {
    // String? uid = currentUser?.uid; // Pour passer l'UID si nécessaire
    return <Widget>[
      const PageBudget(), // Exemple: PageBudget(uid: uid)
      const EcranListeComptes(), // Exemple: EcranListeComptes(uid: uid)
      const PageStatistiques(), // Exemple: PageStatistiques(uid: uid)
    ];
  }

  // Titres pour l'AppBar correspondants aux pages principales
  static const List<String> _titresAppBar = <String>[
    'Budget',
    'Comptes',
    // J'ai changé "Compte" en "Comptes" pour correspondre à EcranListeComptes
    'Statistiques',
  ];

  // TODO: Remplacer cette liste statique par des données chargées (par exemple, depuis Firebase)
  // Cette liste sera probablement gérée différemment une fois que vous chargerez les comptes
  // depuis Firebase en utilisant l'UID de _currentUser.
  List<String> _nomsDesComptesActuels = [
    "Compte Courant",
    "Épargne",
    "Carte de Crédit Perso",
  ];

  void _naviguerVersCreationCompte() {
    if (_currentUser == null) {
      print("Erreur: Utilisateur non connecté pour créer un compte.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur de connexion. Veuillez réessayer.")),
      );
      // Optionnellement, tenter de se reconnecter
      // _performAnonymousSignIn();
      return;
    }
    // String uid = _currentUser!.uid; // Utiliser l'UID si EcranCreationCompte en a besoin

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const EcranCreationCompte(/* uid: uid */)),
    ).then((resultat) {
      if (resultat == true) {
        print(
            "Retour de l'écran de création de compte, un compte pourrait avoir été ajouté.");
        // TODO: Rafraîchir _nomsDesComptesActuels (potentiellement depuis Firebase en utilisant l'UID)
        // Par exemple: _chargerComptesDepuisFirebase();
      }
    });
  }

  void _auChangementOnglet(int index) {
    if (index ==
        2) { // Si c'est le bouton "Nouvelle Transaction" (index 2 dans BottomNavBar)
      if (_currentUser == null) {
        print("Erreur: Utilisateur non connecté pour ajouter une transaction.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur de connexion. Veuillez réessayer.")),
        );
        // Optionnellement, tenter de se reconnecter
        // _performAnonymousSignIn();
        return;
      }
      // String uid = _currentUser!.uid; // Utiliser l'UID si EcranAjoutTransaction en a besoin

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EcranAjoutTransaction(
                comptesExistants: _nomsDesComptesActuels,
                // Vous passerez l'UID ou une fonction de sauvegarde Firebase ici plus tard
                // exemple: uidUtilisateur: uid,
              ),
        ),
      ).then((transactionAjoutee) {
        if (transactionAjoutee == true) {
          print(
              "Retour de l'écran d'ajout de transaction : une transaction a été ajoutée.");
          // TODO: Rafraîchir les données si nécessaire (par exemple, soldes depuis Firebase)
        }
      });
      return; // Ne pas changer l'onglet sélectionné de la page principale
    }

    // Ajuster l'indice pour les pages principales si l'index vient de la BottomNavBar
    // et que le bouton "Nouveau" (index 2) a été pressé mais géré séparément.
    // L'onglet "Compte" est à l'index 1, "Stats" à l'index 3 dans la BottomNavBar.
    // Mais dans _optionsDesPagesPrincipales, "Stats" est à l'index 2.
    int nouvelIndicePrincipal = index;
    if (index ==
        3) { // Si l'onglet "Stats" (index 3 dans BottomNavBar) est sélectionné
      nouvelIndicePrincipal =
      2; // Correspond à l'index de PageStatistiques dans la liste
    }
    // Si index est 0 (Budget) ou 1 (Compte), nouvelIndicePrincipal est correct.

    setState(() {
      _indiceSelectionne = nouvelIndicePrincipal;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Gérer l'état de connexion en cours
    if (_isSigningIn) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Connexion en cours..."),
            ],
          ),
        ),
      );
    }

    // 2. Gérer l'état où la connexion a échoué (et n'est plus en cours)
    if (_currentUser == null && !_isSigningIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text("Échec de la connexion",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text(
                  "Impossible de se connecter au service. Veuillez vérifier votre connexion internet et que l'authentification anonyme est correctement configurée dans Firebase.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _performAnonymousSignIn, // Bouton pour réessayer
                  child: const Text("Réessayer la connexion"),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 3. Si la connexion est réussie (_currentUser n'est pas null), construire l'UI normale
    final List<Widget> pagesPrincipales = _getOptionsDesPagesPrincipales(
        _currentUser);

    final bool estSurOngletComptes = _indiceSelectionne ==
        1; // 1 est l'index pour EcranListeComptes

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_titresAppBar[_indiceSelectionne]} ${_currentUser != null
              ? "(U:${_currentUser!.uid.substring(0, 5)}..)"
              : ""}',
        ),
        centerTitle: true,
        actions: <Widget>[
          if (estSurOngletComptes)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter un compte',
              onPressed: _naviguerVersCreationCompte,
            ),
        ],
      ),
      body: Center(
        // Assurez-vous que _indiceSelectionne est dans les limites de pagesPrincipales
        child: pagesPrincipales.elementAt(
            _indiceSelectionne < pagesPrincipales.length
                ? _indiceSelectionne
                : 0),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), // Changé l'icône pour "Comptes"
            label: 'Comptes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Nouveau', // Action spéciale, n'a pas de page principale dédiée
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
        // Logique pour currentIndex dans BottomNavigationBar :
        // Si l'onglet "Budget" (page index 0) est sélectionné, currentIndex = 0.
        // Si l'onglet "Comptes" (page index 1) est sélectionné, currentIndex = 1.
        // Le bouton "Nouveau" (index 2 dans BottomNavBar) ne change pas la page principale sélectionnée.
        // Si l'onglet "Stats" (page index 2) est sélectionné, currentIndex = 3.
        currentIndex: _indiceSelectionne == 2 ? 3 : _indiceSelectionne,
        // Ajustement pour Stats
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        onTap: _auChangementOnglet,
        type: BottomNavigationBarType
            .fixed, // Pour que tous les labels soient visibles
      ),
    );
  }
}