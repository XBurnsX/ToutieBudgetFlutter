import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/compte_bancaire_model.dart';
import '../../models/enveloppe_model.dart';
import '../../models/item_de_selection_transfert.dart';
import '../../services/service_transfert_argent.dart'; // Pour FirebaseAuth.instance


class EcranVirerArgent extends StatefulWidget {
  // Si vous avez besoin de passer des données initiales à cet écran, déclarez-les ici
  // final String argumentInitial;
  // const EcranVirerArgent({Key? key, required this.argumentInitial}) : super(key: key);

  const EcranVirerArgent({super.key});

  @override
  _EcranVirerArgentState createState() => _EcranVirerArgentState();
}

class _EcranVirerArgentState extends State<EcranVirerArgent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth
      .instance; // Accès direct à FirebaseAuth

  User? _currentUser;
  late ServiceTransfertArgent _serviceTransfert; // Sera initialisé dans initState

  bool _isLoading = true;
  String? _errorMessage;

  List<ItemDeSelectionTransfert> _tousLesItemsSelectionnables = [];
  final Map<String, EnveloppeModel> _mapEnveloppesChargees = {};
  final Map<String, String> _mapEnveloppeIdACategorieId = {
  }; // Map<enveloppeId, categorieId>

  ItemDeSelectionTransfert? _selectionSource;
  ItemDeSelectionTransfert? _selectionDestination;
  double? _montantATransferer;
  final double _soldePretAPlacerActuel = 0.0;

  final TextEditingController _montantController = TextEditingController();
  String _valeurClavier = "0";

  @override
  void initState() {
    super.initState();
    print("[EcranVirerArgent - initState] Début de initState.");

    _currentUser = _auth.currentUser;
    _serviceTransfert =
        ServiceTransfertArgent(_firestore); // Initialisation du service

    if (_currentUser == null) {
      print(
          "[EcranVirerArgent - initState] ERREUR CRITIQUE: Utilisateur non connecté lors de l'initialisation !");
      // Gérer cet état : afficher un message, empêcher le chargement, ou naviguer ailleurs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
            "Session utilisateur invalide ou expirée. Veuillez vous reconnecter.";
          });
          // Optionnel : Rediriger vers l'écran de connexion après un court délai
          // Future.delayed(Duration(seconds: 3), () {
          //   if (mounted) Navigator.of(context).pushReplacementNamed('/ecranDeConnexion');
          // });
        }
      });
    } else {
      print(
          "[EcranVirerArgent - initState] Utilisateur initialisé : UID = ${_currentUser!
              .uid}, Email = ${_currentUser!.email}");
      _chargerDonneesInitialesAvecAffichage();
    }
  }

  Future<void> _chargerDonneesInitialesAvecAffichage() async {
    print("[EcranVirerArgent - _chargerDonneesInitialesAvecAffichage] Début.");
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _chargerDonneesInitiales();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    print("[EcranVirerArgent - _chargerDonneesInitialesAvecAffichage] Fin.");
  }
  Future<void> _chargerDonneesInitiales() async {
    print("[EcranVirerArgent - _chargerDonneesInitiales] Début du chargement des données réelles.");

    if (_currentUser == null) {
      print("[EcranVirerArgent - _chargerDonneesInitiales] ERREUR: _currentUser est null.");
      if (mounted) {
        setState(() {
          _errorMessage = "Utilisateur non authentifié. Impossible de charger les données.";
        });
      }
      return;
    }
    print("[EcranVirerArgent - _chargerDonneesInitiales] Utilisateur UID: ${_currentUser!.uid}");

    try {
      List<ItemDeSelectionTransfert> itemsTemp = [];
      _mapEnveloppesChargees.clear();
      _mapEnveloppeIdACategorieId.clear();

      // 1. Charger tous les comptes bancaires de l'utilisateur
      print("[EcranVirerArgent - _chargerDonneesInitiales] Chargement des comptes bancaires...");
      final comptesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('comptes')
          .get();
      print("[EcranVirerArgent - _chargerDonneesInitiales] Nombre de documents de comptes récupérés: ${comptesSnapshot.docs.length}");

      List<CompteBancaireModel> tousLesComptes = comptesSnapshot.docs
          .map((doc) {
        print("[EcranVirerArgent - _chargerDonneesInitiales] Parsing Compte ID: ${doc.id}, Data: ${doc.data()}");
        try {
          return CompteBancaireModel.fromFirestore(doc);
        } catch (e,s) {
          print("[EcranVirerArgent - _chargerDonneesInitiales] ERREUR PARSING COMPTE ID '${doc.id}': $e\nStackTrace: $s");
          return null; // Retourner null si le parsing échoue pour un compte
        }
      })
          .where((compte) => compte != null) // Filtrer les comptes qui ont échoué au parsing
          .cast<CompteBancaireModel>() // S'assurer du bon type après le filtrage
          .toList();
      print("[EcranVirerArgent - _chargerDonneesInitiales] Nombre de CompteBancaireModel chargés: ${tousLesComptes.length}");
      for (var compte in tousLesComptes) {
        print("  > Compte chargé: ${compte.nom}, ID: ${compte.id}, SoldeInitial: ${compte.soldeInitial}");
      }

      // 2. Charger toutes les enveloppes (de toutes les catégories)
      print("[EcranVirerArgent - _chargerDonneesInitiales] Chargement des enveloppes...");
      List<EnveloppeModel> toutesLesEnveloppes = [];
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('categories')
          .get();
      print("[EcranVirerArgent - _chargerDonneesInitiales] Nombre de catégories récupérées: ${categoriesSnapshot.docs.length}");

      for (QueryDocumentSnapshot catDoc in categoriesSnapshot.docs) {
        print("[EcranVirerArgent - _chargerDonneesInitiales] Chargement des enveloppes pour catégorie ID: ${catDoc.id}");
        final enveloppesSnapshot = await catDoc.reference
            .collection('enveloppes')
            .orderBy('nom')
            .get();
        print("  > Nombre d'enveloppes récupérées pour catégorie ${catDoc.id}: ${enveloppesSnapshot.docs.length}");
        for (QueryDocumentSnapshot<Map<String, dynamic>> envDoc in enveloppesSnapshot.docs) {
          print("  > Parsing Enveloppe ID: ${envDoc.id}, Data: ${envDoc.data()}");
          try {
            EnveloppeModel env = EnveloppeModel.fromSnapshot(envDoc);
            toutesLesEnveloppes.add(env);
            _mapEnveloppesChargees[env.id] = env;
            _mapEnveloppeIdACategorieId[env.id] = catDoc.id;
          } catch (e, s) {
            print("[EcranVirerArgent - _chargerDonneesInitiales] ERREUR PARSING ENVELOPPE ID '${envDoc.id}': $e\nStackTrace: $s");
          }
        }
      }
      print("[EcranVirerArgent - _chargerDonneesInitiales] Nombre total d'EnveloppeModel chargées: ${toutesLesEnveloppes.length}");
      for (var env in toutesLesEnveloppes) {
        print("  > Enveloppe chargée: ${env.nom}, ID: ${env.id}, CompteSourceID: ${env.compteSourceId}, Montant: ${env.soldeEnveloppe}");
      }


      // 3. Calculer "Prêt à placer" pour chaque compte
      print("[EcranVirerArgent - _chargerDonneesInitiales] Calcul des 'Prêt à placer'...");
      for (CompteBancaireModel compte in tousLesComptes) {
        print("  > Calcul PAP pour compte: ${compte.nom} (ID: ${compte.id}), SoldeInitial: ${compte.soldeInitial}");
        double totalAlloueAuxEnveloppesPourCeCompte = 0;
        for (EnveloppeModel env in toutesLesEnveloppes) {
          if (env.compteSourceId == compte.id) {
            totalAlloueAuxEnveloppesPourCeCompte += env.soldeEnveloppe;
            print("    >> Enveloppe '${env.nom}' (Montant: ${env.soldeEnveloppe}) est liée à ce compte.");
          }
        }
        print("  > Total alloué aux enveloppes pour compte '${compte.nom}': $totalAlloueAuxEnveloppesPourCeCompte");
        double soldeBrutDuCompte = compte.soldeInitial;
        double soldePretAPlacerDuCompte = soldeBrutDuCompte - totalAlloueAuxEnveloppesPourCeCompte;
        print("  > Solde 'Prêt à placer' calculé pour compte '${compte.nom}': $soldePretAPlacerDuCompte");

        if (soldePretAPlacerDuCompte < 0) {
          print("  ATTENTION: Solde PAP négatif ($soldePretAPlacerDuCompte) pour compte '${compte.nom}'. Sera mis à 0.");
        }

        itemsTemp.add(ItemDeSelectionTransfert(
          id: 'comptepap_${compte.id}',
          nom: '${compte.nom} (Prêt à placer)',
          solde: soldePretAPlacerDuCompte < 0 ? 0 : soldePretAPlacerDuCompte,
          estPretAPlacer: true,
        ));
      }

      // 4. Ajouter les enveloppes elles-mêmes
      print("[EcranVirerArgent - _chargerDonneesInitiales] Ajout des enveloppes comme items de sélection...");
      for (EnveloppeModel env in toutesLesEnveloppes) {
        itemsTemp.add(ItemDeSelectionTransfert(
          id: env.id,
          nom: env.nom,
          solde: env.soldeEnveloppe,
          estPretAPlacer: false,
        ));
        print("  > Item Enveloppe ajouté: ${env.nom}, Solde: ${env.soldeEnveloppe}");
      }
      print("[EcranVirerArgent - _chargerDonneesInitiales] itemsTemp AVANT tri (${itemsTemp.length} items): ${itemsTemp.map((i) => '{Nom: ${i.nom}, PAP: ${i.estPretAPlacer}, Solde: ${i.solde}, ID: ${i.id}}').toList()}");


      // 5. Trier et mettre à jour la liste principale
      if (itemsTemp.isNotEmpty) {
        List<ItemDeSelectionTransfert> itemsPretAPlacer = itemsTemp.where((item) => item.estPretAPlacer).toList();
        List<ItemDeSelectionTransfert> enveloppesSeulement = itemsTemp.where((item) => !item.estPretAPlacer).toList();

        itemsPretAPlacer.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        enveloppesSeulement.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

        _tousLesItemsSelectionnables = [...itemsPretAPlacer, ...enveloppesSeulement];
      } else {
        _tousLesItemsSelectionnables = [];
      }
      print("[EcranVirerArgent - _chargerDonneesInitiales] _tousLesItemsSelectionnables APRÈS tri (${_tousLesItemsSelectionnables.length} items): ${_tousLesItemsSelectionnables.map((i) => '{Nom: ${i.nom}, PAP: ${i.estPretAPlacer}, Solde: ${i.solde}, ID: ${i.id}}').toList()}");

      _mettreAJourSelectionsInitiales();

    } catch (e, s) {
      print("[EcranVirerArgent - _chargerDonneesInitiales] ERREUR GLOBALE pendant le chargement: $e\nStackTrace: $s");
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur de chargement des données : ${e.toString()}";
        });
      }
    }
    print("[EcranVirerArgent - _chargerDonneesInitiales] Fin du chargement des données réelles. Nombre final d'items sélectionnables: ${_tousLesItemsSelectionnables.length}");
  }

  void _mettreAJourSelectionsInitiales() {
    print("[EcranVirerArgent - _mettreAJourSelectionsInitiales] Début.");
    if (_tousLesItemsSelectionnables.isNotEmpty) {
      _selectionSource = _tousLesItemsSelectionnables.firstWhere(
            (item) => item.id == ServiceTransfertArgent.idPretAPlacer,
        orElse: () => _tousLesItemsSelectionnables.first,
      );
      print(
          "[EcranVirerArgent - _mettreAJourSelectionsInitiales] Sélection source initiale: ${_selectionSource
              ?.nom}");

      if (_tousLesItemsSelectionnables.length > 1) {
        _selectionDestination = _tousLesItemsSelectionnables
            .where((item) => item.id != ServiceTransfertArgent.idPretAPlacer)
            .firstOrNull; // Prend la première enveloppe non "Prêt à placer"
        if (_selectionDestination == null &&
            _selectionSource?.id != _tousLesItemsSelectionnables.last.id) {
          // Fallback si "Prêt à placer" est le seul ou si on veut éviter de sélectionner la même source et dest
          _selectionDestination = _tousLesItemsSelectionnables.last;
        }
      } else {
        _selectionDestination =
        null; // Pas de destination si "Prêt à placer" est le seul item
      }
      print(
          "[EcranVirerArgent - _mettreAJourSelectionsInitiales] Sélection destination initiale: ${_selectionDestination
              ?.nom}");
    } else {
      _selectionSource = null;
      _selectionDestination = null;
      print(
          "[EcranVirerArgent - _mettreAJourSelectionsInitiales] Aucun item sélectionnable, sélections mises à null.");
    }
    _valeurClavier = "0";
    _montantController.text = _valeurClavier;
    _montantATransferer = 0.0;
    print("[EcranVirerArgent - _mettreAJourSelectionsInitiales] Fin.");
  }

  // --- Logique du clavier et du transfert (simplifiée pour se concentrer sur le chargement) ---
  void _onClavierNumeroAppuye(String valeur) {
    setState(() {
      if (_valeurClavier == "0") {
        _valeurClavier = valeur;
      } else {
        _valeurClavier += valeur;
      }
      _montantController.text = _valeurClavier;
      _montantATransferer = double.tryParse(_valeurClavier);
    });
  }

  void _onClavierEffacerAppuye() {
    setState(() {
      _valeurClavier = "0";
      _montantController.text = _valeurClavier;
      _montantATransferer = 0.0;
    });
  }

  void _effectuerLeTransfert() async {
    if (_selectionSource == null || _selectionDestination == null ||
        _montantATransferer == null || _montantATransferer! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            "Veuillez sélectionner une source, une destination et un montant valide.")),
      );
      return;
    }
    if (_selectionSource!.id == _selectionDestination!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            "La source et la destination ne peuvent pas être identiques.")),
      );
      return;
    }

    // Logique de vérification du solde (simplifiée)
    if (!_selectionSource!.estPretAPlacer &&
        _selectionSource!.solde < _montantATransferer!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            "Solde insuffisant dans l'enveloppe source: ${_selectionSource!
                .nom}")),
      );
      return;
    }
    if (_selectionSource!.estPretAPlacer &&
        _soldePretAPlacerActuel < _montantATransferer!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solde 'Prêt à placer' insuffisant.")),
      );
      return;
    }


    setState(() {
      _isLoading = true;
    }); // Afficher le chargement pendant le transfert

    try {
      print(
          "[EcranVirerArgent - _effectuerLeTransfert] Tentative de transfert de $_montantATransferer de ${_selectionSource!
              .nom} vers ${_selectionDestination!.nom}");
      await _serviceTransfert.transfererArgent(
        utilisateurId: _currentUser!.uid,
        sourceId: _selectionSource!.id,
        destinationId: _selectionDestination!.id,
        montant: _montantATransferer!,
        mapEnveloppes: _mapEnveloppesChargees,
        mapEnveloppeIdACategorieId: _mapEnveloppeIdACategorieId,
        sourceEstPretAPlacer: _selectionSource!.estPretAPlacer,
        destinationEstPretAPlacer: _selectionDestination!.estPretAPlacer,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transfert effectué avec succès !")),
      );
      // Recharger les données pour refléter les changements
      await _chargerDonneesInitialesAvecAffichage();
    } catch (e) {
      print(
          "[EcranVirerArgent - _effectuerLeTransfert] ERREUR lors du transfert: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du transfert: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    print(
        "[EcranVirerArgent - build] Construction du widget. isLoading: $_isLoading, errorMessage: $_errorMessage");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virer de l\'Argent'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _tousLesItemsSelectionnables.isEmpty && _currentUser != null
          ? Center( // Cas où tout est chargé mais il n'y a pas d'enveloppes (sauf peut-être "Prêt à placer" seul)
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _tousLesItemsSelectionnables.any((item) =>
            item.estPretAPlacer && _tousLesItemsSelectionnables.length == 1)
                ? "Veuillez créer des enveloppes pour pouvoir effectuer des virements."
                : "Aucune enveloppe ou source de fonds disponible. Veuillez vérifier votre configuration ou créer des enveloppes.",
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Column( // Affichage principal si tout va bien
        children: [
          // --- Section des Dropdowns ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Dropdown Source
                DropdownButtonFormField<ItemDeSelectionTransfert>(
                  decoration: const InputDecoration(labelText: 'De (Source)'),
                  value: _selectionSource,
                  items: _tousLesItemsSelectionnables.map((item) {
                    return DropdownMenuItem<ItemDeSelectionTransfert>(
                      value: item,
                      child: Text(
                          '${item.nom} (${item.solde.toStringAsFixed(2)} €)'),
                    );
                  }).toList(),
                  onChanged: (ItemDeSelectionTransfert? newValue) {
                    setState(() {
                      _selectionSource = newValue;
                    });
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 10),
                // Dropdown Destination
                DropdownButtonFormField<ItemDeSelectionTransfert>(
                  decoration: const InputDecoration(
                      labelText: 'Vers (Destination)'),
                  value: _selectionDestination,
                  items: _tousLesItemsSelectionnables.map((item) {
                    return DropdownMenuItem<ItemDeSelectionTransfert>(
                      value: item,
                      child: Text(
                          '${item.nom} (${item.solde.toStringAsFixed(2)} €)'),
                    );
                  }).toList(),
                  onChanged: (ItemDeSelectionTransfert? newValue) {
                    setState(() {
                      _selectionDestination = newValue;
                    });
                  },
                  isExpanded: true,
                ),
              ],
            ),
          ),

          // --- Section du Montant Affiché ---
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _montantController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Montant à transférer',
                suffixText: '€',
              ),
            ),
          ),
          Expanded(child: Container()),
          // Espace pour pousser le clavier vers le bas

          // --- Section du Clavier Numérique ---
          _buildClavierNumerique(),

          // --- Bouton de Transfert ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Hauteur minimale
              ),
              onPressed: _effectuerLeTransfert,
              child: const Text('Effectuer le Virement'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClavierNumerique() {
    // Adapter cette partie à votre design de clavier numérique existant
    // Ceci est un exemple très basique
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      // Ajuster pour la taille des boutons
      padding: const EdgeInsets.all(8.0),
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      children: [
        ...['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'].map((val) {
          return ElevatedButton(
            onPressed: () => _onClavierNumeroAppuye(val),
            child: Text(val, style: const TextStyle(fontSize: 18)),
          );
        }),
        ElevatedButton(
          onPressed: _onClavierEffacerAppuye,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Icon(Icons
              .backspace_outlined), //Text('Effacer', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }
}

// Assurez-vous que ServiceTransfertArgent.idPretAPlacer est bien défini
// exemple: static const String idPretAPlacer = "##PRET_A_PLACER##"; dans ServiceTransfertArgent