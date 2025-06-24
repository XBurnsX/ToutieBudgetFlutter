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

  const EcranVirerArgent({Key? key}) : super(key: key);

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
  Map<String, EnveloppeModel> _mapEnveloppesChargees = {};
  Map<String, String> _mapEnveloppeIdACategorieId = {
  }; // Map<enveloppeId, categorieId>

  ItemDeSelectionTransfert? _selectionSource;
  ItemDeSelectionTransfert? _selectionDestination;
  double? _montantATransferer;
  double _soldePretAPlacerActuel = 0.0;

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
    // La vérification _currentUser peut rester en dehors du try principal
    // si vous voulez une gestion d'erreur différente pour ce cas.
    // Cependant, si _currentUser EST null ici, les lignes suivantes lèveront une erreur
    // car vous utilisez _currentUser!.uid. Il est donc préférable de l'inclure ou de retourner tôt.

    if (_currentUser == null) {
      print("[EcranVirerArgent - _chargerDonneesInitiales] ERREUR: _currentUser est null au début du chargement réel.");
      if (mounted) {
        setState(() {
          _errorMessage = "Utilisateur non authentifié. Impossible de charger les données.";
          // _isLoading devrait aussi être mis à false ici si vous ne le faites pas dans _chargerDonneesInitialesAvecAffichage
        });
      }
      return; // Important de sortir si _currentUser est null
    }

    try { // <--- DÉBUT DU BLOC TRY
      List<ItemDeSelectionTransfert> itemsTemp = [];
      _mapEnveloppesChargees.clear();
      _mapEnveloppeIdACategorieId.clear();

      // 1. Charger tous les comptes bancaires de l'utilisateur
      final comptesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid) // Utilisation de ! donc doit être dans try ou après une vérification non-null
          .collection('comptes_bancaires')
          .get();

      List<CompteBancaireModel> tousLesComptes = comptesSnapshot.docs
          .map((doc) => CompteBancaireModel.fromFirestore(doc))
          .toList();

      // 2. Charger toutes les enveloppes (de toutes les catégories)
      List<EnveloppeModel> toutesLesEnveloppes = [];
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('categories')
          .get();

      for (QueryDocumentSnapshot catDoc in categoriesSnapshot.docs) {
        final enveloppesSnapshot = await catDoc.reference
            .collection('enveloppes')
            .orderBy('nom')
            .get();
        for (QueryDocumentSnapshot<Map<String, dynamic>> envDoc in enveloppesSnapshot.docs) {
          try { // try-catch interne pour le parsing d'une seule enveloppe (bonne pratique)
            EnveloppeModel env = EnveloppeModel.fromSnapshot(envDoc);
            toutesLesEnveloppes.add(env);
            _mapEnveloppesChargees[env.id] = env;
            _mapEnveloppeIdACategorieId[env.id] = catDoc.id;
          } catch (e, s) {
            print("[EcranVirerArgent] ERREUR PARSING ENVELOPPE ID '${envDoc.id}': $e\nStackTrace: $s");
            // Vous pourriez décider de continuer à charger les autres enveloppes
          }
        }
      }

      // 3. Calculer "Prêt à placer" pour chaque compte
      for (CompteBancaireModel compte in tousLesComptes) {
        double totalAlloueAuxEnveloppesPourCeCompte = 0;
        for (EnveloppeModel env in toutesLesEnveloppes) {
          if (env.compteSourceId == compte.id) {
            totalAlloueAuxEnveloppesPourCeCompte += env.montantAlloueActuellement;
          }
        }
        double soldeBrutDuCompte = compte.soldeInitial;
        double soldePretAPlacerDuCompte = soldeBrutDuCompte - totalAlloueAuxEnveloppesPourCeCompte;

        itemsTemp.add(ItemDeSelectionTransfert(
          id: 'comptepap_${compte.id}',
          nom: '${compte.nom} (Prêt à placer)',
          solde: soldePretAPlacerDuCompte < 0 ? 0 : soldePretAPlacerDuCompte,
          estPretAPlacer: true,
        ));
        print("[EcranVirerArgent] 'Prêt à placer' pour compte '${compte.nom}' ajouté. Solde calculé: $soldePretAPlacerDuCompte");
      }

      // 4. Ajouter les enveloppes elles-mêmes
      for (EnveloppeModel env in toutesLesEnveloppes) {
        itemsTemp.add(ItemDeSelectionTransfert(
          id: env.id,
          nom: env.nom,
          solde: env.montantAlloueActuellement,
          estPretAPlacer: false,
        ));
      }

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
      print("[EcranVirerArgent - _chargerDonneesInitiales] Nombre total d'items sélectionnables: ${_tousLesItemsSelectionnables.length}");

      _mettreAJourSelectionsInitiales();

    } catch (e, s) { // <--- LE BLOC CATCH ASSOCIÉ AU TRY CI-DESSUS
      print(
          "[EcranVirerArgent - _chargerDonneesInitiales] ERREUR GLOBALE pendant le chargement: $e\nStackTrace: $s");
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur de chargement des données : ${e.toString()}";
          // _isLoading devrait être false ici aussi pour arrêter l'indicateur
        });
      }
    }
    // Le print de fin peut être ici ou dans un bloc finally si vous en aviez un
    print("[EcranVirerArgent - _chargerDonneesInitiales] Fin du chargement des données réelles.");
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
        }).toList(),
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