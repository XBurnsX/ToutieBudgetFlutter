import 'package:flutter/material.dart';
import '../models/transaction_model.dart'; // Assurez-vous que ce chemin est correct

// (Si vous utilisez un Provider ou autre pour les comptes, importez-le ici)
// import 'package:provider/provider.dart';
// import '../providers/compte_provider.dart'; // Exemple

class EcranAjoutTransaction extends StatefulWidget {
  // OPTION 1: Passer les comptes via le constructeur
  final List<String> comptesExistants; // Liste des noms de comptes réels

  const EcranAjoutTransaction({
    super.key,
    required this.comptesExistants, // Requis si vous utilisez l'option 1
  });

  // OPTION 2: Si vous n'utilisez pas l'option 1 (par ex. avec Provider)
  // const EcranAjoutTransaction({super.key});

  @override
  State<EcranAjoutTransaction> createState() => _EcranAjoutTransactionState();
}

class _EcranAjoutTransactionState extends State<EcranAjoutTransaction> {
  // --- Variables d'état ---
  TypeTransaction _typeSelectionne = TypeTransaction.depense;
  final TextEditingController _montantController = TextEditingController(text: '0.00');
  final FocusNode _montantFocusNode = FocusNode();

  final TextEditingController _payeController = TextEditingController();
  // final List<String> _payesConnus = []; // Gardez si vous avez une logique d'autocomplétion pour les tiers

  String? _enveloppeSelectionnee; // Sera utilisé plus tard
  String? _compteSelectionne;    // Le compte choisi dans le dropdown pour les transactions normales
  DateTime _dateSelectionnee = DateTime.now();
  String? _marqueurSelectionne;
  final TextEditingController _noteController = TextEditingController();
  TypeMouvementFinancier _typeMouvementSelectionne = TypeMouvementFinancier.depenseNormale;

  // Liste des comptes pour le Dropdown "Compte" (sera initialisée)
  late List<String> _listeComptesAffichables;

  // Listes pour les autres dropdowns (si elles sont toujours statiques ici)
  final List<String> _listeEnveloppes = ['Nourriture', 'Transport', 'Loisirs', 'Factures']; // À remplacer par une gestion dynamique plus tard
  final List<String> _listeMarqueurs = ['Aucun', 'Important', 'À vérifier'];

  @override
  void initState() {
    super.initState();
    print("--- ECRAN INIT STATE ---");

    // --- Initialisation de _listeComptesAffichables ---
    // OPTION 1: Si les comptes sont passés via le constructeur
    _listeComptesAffichables = List<String>.from(widget.comptesExistants)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // OPTION 2: Si vous utilisez un Provider (à faire dans didChangeDependencies ou avec Consumer)
    // (Voir exemple précédent pour didChangeDependencies)
    // Si la liste des comptes est vide initialement et chargée plus tard,
    // assurez-vous que le Dropdown gère correctement un état de chargement ou une liste vide.

    _montantController.addListener(() {});
    _montantFocusNode.addListener(() {
      if (_montantFocusNode.hasFocus && _montantController.text == '0.00') {
        _montantController.selection = TextSelection(baseOffset: 0, extentOffset: _montantController.text.length);
      }
    });
  }

  // (Si vous utilisez Provider et voulez récupérer les comptes dans didChangeDependencies)
  /*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // OPTION 2 - Exemple avec Provider:
    // final compteProvider = Provider.of<CompteProvider>(context, listen: false); // listen: false si seulement à l'init
    // _listeComptesAffichables = compteProvider.nomsDesComptesReels
    //   ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    // print("Comptes chargés depuis Provider: $_listeComptesAffichables");
  }
  */

  @override
  void dispose() {
    print("--- ECRAN DISPOSE ---");
    _montantController.dispose();
    _montantFocusNode.dispose();
    _payeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- Fonction _libellePourTypeMouvement (INCHANGÉE PAR RAPPORT À VOTRE VERSION PRÉCÉDENTE) ---
  String _libellePourTypeMouvement(TypeMouvementFinancier type) {
    switch (type) {
      case TypeMouvementFinancier.depenseNormale: return 'Dépense';
      case TypeMouvementFinancier.revenuNormal: return 'Revenu';
      case TypeMouvementFinancier.pretAccorde: return 'Prêt accordé (Sortie)';
      case TypeMouvementFinancier.remboursementRecu: return 'Remboursement reçu (Entrée)';
      case TypeMouvementFinancier.detteContractee: return 'Dette contractée (Entrée)';
      case TypeMouvementFinancier.remboursementEffectue: return 'Remboursement effectué (Sortie)';
    // Ajoutez d'autres cas si nécessaire, en vous assurant qu'ils existent dans l'enum
      default:
      // Pour être sûr, retournez le nom de l'enum si non mappé, ou un texte d'erreur
        print("AVERTISSEMENT: Libellé non trouvé pour TypeMouvementFinancier.$type");
        return type.name; // Retourne le nom de l'enum (ex: 'investissement')
    }
  }

  // --- NOUVELLE FONCTION _definirNomCompteDette ---
  // (Placée ici, avant les méthodes _build... ou avant onPressed du bouton Sauvegarder)
  Future<String?> _definirNomCompteDette(String nomPreteurInitial, double montantInitialTransaction) async {
    String nomCompteDette = "Prêt Personnel";
    String nomPreteur = nomPreteurInitial.trim();

    if (nomPreteur.isNotEmpty) {
      nomCompteDette += " : $nomPreteur";
    } else {
      if (!mounted) return null; // Vérification pour les opérations asynchrones
      final bool? continuerSansNom = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Nom du prêteur non spécifié'),
            content: const Text(
                'Aucun nom de prêteur n\'a été spécifié. '
                    'Voulez-vous nommer le compte de dette "Prêt Personnel Générique" ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: const Text('Utiliser "Prêt Personnel Générique"'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        },
      );

      if (continuerSansNom == true) {
        nomCompteDette = "Prêt Personnel Générique";
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opération de dette annulée : nom du prêteur requis ou générique refusé.')),
          );
        }
        return null;
      }
    }
    print('Nom du compte de dette déterminé : $nomCompteDette');
    return nomCompteDette;
  }

  // --- Méthodes _build... ---
  // _buildSelecteurTypeTransaction() - (INCHANGÉE PAR RAPPORT À VOTRE VERSION PRÉCÉDENTE)
  Widget _buildSelecteurTypeTransaction() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color selectorBackgroundColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final Color selectedOptionColor = isDark ? Colors.black54 : Colors.blueGrey[700]!;
    final Color unselectedTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color selectedTextColor = Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: selectorBackgroundColor,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildOptionType(TypeTransaction.depense, '- Dépense', selectedOptionColor, selectedTextColor, unselectedTextColor),
          _buildOptionType(TypeTransaction.revenu, '+ Revenu', selectedOptionColor, selectedTextColor, unselectedTextColor),
        ],
      ),
    );
  }

  // _buildOptionType() - (INCHANGÉE, ASSUREZ-VOUS D'UTILISER .estDepense/.estRevenu)
  Widget _buildOptionType(TypeTransaction type, String libelle, Color selectedBackgroundColor, Color selectedTextColor, Color unselectedTextColor) {
    final estSelectionne = _typeSelectionne == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeSelectionne = type;
            if (type == TypeTransaction.depense) {
              if (!_typeMouvementSelectionne.estDepense) {
                _typeMouvementSelectionne = TypeMouvementFinancier.depenseNormale;
              }
            } else { // TypeTransaction.revenu
              if (!_typeMouvementSelectionne.estRevenu) {
                _typeMouvementSelectionne = TypeMouvementFinancier.revenuNormal;
              }
            }
            print("Sélecteur D/R changé: _typeSelectionne: $_typeSelectionne, _typeMouvementSelectionne: $_typeMouvementSelectionne");
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: estSelectionne ? selectedBackgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: estSelectionne ? selectedTextColor : unselectedTextColor,
              fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // _buildChampMontant() - (INCHANGÉE PAR RAPPORT À VOTRE VERSION PRÉCÉDENTE)
  Widget _buildChampMontant() {
    final Color couleurMontant = _typeSelectionne == TypeTransaction.depense
        ? (Theme.of(context).colorScheme.error)
        : Colors.greenAccent[700] ?? Colors.green;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      child: TextField(
        controller: _montantController,
        focusNode: _montantFocusNode,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: couleurMontant),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey[600])),
        onTap: () {
          if (_montantController.text == '0.00') {
            _montantController.selection = TextSelection(baseOffset: 0, extentOffset: _montantController.text.length);
          }
        },
      ),
    );
  }

  // _buildSectionInformationsCles() - (MODIFIÉE pour le Dropdown des comptes et le onChanged du Type Mouvement)
  Widget _buildSectionInformationsCles() {
    final cardColor = Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.white);
    final cardShape = Theme.of(context).cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0));

    return Card(
      color: cardColor,
      shape: cardShape,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: <Widget>[
            // --- CHAMP TYPE MOUVEMENT (onChanged simplifié) ---
            _buildChampDetail(
              icone: Icons.compare_arrows,
              libelle: 'Type Mouvement',
              widgetContenu: DropdownButtonFormField<TypeMouvementFinancier>(
                value: _typeMouvementSelectionne,
                items: TypeMouvementFinancier.values.map((TypeMouvementFinancier type) {
                  return DropdownMenuItem<TypeMouvementFinancier>(
                    value: type,
                    child: Text(_libellePourTypeMouvement(type), style: Theme.of(context).textTheme.bodyMedium),
                  );
                }).toList(),
                onChanged: (TypeMouvementFinancier? newValue) { // CHANGEMENT ICI
                  if (newValue != null) {
                    setState(() {
                      _typeMouvementSelectionne = newValue;
                      if (newValue.estDepense) {
                        _typeSelectionne = TypeTransaction.depense;
                      } else if (newValue.estRevenu) {
                        _typeSelectionne = TypeTransaction.revenu;
                      }
                      if (newValue != TypeMouvementFinancier.detteContractee && _compteSelectionne != null && _compteSelectionne!.startsWith("Prêt Personnel")) {
                      }
                      print("Dropdown Type Mouvement changé: $_typeMouvementSelectionne, _typeSelectionne: $_typeSelectionne");
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Type de mouvement',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                isExpanded: true,
              ),
            ),
            _buildSeparateurDansCarte(),

            // --- CHAMP TIERS / PRÊTEUR (Anciennement "Payé à / Reçu de") ---
            _buildChampDetail(
              icone: Icons.person_outline, // ou Icons.handshake_outlined pour prêteur
              libelle: _typeMouvementSelectionne == TypeMouvementFinancier.detteContractee ? 'Prêteur (Optionnel)' : 'Tiers',
              widgetContenu: TextField(
                controller: _payeController,
                decoration: InputDecoration(
                  hintText: _typeMouvementSelectionne == TypeMouvementFinancier.detteContractee ? 'Nom du prêteur' : 'Payé à / Reçu de',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                // Vous pouvez ajouter ici une logique d'autocomplétion si vous le souhaitez
              ),
            ),
            _buildSeparateurDansCarte(),

            // --- CHAMP COMPTE (Doit TOUJOURS être visible) ---
            // IL NE DOIT PLUS Y AVOIR DE "if (_typeMouvementSelectionne != TypeMouvementFinancier.detteContractee)" ICI
            _buildChampDetail(
              icone: Icons.account_balance_wallet_outlined,
              // Le libellé peut changer dynamiquement
              libelle: _typeMouvementSelectionne == TypeMouvementFinancier.detteContractee
                  ? 'Vers Compte Actif' // Libellé spécifique pour les dettes
                  : 'Compte',        // Libellé normal
              widgetContenu: DropdownButtonFormField<String>(
                value: _compteSelectionne,
                items: _listeComptesAffichables.map((String compte) { // Assurez-vous que _listeComptesAffichables contient vos comptes d'actifs
                  return DropdownMenuItem<String>(
                    value: compte,
                    child: Text(compte, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _compteSelectionne = newValue;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Sélectionner un compte', // Texte d'aide si rien n'est sélectionné
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                isExpanded: true,
              ),
            ),
            _buildSeparateurDansCarte(),

            // ... (Vos autres champs: Date, Enveloppe, Marqueur, Note - INCHANGÉS)
            // Exemple pour Date:
            _buildChampDetail(
              icone: Icons.calendar_today_outlined,
              libelle: 'Date',
              widgetContenu: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _dateSelectionnee,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _dateSelectionnee) {
                    setState(() {
                      _dateSelectionnee = picked;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                  child: Text(
                    "${_dateSelectionnee.toLocal()}".split(' ')[0], // Format YYYY-MM-DD
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            _buildSeparateurDansCarte(),

            _buildChampDetail(
              icone: Icons.label_outline,
              libelle: 'Enveloppe',
              widgetContenu: DropdownButtonFormField<String>(
                value: _enveloppeSelectionnee,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("Aucune", style: TextStyle(fontStyle: FontStyle.italic))),
                  ..._listeEnveloppes.map((String enveloppe) {
                    return DropdownMenuItem<String>(value: enveloppe, child: Text(enveloppe));
                  })
                ],
                onChanged: (String? newValue) => setState(() => _enveloppeSelectionnee = newValue),
                decoration: InputDecoration(hintText: 'Optionnel', border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)),
                isExpanded: true,
              ),
            ),
            _buildSeparateurDansCarte(),

            _buildChampDetail(
              icone: Icons.flag_outlined,
              libelle: 'Marqueur',
              widgetContenu: DropdownButtonFormField<String>(
                value: _marqueurSelectionne ?? _listeMarqueurs.first, // Assurer une valeur par défaut non nulle
                items: _listeMarqueurs.map((String marqueur) {
                  return DropdownMenuItem<String>(value: marqueur, child: Text(marqueur));
                }).toList(),
                onChanged: (String? newValue) => setState(() => _marqueurSelectionne = newValue),
                decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)),
                isExpanded: true,
              ),
            ),
            _buildSeparateurDansCarte(),

            _buildChampDetail(
              icone: Icons.notes_outlined,
              libelle: 'Note',
              widgetContenu: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Optionnel',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null, // Permet plusieurs lignes
              ),
              alignementVerticalIcone: CrossAxisAlignment.start,
            ),
          ],
        ),
      ),
    );
  }

  // _buildChampDetail() - (Peut-être ajouter un paramètre pour l'alignement de l'icône si besoin)
  Widget _buildChampDetail({
    required IconData icone,
    required String libelle,
    required Widget widgetContenu,
    CrossAxisAlignment alignementVerticalIcone = CrossAxisAlignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: alignementVerticalIcone,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 2.0), // Léger ajustement pour l'icône
            child: Icon(icone, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          Expanded(
            flex: 2, // Donne plus de place au libellé si nécessaire
            child: Text(libelle, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 3, // Donne plus de place au contenu
            child: Align(
              alignment: Alignment.centerRight,
              child: widgetContenu,
            ),
          ),
        ],
      ),
    );
  }

  // _buildSeparateurDansCarte() - (INCHANGÉE)
  Widget _buildSeparateurDansCarte() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.3));
  }

  // --- Méthode build() avec le bouton Sauvegarder MODIFIÉ ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter Transaction'),
        // actions: [IconButton(icon: Icon(Icons.save), onPressed: _sauvegarderTransaction)], // Si vous aviez un bouton save ici
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSelecteurTypeTransaction(),
            _buildChampMontant(),
            _buildSectionInformationsCles(),
            const SizedBox(height: 30),

            // --- BOUTON SAUVEGARDER (LOGIQUE MODIFIÉE) ---
            ElevatedButton(
              onPressed: () async {
                final double montant = double.tryParse(_montantController.text.replaceAll(',', '.')) ?? 0.0;
                final String tiersTexte = _payeController.text.trim(); // Nom du prêteur pour une dette

                if (montant <= 0) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un montant valide.')));
                  return;
                }

                // Le compte sélectionné dans le dropdown est TOUJOURS le compte d'actif.
                if (_compteSelectionne == null || _compteSelectionne!.isEmpty) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner le compte de destination.')));
                  return;
                }
                String compteActifCible = _compteSelectionne!;
                String? nomCompteDePassifPourCetteTransaction; // Sera rempli si c'est une dette

                if (_typeMouvementSelectionne == TypeMouvementFinancier.detteContractee) {
                  // S'assurer qu'un prêteur est spécifié, même si c'est pour un compte générique
                  if (tiersTexte.isEmpty) {
                    // Optionnel: Afficher un dialogue pour forcer le nom du prêteur ou générique
                    // Pour l'instant, on va juste le demander via le hintText du champ prêteur.
                    // Mais si tiersTexte est vide, _definirNomCompteDette va déjà demander
                    // s'il faut utiliser "Prêt Personnel Générique".
                  }

                  if (!mounted) return;
                  String? nomCompteDetteDefini = await _definirNomCompteDette(tiersTexte, montant);

                  if (nomCompteDetteDefini == null) {
                    print("Sauvegarde annulée car la définition du nom du compte de dette a échoué.");
                    return;
                  }
                  nomCompteDePassifPourCetteTransaction = nomCompteDetteDefini;

                  // --- PERSISTANCE DU COMPTE DE DETTE LUI-MÊME (si nouveau) ---
                  // Cette logique crée le "Compte de Passif" dans votre système de comptes.
                  // Exemple:
                  // bool comptePassifExisteDeja = await votreServiceComptes.existe(nomCompteDePassifPourCetteTransaction);
                  // if (!comptePassifExisteDeja) {
                  //    await votreServiceComptes.creerCompte(nom: nomCompteDePassifPourCetteTransaction, type: "Dette", soldeInitial: montant);
                  //    print('COMPTE DE PASSIF "$nomCompteDePassifPourCetteTransaction" CRÉÉ EN BD.');
                  //    // Optionnel: Mettre à jour _nomsDesComptesActuels si vous mélangez les types dans un seul dropdown,
                  //    // mais ici _listeComptesAffichables ne devrait contenir que les comptes d'actifs.
                  // } else {
                  //    // Si le compte de dette existe déjà, vous pourriez vouloir mettre à jour son solde (ajouter le nouveau montant de dette)
                  //    // await votreServiceComptes.mettreAJourSolde(nomCompteDePassifPourCetteTransaction, montant);
                  //    print('COMPTE DE PASSIF "$nomCompteDePassifPourCetteTransaction" EXISTE DÉJÀ. Solde potentiellement mis à jour.');
                  // }
                  print('>>> PERSISTANCE (simulation) du COMPTE DE PASSIF : "$nomCompteDePassifPourCetteTransaction" <<<');

                }
                // Pas de 'else' ici pour compteActifCible, car il est déjà défini à partir de _compteSelectionne

                // --- CRÉATION ET SAUVEGARDE DE LA TRANSACTION ---
                final String transactionId = DateTime.now().millisecondsSinceEpoch.toString();
                final nouvelleTransaction = Transaction(
                  id: transactionId,
                  type: _typeSelectionne, // Sera .revenu pour detteContractee
                  typeMouvement: _typeMouvementSelectionne,
                  montant: montant,
                  tiers: tiersTexte, // Nom du prêteur si dette, sinon tiers normal
                  compteId: compteActifCible, // COMPTE D'ACTIF où l'argent est déposé
                  compteDePassifAssocie: nomCompteDePassifPourCetteTransaction, // Nom du compte de dette si applicable
                  date: _dateSelectionnee,
                  enveloppeId: _enveloppeSelectionnee,
                  marqueur: _marqueurSelectionne,
                  note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                );

                print('>>> Transaction à sauvegarder: ${nouvelleTransaction.toJson()}');
                print('Compte ACTIF cible pour la transaction: $compteActifCible');
                if (nomCompteDePassifPourCetteTransaction != null) {
                  print('Compte de PASSIF associé: $nomCompteDePassifPourCetteTransaction');
                }

                // --- VRAIE PERSISTANCE DE LA TRANSACTION ---
                // await votreServiceTransactions.sauvegarder(nouvelleTransaction);
                print('>>> PERSISTANCE (simulation) de la TRANSACTION <<<');

                // --- MISE À JOUR DU SOLDE DU COMPTE ACTIF CIBLE ---
                // Le solde du compte d'actif (ex: Compte Courant) augmente car on a reçu de l'argent (le prêt).
                // await votreServiceComptes.mettreAJourSolde(
                //   compteActifCible,
                //   montant // Toujours positif car c'est un revenu sur le compte d'actif
                // );
                print('>>> MISE À JOUR SOLDE (simulation) pour COMPTE ACTIF "$compteActifCible" de +$montant <<<');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Transaction sauvegardée pour "$compteActifCible".')),
                  );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, true);
                  }
                }
              },
              // ... style ...
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }
}