// lib/pages/ecran_accueil.dart
// (Assurez-vous que le chemin d'accès au fichier est correct dans votre projet)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ecran_ajout_transaction.dart';
import 'ecran_creation_compte.dart';
import 'ecran_liste_comptes.dart';
import 'ecran_budget.dart';

class PageStatistiques extends StatelessWidget {
  const PageStatistiques({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Contenu de la page Statistiques'));
  }
}

class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  int _indiceSelectionne = 0;
  User? _currentUser;
  bool _isSigningIn = false;

  final List<String> _nomsDesComptesActuels = [ // Assurez-vous que c'est bien ici
    "Compte Courant",
    "Épargne",
    "Carte de Crédit Perso",
  ];

  Future<void> _performAnonymousSignIn() async {
    if (mounted) setState(() => _isSigningIn = true);

    if (FirebaseAuth.instance.currentUser != null) {
      if (mounted) {
        setState(() {
          _currentUser = FirebaseAuth.instance.currentUser;
          _isSigningIn = false;
        });
      }
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (userCredential.user != null && mounted) {
        setState(() => _currentUser = userCredential.user);
      }
    } catch (e) {
      print("EcranAccueil: Erreur connexion anonyme: $e");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _performAnonymousSignIn();
  }

  static List<Widget> _getOptionsDesPagesPrincipales(User? currentUser) {
    return <Widget>[
      const EcranBudget(),
      const EcranListeComptes(),
      const PageStatistiques(),
    ];
  }

  void _naviguerVersCreationCompte() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur de connexion. Veuillez réessayer.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    ).then((resultat) {
      if (resultat == true) {
        // TODO: Rafraîchir la liste des comptes si un compte a été ajouté
        print("Retour de la création de compte, rafraîchir si nécessaire.");
      }
    });
  }

  void _auChangementOnglet(int indexDepuisNavBar) {
    if (indexDepuisNavBar == 2) { // Bouton "Nouveau"
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur de connexion. Veuillez réessayer.")),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EcranAjoutTransaction(
                comptesExistants: _nomsDesComptesActuels,
              ),
        ),
      ).then((transactionAjoutee) {
        if (transactionAjoutee == true) {
          // TODO: Rafraîchir les données du budget/transactions
          print("Retour de l'ajout de transaction, rafraîchir si nécessaire.");
        }
      });
      return;
    }

    int nouvelIndicePrincipal;
    if (indexDepuisNavBar == 0) {
      nouvelIndicePrincipal = 0; // Budget
    } else if (indexDepuisNavBar == 1) nouvelIndicePrincipal = 1; // Comptes
    else if (indexDepuisNavBar == 3) nouvelIndicePrincipal = 2; // Stats
    else
      nouvelIndicePrincipal = _indiceSelectionne;

    setState(() => _indiceSelectionne = nouvelIndicePrincipal);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSigningIn) {
      return const Scaffold(body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Connexion en cours...")
          ])));
    }

    if (_currentUser == null && !_isSigningIn) {
      return Scaffold(body: Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
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
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _performAnonymousSignIn,
                    child: const Text("Réessayer la connexion"))
              ]))));
    }

    final List<Widget> pagesPrincipales = _getOptionsDesPagesPrincipales(
        _currentUser);
    // final bool estSurOngletComptes = _indiceSelectionne == 1; // Plus directement utilisé ici si AppBar est enlevée

    return Scaffold(
      // appBar: AppBar(...), // <--- TOUTE L'APPBAR EST SUPPRIMÉE ICI
      body: IndexedStack( // Utiliser IndexedStack pour préserver l'état des pages enfants
        index: (_indiceSelectionne >= 0 &&
            _indiceSelectionne < pagesPrincipales.length)
            ? _indiceSelectionne
            : 0,
        children: pagesPrincipales,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Comptes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Nouveau'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
        currentIndex: (_indiceSelectionne == 0) ? 0 : (_indiceSelectionne == 1)
            ? 1
            : (_indiceSelectionne == 2) ? 3 : _indiceSelectionne,
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        onTap: _auChangementOnglet,
        type: BottomNavigationBarType.fixed,
      ),
      // Si vous aviez besoin d'un FloatingActionButton conditionnel :
      // floatingActionButton: _indiceSelectionne == 1 // Si onglet Comptes
      //     ? FloatingActionButton(
      //         onPressed: _naviguerVersCreationCompte,
      //         tooltip: 'Ajouter un compte',
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
    );
  }
}