// lib/screens/ecran_virer_argent.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/enveloppe_model.dart';
import '../../services/service_transfert_argent.dart';

// Classe helper pour les items dans les Dropdowns
class ItemDeSelectionTransfert {
  final String id;
  final String nom;
  double solde;
  final bool estPretAPlacer;
  final Color? couleurAffichage;

  ItemDeSelectionTransfert({
    required this.id,
    required this.nom,
    required this.solde,
    this.estPretAPlacer = false,
    this.couleurAffichage,
  });

  @override
  String toString() => nom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ItemDeSelectionTransfert &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class EcranVirerArgent extends StatefulWidget {
  const EcranVirerArgent({Key? key}) : super(key: key);

  @override
  State<EcranVirerArgent> createState() => _EcranVirerArgentState();
}

class _EcranVirerArgentState extends State<EcranVirerArgent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final ServiceTransfertArgent _serviceTransfert;
  User? _currentUser;

  String _valeurSaisie = "0";
  final currencyFormatter =
  NumberFormat.currency(locale: 'fr_CA', symbol: '\$');

  List<ItemDeSelectionTransfert> _tousLesItemsSelectionnables = [];
  Map<String, EnveloppeModel> _mapEnveloppesChargees = {};
  Map<String, String> _mapEnveloppeIdACategorieId = {};

  ItemDeSelectionTransfert? _sourceSelectionnee;
  ItemDeSelectionTransfert? _destinationSelectionnee;

  bool _isLoading = true;
  String? _errorMessage;
  double _soldePretAPlacerActuel = 0.0;
  Color? _couleurComptePrincipalPourPAP;

  final TextEditingController _montantController =
  TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _serviceTransfert = ServiceTransfertArgent(_firestore);
    _currentUser = _auth.currentUser;

    if (_currentUser != null) {
      _chargerDonneesInitialesAvecAffichage();
    } else {
      _handleUserNotLoggedIn();
    }
    _montantController.addListener(() {
      // Synchroniser _valeurSaisie avec _montantController si modifié de l'extérieur (peu probable ici)
      // La principale mise à jour se fait via _onValeurSaisieChange qui met à jour le controller.
      // Cette vérification évite une boucle si on saisit directement dans un TextField (pas le cas ici avec le numpad custom)
      if (_montantController.text.replaceAll(',', '.') != _valeurSaisie) {
        _onValeurSaisieChange(_montantController.text);
      }
    });
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  void _handleUserNotLoggedIn() {
    setState(() {
      _isLoading = false;
      _errorMessage = "Utilisateur non connecté.";
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text("Veuillez vous connecter pour effectuer un virement.")),
        );
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _chargerDonneesInitialesAvecAffichage() async {
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
  }

  Future<void> _chargerDonneesInitiales() async {
    if (_currentUser == null) return;

    try {
      final userDoc =
      await _firestore.collection('users').doc(_currentUser!.uid).get();
      _soldePretAPlacerActuel =
          (userDoc.data()?['soldePretAPlacerGlobal'] as num? ?? 0.0)
              .toDouble();

      _couleurComptePrincipalPourPAP =
          Theme
              .of(context)
              .colorScheme
              .secondary; // Couleur par défaut

      List<ItemDeSelectionTransfert> itemsTemp = [];
      _mapEnveloppesChargees.clear();
      _mapEnveloppeIdACategorieId.clear();

      itemsTemp.add(ItemDeSelectionTransfert(
        id: ServiceTransfertArgent.idPretAPlacer,
        nom: 'Prêt à placer',
        solde: _soldePretAPlacerActuel,
        estPretAPlacer: true,
        couleurAffichage: _couleurComptePrincipalPourPAP,
      ));

      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('categories')
          .orderBy('nom')
          .get();

      for (var catDoc in categoriesSnapshot.docs) {
        final enveloppesSnapshot = await catDoc.reference
            .collection('enveloppes')
            .orderBy('ordre')
            .get();

        for (var envDoc in enveloppesSnapshot.docs) {
          try {
            EnveloppeModel env = EnveloppeModel.fromSnapshot(
                envDoc as DocumentSnapshot<Map<String, dynamic>>);
            _mapEnveloppesChargees[env.id] = env;
            _mapEnveloppeIdACategorieId[env.id] = catDoc.id;

            itemsTemp.add(ItemDeSelectionTransfert(
              id: env.id,
              nom: env.nom,
              solde: env.montantAlloueActuellement,
              estPretAPlacer: false,
              couleurAffichage: null, // Ou une couleur basée sur la catégorie/enveloppe
            ));
          } catch (e) {
            print(
                "Erreur de parsing pour l'enveloppe ${envDoc
                    .id} dans catégorie ${catDoc.id}: $e");
          }
        }
      }

      if (itemsTemp.length > 1) {
        List<ItemDeSelectionTransfert> enveloppesTriables =
        itemsTemp.sublist(1);
        enveloppesTriables
            .sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        _tousLesItemsSelectionnables = [itemsTemp.first] + enveloppesTriables;
      } else {
        _tousLesItemsSelectionnables = itemsTemp;
      }

      if (!mounted) return;

      // Logique de sélection initiale simplifiée pour source et destination
      if (_tousLesItemsSelectionnables.isNotEmpty) {
        final idSourcePrecedente = _sourceSelectionnee?.id;
        _sourceSelectionnee = _tousLesItemsSelectionnables.firstWhere(
              (item) =>
          item.id ==
              (idSourcePrecedente ?? ServiceTransfertArgent.idPretAPlacer),
          orElse: () =>
              _tousLesItemsSelectionnables.firstWhere(
                    (i) => i.estPretAPlacer,
                orElse: () => _tousLesItemsSelectionnables.first,
              ),
        );

        final idDestinationPrecedente = _destinationSelectionnee?.id;
        List<ItemDeSelectionTransfert> optionsDestinationPossibles =
        _tousLesItemsSelectionnables
            .where((item) => item.id != _sourceSelectionnee!.id)
            .toList();

        if (optionsDestinationPossibles.isNotEmpty) {
          try {
            _destinationSelectionnee = optionsDestinationPossibles.firstWhere(
                  (item) => item.id == idDestinationPrecedente,
            );
          } catch (e) {
            _destinationSelectionnee = optionsDestinationPossibles.first;
          }
        } else {
          _destinationSelectionnee = null;
        }
      } else {
        _sourceSelectionnee = null;
        _destinationSelectionnee = null;
      }
    } catch (e, s) {
      print("Erreur lors du chargement des données initiales: $e\n$s");
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur de chargement: ${e.toString()}";
        });
      }
    }
  }

  void _onValeurSaisieChange(String nouvelleValeur) {
    String valeurNettoyee = nouvelleValeur.replaceAll(',', '.');
    if (valeurNettoyee.indexOf('.') != valeurNettoyee.lastIndexOf('.')) {
      valeurNettoyee = _valeurSaisie.replaceAll(
          ',', '.'); // Revenir à la dernière valeur valide
    }

    if (valeurNettoyee.contains('.')) {
      final parts = valeurNettoyee.split('.');
      if (parts.length > 1 && parts[1].length > 2) {
        parts[1] = parts[1].substring(0, 2);
        valeurNettoyee = parts.join('.');
      }
    }

    // Gérer le cas où la valeur nettoyée est juste "."
    if (valeurNettoyee == ".") {
      valeurNettoyee = "0.";
    }
    // Gérer le cas où la valeur est vide après nettoyage (ex: après avoir effacé "0.")
    if (valeurNettoyee.isEmpty) {
      valeurNettoyee = "0";
    }


    setState(() {
      _valeurSaisie = valeurNettoyee;
      if (_montantController.text != _valeurSaisie) {
        // Formatter pour le cas où _valeurSaisie est "0." mais on veut "0." dans le controller
        String textPourController = _valeurSaisie;
        _montantController.text = textPourController;
        _montantController.selection = TextSelection.fromPosition(
            TextPosition(offset: _montantController.text.length));
      }
    });
  }

  void _ajouterChiffre(String chiffre) {
    String valeurActuelle = _valeurSaisie.replaceAll(',', '.');
    String nouvelleValeur;

    if (chiffre == ".") {
      if (valeurActuelle.contains(".")) return; // Déjà un point
      nouvelleValeur = valeurActuelle.isEmpty ? "0." : valeurActuelle + ".";
    } else {
      if (valeurActuelle == "0") {
        nouvelleValeur = chiffre;
      } else {
        nouvelleValeur = valeurActuelle + chiffre;
      }
    }
    _onValeurSaisieChange(nouvelleValeur);
  }

  void _effacerDernierChiffre() {
    String valeurActuelle = _valeurSaisie.replaceAll(',', '.');
    if (valeurActuelle.isNotEmpty) {
      String nouvelleValeur =
      valeurActuelle.substring(0, valeurActuelle.length - 1);
      if (nouvelleValeur.isEmpty || nouvelleValeur == "-") {
        nouvelleValeur = "0";
      }
      _onValeurSaisieChange(nouvelleValeur);
    }
  }

  String _formatCurrencyDisplayForInput(String value) {
    final doubleValue = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    // Pour l'affichage principal, on formate toujours.
    // Pour le _montantController, on garde la valeur brute pour la saisie.
    return currencyFormatter.format(doubleValue);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _effectuerVirement() async {
    final double? montant = double.tryParse(_valeurSaisie.replaceAll(',', '.'));

    if (_currentUser == null) {
      _showErrorSnackBar('Utilisateur non identifié.');
      return;
    }
    if (_sourceSelectionnee == null || _destinationSelectionnee == null) {
      _showErrorSnackBar('Veuillez sélectionner la source et la destination.');
      return;
    }
    if (montant == null || montant <= 0) {
      _showErrorSnackBar('Veuillez saisir un montant valide.');
      return;
    }
    // La vérification source != destination est implicitement gérée par la logique des dropdowns
    // mais une double vérification ici est sans danger.
    if (_sourceSelectionnee!.id == _destinationSelectionnee!.id) {
      _showErrorSnackBar(
          'La source et la destination doivent être différentes.');
      return;
    }

    // Vérification des soldes (déjà partiellement faite mais bon de revérifier)
    if (_sourceSelectionnee!.estPretAPlacer) {
      if (_soldePretAPlacerActuel < montant) {
        _showErrorSnackBar('Le montant dépasse le solde "Prêt à placer".');
        return;
      }
    } else {
      EnveloppeModel? envSource =
      _mapEnveloppesChargees[_sourceSelectionnee!.id];
      if (envSource == null || envSource.montantAlloueActuellement < montant) {
        _showErrorSnackBar(
            'Le montant dépasse le solde de l\'enveloppe source "${_sourceSelectionnee!
                .nom}".');
        return;
      }
    }

    setState(() {
      _isLoading = true; // Pour l'indicateur sur le bouton de virement
      _errorMessage = null;
    });

    EnveloppeModel? enveloppeSourceDetails;
    String? categorieIdSource;
    if (!_sourceSelectionnee!.estPretAPlacer) {
      enveloppeSourceDetails = _mapEnveloppesChargees[_sourceSelectionnee!.id];
      categorieIdSource = _mapEnveloppeIdACategorieId[_sourceSelectionnee!.id];
      if (enveloppeSourceDetails == null || categorieIdSource == null) {
        _showErrorSnackBar("Détails de l'enveloppe source introuvables.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    EnveloppeModel? enveloppeDestinationDetails;
    String? categorieIdDestination;
    if (!_destinationSelectionnee!.estPretAPlacer) {
      enveloppeDestinationDetails =
      _mapEnveloppesChargees[_destinationSelectionnee!.id];
      categorieIdDestination =
      _mapEnveloppeIdACategorieId[_destinationSelectionnee!.id];
      if (enveloppeDestinationDetails == null ||
          categorieIdDestination == null) {
        _showErrorSnackBar(
            "Détails de l'enveloppe destination introuvables.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    try {
      final nouveauSoldePAPCalculeOuNull =
      await _serviceTransfert.effectuerVirement(
        userId: _currentUser!.uid,
        montant: montant,
        sourceId: _sourceSelectionnee!.id,
        enveloppeSourceDetails: enveloppeSourceDetails,
        destinationId: _destinationSelectionnee!.id,
        enveloppeDestinationDetails: enveloppeDestinationDetails,
        soldePretAPlacerActuel: _soldePretAPlacerActuel,
        idCategorieSource: categorieIdSource,
        idCategorieDestination: categorieIdDestination,
      );

      // Le rechargement des données va mettre à jour tous les soldes, y compris PAP.
      // Si le service retournait le nouveau solde PAP, on pourrait l'utiliser pour un update local plus rapide
      // mais _chargerDonneesInitiales() est plus complet.
      // if (nouveauSoldePAPCalculeOuNull != null && mounted) {
      //   setState(() {
      //     _soldePretAPlacerActuel = nouveauSoldePAPCalculeOuNull;
      //   });
      // }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Virement de ${_formatCurrencyDisplayForInput(
                      montant.toString())} effectué avec succès!'),
              backgroundColor: Colors.green),
        );
        setState(() {
          _valeurSaisie = "0";
          _montantController.text = "0"; // Réinitialiser après succès
        });
      }
      await _chargerDonneesInitialesAvecAffichage(); // Recharger pour mettre à jour tous les soldes
    } on TransfertException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e, s) {
      print("Erreur inattendue lors du virement: $e\n$s");
      _showErrorSnackBar('Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Fin du chargement du virement
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isCurrentlyInitialLoading = _isLoading && _tousLesItemsSelectionnables.isEmpty;
    bool hasErrorOnInitialLoad =
        _errorMessage != null && _tousLesItemsSelectionnables.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Virer de l\'argent')),
      body: isCurrentlyInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : hasErrorOnInitialLoad
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
        ),
      )
          : Column( // Column principale
        children: [
          // 1. Espace flexible au-dessus du montant pour le centrer verticalement
          Expanded( // Ce Expanded prend l'espace en haut
            child: Center( // Ce Center centre son enfant dans l'Expanded
              child: Padding( // Padding global pour le bloc du montant
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align( // Aligne son enfant (le Text avec son padding) à droite
                  alignment: Alignment.centerRight,
                  child: Padding( // Padding spécifique pour décaler le texte du bord droit
                    padding: const EdgeInsets.only(right: 16.0), // <-- Ajustez ce padding pour l'espacement droit
                    child: Text(
                      _formatCurrencyDisplayForInput(_valeurSaisie),
                      style: theme.textTheme.displayMedium?.copyWith( // <-- Ajustez 'displayMedium' pour la taille
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Dropdowns de sélection (juste au-dessus du Numpad)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important pour que cette Column ne prenne pas trop de hauteur
              children: [
                _buildDropdown(
                  label: 'De:',
                  selectedValue: _sourceSelectionnee,
                  items: _tousLesItemsSelectionnables,
                  onChanged: (ItemDeSelectionTransfert? newValue) {
                    if (newValue != null && !_isLoading) {
                      setState(() {
                        final nouvelleSource = newValue;
                        _sourceSelectionnee = nouvelleSource;

                        if (_destinationSelectionnee == null || _destinationSelectionnee!.id == nouvelleSource.id) {
                          try {
                            _destinationSelectionnee = _tousLesItemsSelectionnables.firstWhere(
                                  (item) => item.id != nouvelleSource.id,
                            );
                          } catch (e) {
                            _destinationSelectionnee = null;
                          }
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildDropdown(
                  label: 'À:',
                  selectedValue: _destinationSelectionnee,
                  items: _tousLesItemsSelectionnables
                      .where((item) => item.id != _sourceSelectionnee?.id)
                      .toList(),
                  onChanged: (ItemDeSelectionTransfert? newValue) {
                    if (newValue != null && !_isLoading) {
                      setState(() {
                        _destinationSelectionnee = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Espace entre les dropdowns et le Numpad

          // 3. Numpad (ne prend plus d'Expanded ici car il est en bas)
          _buildNumpad(), // Le Numpad est maintenant un enfant direct

          // 4. Bouton "Effectuer le virement" en bas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: (isCurrentlyInitialLoading || (_isLoading && !isCurrentlyInitialLoading) ||
                  _sourceSelectionnee == null ||
                  _destinationSelectionnee == null)
                  ? null
                  : _effectuerVirement,
              child: (_isLoading && !isCurrentlyInitialLoading)
                  ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ))
                  : const Text('Effectuer le virement'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required ItemDeSelectionTransfert? selectedValue,
    required List<ItemDeSelectionTransfert> items,
    required ValueChanged<ItemDeSelectionTransfert?> onChanged,
  }) {
    final theme = Theme.of(context);
    bool dropdownDisabled = _isLoading && _tousLesItemsSelectionnables
        .isEmpty; // Désactiver pendant le chargement initial

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ItemDeSelectionTransfert>(
          isExpanded: true,
          value: selectedValue,
          // Doit être null si non trouvable dans items, ou un des items
          items: items.map((item) {
            return DropdownMenuItem<ItemDeSelectionTransfert>(
              value: item,
              child: Row(
                children: [
                  if (item.couleurAffichage != null)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: item.couleurAffichage, shape: BoxShape.circle),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                  Expanded(
                      child: Text(item.nom, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormatter.format(item.solde),
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: dropdownDisabled ? null : onChanged,
          // Utiliser la variable dropdownDisabled
          hint: Text(items.isEmpty && !dropdownDisabled
              ? "Aucune option"
              : "Sélectionner..."),
          disabledHint: selectedValue != null
              ? Text(selectedValue.nom, style: TextStyle(color: Theme
              .of(context)
              .disabledColor))
              : (items.isEmpty
              ? const Text("Chargement...")
              : null), // Message pendant chargement initial
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final buttons = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '<'
    ];
    // Désactiver le numpad pendant le chargement initial
    bool numpadDisabled = _isLoading && _tousLesItemsSelectionnables.isEmpty;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.9,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final buttonText = buttons[index];
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme
                .of(context)
                .colorScheme
                .onSurface,
            textStyle: Theme
                .of(context)
                .textTheme
                .headlineSmall,
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: numpadDisabled ? null : () { // Utiliser numpadDisabled
            if (buttonText == '<') {
              _effacerDernierChiffre();
            } else {
              _ajouterChiffre(buttonText);
            }
          },
          child: Text(buttonText),
        );
      },
    );
  }
}