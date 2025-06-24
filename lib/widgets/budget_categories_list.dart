// lib/pages/ecran_liste_comptes.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pour le formatage des nombres/devises

// Import du modèle Compte centralisé
import '../models/compte_model.dart'; // Assurez-vous que ce chemin est correct

// Import de l'écran de création de compte
import '../pages/ecran_creation_compte.dart';

class EcranListeComptes extends StatefulWidget {
  const EcranListeComptes({super.key});

  @override
  State<EcranListeComptes> createState() => _EcranListeComptesState();
}

class _EcranListeComptesState extends State<EcranListeComptes> {
  User? _currentUser;
  Stream<List<Compte>>? _comptesStream;
  Stream<double>? _soldeTotalStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _comptesStream = _getComptesStream();
      _soldeTotalStream = _getSoldeTotalStream();
    } else {
      debugPrint(
          "EcranListeComptes: Aucun utilisateur connecté à l'initialisation.");
      // Gérer ici si l'utilisateur n'est pas connecté (ex: redirection)
    }
  }

  Stream<List<Compte>>? _getComptesStream() {
    if (_currentUser == null)
      return Stream.value([]); // Retourne un stream avec une liste vide
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('comptes')
        .orderBy('nom') // Optionnel: trier par nom, ou 'dateCreation'
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return <Compte>[];
      }
      final comptes = querySnapshot.docs.map((doc) {
        try {
          return Compte.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>);
        } catch (e, stacktrace) {
          debugPrint("EcranListeComptes - ERREUR lors du mapping du Compte ${doc
              .id}: $e");
          debugPrint("Stacktrace: $stacktrace");
          return null;
        }
      }).whereType<Compte>().toList(); // Filtre les nulls
      return comptes;
    }).handleError((error, stacktrace) {
      debugPrint(
          "EcranListeComptes - Erreur dans le stream des comptes: $error");
      debugPrint("Stacktrace: $stacktrace");
      return <Compte>[]; // Retourne une liste vide en cas d'erreur
    });
  }

  Stream<double>? _getSoldeTotalStream() {
    if (_currentUser == null) return Stream.value(0.0);
    return _comptesStream?.map((listComptes) {
      if (listComptes.isEmpty) return 0.0;
      return listComptes.fold(
          0.0, (sum, item) => sum + item.soldeActuel); // Utilise soldeActuel
    }) ?? Stream.value(
        0.0); // Fournit une valeur par défaut si _comptesStream est null
  }

  void _naviguerVersCreationCompte() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcranCreationCompte()),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("Nouveau compte ajouté."),
          duration: Duration(seconds: 2),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes Comptes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Veuillez vous connecter pour voir vos comptes.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Comptes'),
        actions: [
          StreamBuilder<double>(
            stream: _soldeTotalStream,
            builder: (context, snapshotSolde) {
              if (snapshotSolde.connectionState == ConnectionState.waiting &&
                  !snapshotSolde.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                );
              }
              if (snapshotSolde.hasError || !snapshotSolde.hasData ||
                  snapshotSolde.data == null) {
                return const SizedBox
                    .shrink(); // Ne rien afficher en cas d'erreur ou pas de données
              }
              final total = snapshotSolde.data!;
              final currencyFormat = NumberFormat.currency(
                  locale: 'fr_CA', symbol: '\$', decimalDigits: 2);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    currencyFormat.format(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: total >= 0 ? Colors.greenAccent.shade400 : Colors
                            .redAccent.shade400,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Compte>>(
        stream: _comptesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint(
                "EcranListeComptes - Erreur du StreamBuilder principal: ${snapshot
                    .error}");
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Erreur de chargement des comptes: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ));
          }
          if (!snapshot.hasData || snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          final comptes = snapshot.data!;
          return ListView.separated(
            itemCount: comptes.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            // Padding vertical pour la liste entière
            separatorBuilder: (context, index) =>
                Divider(
                  height: 1,
                  // Hauteur du Divider (espace qu'il occupe + la ligne)
                  thickness: 0.5,
                  // Épaisseur de la ligne elle-même
                  color: Colors.grey[700],
                  // Couleur de la ligne
                  indent: 16,
                  // Espace à gauche avant le début de la ligne
                  endIndent: 16, // Espace à droite avant la fin de la ligne
                ),
            itemBuilder: (context, index) {
              final compte = comptes[index];
              return _buildCompteListItem(theme, compte);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _naviguerVersCreationCompte,
        label: const Text('Nouveau Compte'),
        icon: const Icon(Icons.add),
        // Vous pouvez décommenter et personnaliser le style si besoin
        // style: ElevatedButton.styleFrom(
        //   backgroundColor: theme.colorScheme.primary,
        //   foregroundColor: theme.colorScheme.onPrimary,
        // ),
      ),
    );
  }

  Widget _buildCompteListItem(ThemeData theme, Compte compte) {
    final currencyFormat = NumberFormat.currency(
        locale: 'fr_CA', symbol: '\$', decimalDigits: 2);
    final Color couleurCompte = compte
        .couleur; // `compte.couleur` doit être non-null grâce à la valeur par défaut dans fromSnapshot
    final double soldeAAfficher = compte.soldeActuel;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: couleurCompte.withOpacity(0.2),
        child: Icon(Icons.account_balance_wallet_outlined, color: couleurCompte,
            size: 24),
      ),
      title: Text(
        compte.nom,
        style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        compte.typeDisplayName, // Utilise le getter pour un nom de type formaté
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
      ),
      trailing: Text(
        currencyFormat.format(soldeAAfficher),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: soldeAAfficher >= 0 ? theme.colorScheme.primary : theme
              .colorScheme.error,
        ),
      ),
      onTap: () {
        debugPrint('Compte ${compte.nom} cliqué. ID: ${compte.id}');
        // TODO: Naviguer vers l'écran de détails du compte si nécessaire
        // Navigator.push(context, MaterialPageRoute(builder: (context) => EcranDetailsCompte(compteId: compte.id)));
      },
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 10.0), // Padding pour chaque ListTile
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.account_balance_outlined, size: 80,
                color: Colors.grey[600]),
            const SizedBox(height: 20),
            Text(
              'Aucun compte pour le moment',
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Appuyez sur le bouton "+" pour ajouter votre premier compte.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}