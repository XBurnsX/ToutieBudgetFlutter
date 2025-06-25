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
      }


      // 3. Calculer "Prêt à placer" pour chaque compte
      print("[EcranVirerArgent - _chargerDonneesInitiales] Calcul des 'Prêt à placer'...");
      for (CompteBancaireModel compte in tousLesComptes) {
        print("  > Calcul PAP pour compte: ${compte.nom} (ID: ${compte.id}), SoldeInitial: ${compte.soldeInitial}");
        double totalAlloueAuxEnveloppesPourCeCompte = 0;
        for (EnveloppeModel env in toutesLesEnveloppes) {
          if (env.compteSourceAttacheId == compte.id) { // <--- CORRECTED
            totalAlloueAuxEnveloppesPourCeCompte += env.soldeEnveloppe;
            print("    >> Enveloppe '${env.nom}' (Montant: ${env.soldeEnveloppe}, compteSourceId: ${env.compteSourceAttacheId}) est liée au compte ${compte.id}.");
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Virer de l\'Argent')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Virer de l\'Argent')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_currentUser != null &&
        (_tousLesItemsSelectionnables.isEmpty ||
            _tousLesItemsSelectionnables.every((item) =>
            item.estPretAPlacer))) {
      return Scaffold(
        appBar: AppBar(title: const Text('Virer de l\'Argent')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Veuillez créer au moins une enveloppe pour pouvoir effectuer des virements.",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    // Hauteur approximative du clavier et du bouton pour aider au layout si nécessaire
    // Ceci est très approximatif et dépend du childAspectRatio, padding, etc.
    // const double approxClavierHeight = 220; // Ajustez si vous avez une idée plus précise
    // const double approxBoutonVirementHeight = 70; // 55 + padding

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virer de l\'Argent'),
      ),
      body: Padding( // Ajout d'un Padding global pour éviter que les éléments ne collent aux bords de l'écran
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Section du Montant (prend l'espace flexible et centré) ---
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: TextField(
                    controller: _montantController,
                    readOnly: true,
                    textAlign: TextAlign.right,
                    style: TextStyle( // Le style qui augmente la taille et causait l'encadré
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      // 1. Indiquer que le champ doit être rempli
                      filled: true,
                      // 2. Spécifier la couleur de remplissage pour qu'elle corresponde au fond
                      fillColor: theme.scaffoldBackgroundColor, // OU la couleur de fond spécifique si différente
                      // 3. Essayer de minimiser la bordure visible, même si elle sera de la même couleur
                      border: InputBorder.none, // Gardez ceci, au cas où cela réduirait l'épaisseur
                      // Vous pouvez aussi essayer avec une bordure de la même couleur :
                      // border: UnderlineInputBorder( // Ou OutlineInputBorder
                      //  borderSide: BorderSide(color: theme.scaffoldBackgroundColor),
                      // ),

                      // Ajoutez votre hintText et suffixText ici si vous le souhaitez
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      suffixText: '\$',
                      suffixStyle: TextStyle(
                        fontSize: 28,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),



            // --- Section des Sélections (Source/Destination) ---
            // Plus besoin de Card ici si on veut un look plus intégré au-dessus du clavier
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              // Espace avant le clavier
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Depuis", style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ItemDeSelectionTransfert>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                          0.3),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 15.0),
                    ),
                    value: _selectionSource,
                    items: _tousLesItemsSelectionnables.map((item) {
                      return DropdownMenuItem<ItemDeSelectionTransfert>(
                        value: item,
                        child: Text(
                          '${item.nom} (${item.solde.toStringAsFixed(2)} €)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (ItemDeSelectionTransfert? newValue) {
                      setState(() {
                        _selectionSource = newValue;
                      });
                    },
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),
                  // Espace réduit entre les dropdowns
                  Text("Vers", style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ItemDeSelectionTransfert>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                          0.3),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 15.0),
                    ),
                    value: _selectionDestination,
                    items: _tousLesItemsSelectionnables.map((item) {
                      final bool estSourceSelectionnee = _selectionSource !=
                          null && _selectionSource!.id == item.id;
                      return DropdownMenuItem<ItemDeSelectionTransfert>(
                        value: item,
                        enabled: !estSourceSelectionnee,
                        child: Text(
                          '${item.nom} (${item.solde.toStringAsFixed(2)} €)',
                          style: estSourceSelectionnee
                              ? TextStyle(color: theme.disabledColor,
                              fontStyle: FontStyle.italic)
                              : null,
                          overflow: TextOverflow.ellipsis,
                        ),
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

            // --- Section du Clavier Numérique ---
            _buildClavierNumerique(theme),
            // Pas de padding supplémentaire autour ici, géré dans le widget lui-même ou ci-dessous

            // --- Bouton de Transfert ---
            // Le SizedBox donne l'espacement "d'environ 15dp" en dessous du clavier
            // Et le Padding en bas donne l'espacement par rapport au bord de l'écran
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 16.0),
              // top: 15 pour l'espace au-dessus du bouton
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_selectionSource != null &&
                    _selectionDestination != null &&
                    _montantATransferer != null && _montantATransferer! > 0)
                    ? _effectuerLeTransfert
                    : null,
                child: const Text('Effectuer le Virement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

// _buildClavierNumerique reste le même que dans la proposition précédente,
// mais assurez-vous que son padding interne est approprié.
// Par exemple, le GridView.builder avait un padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// Vous pourriez vouloir ajuster cela ou le retirer si le Padding global de la Column externe est suffisant.
// Pour cette nouvelle structure, il est probablement mieux de garder un padding horizontal dans _buildClavierNumerique
// et de ne pas en avoir de vertical, ou un très petit.

  Widget _buildClavierNumerique(ThemeData theme) {
    final List<String> touchesClavier = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', 'effacer'
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.9, // Légèrement ajusté, à tester
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: touchesClavier.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Padding horizontal pour ne pas coller aux bords si le padding global du Scaffold n'est pas là.
      // Puisque le Scaffold > Padding > Column a un padding horizontal de 16,
      // celui-ci n'est peut-être plus nécessaire ou peut être réduit.
      // Je le laisse pour l'instant, vous pouvez l'enlever pour voir l'effet.
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      // Uniquement padding vertical ici
      itemBuilder: (context, index) {
        final touche = touchesClavier[index];

        if (touche == 'effacer') {
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(
                  0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _onClavierEffacerAppuye,
            child: Icon(Icons.backspace_outlined,
                color: theme.colorScheme.onSecondaryContainer, size: 28),
          );
        } else {
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                  0.7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () => _onClavierNumeroAppuye(touche),
            child: Text(
              touche,
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
      },
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