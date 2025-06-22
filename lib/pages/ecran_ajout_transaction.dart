// lib/pages/ecran_ajout_transaction.dart
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Décommentez pour la persistance

enum TypeTransaction { depense, revenu }

class EcranAjoutTransaction extends StatefulWidget {
  const EcranAjoutTransaction({super.key});

  @override
  State<EcranAjoutTransaction> createState() => _EcranAjoutTransactionState();
}

class _EcranAjoutTransactionState extends State<EcranAjoutTransaction> {
  TypeTransaction _typeSelectionne = TypeTransaction.depense;
  final TextEditingController _montantController = TextEditingController(
      text: '0.00');
  final FocusNode _montantFocusNode = FocusNode();

  final TextEditingController _payeController = TextEditingController();
  final List<String> _payesConnus = [
    'Epicerie Max',
    'Pharmacie Jean Coutu',
    'Shell',
    'Salaire Inc.',
    'Loyer'
  ]; // Exemple étendu
  // FocusNode pour le champ Autocomplete lui-même, géré par Autocomplete
  // final FocusNode _autocompleteFocusNode = FocusNode(); // Pas besoin de le définir ici si on utilise celui de fieldViewBuilder

  String? _enveloppeSelectionnee;
  String? _compteSelectionne;
  DateTime _dateSelectionnee = DateTime.now();
  String? _marqueurSelectionne;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _listeEnveloppes = [
    'Nourriture',
    'Transport',
    'Loisirs',
    'Factures'
  ];
  final List<String> _listeComptes = [
    'Compte Courant',
    'Épargne',
    'Carte de Crédit'
  ];
  final List<String> _listeMarqueurs = ['Aucun', 'Important', 'À vérifier'];

  @override
  void initState() {
    super.initState();
    print("--- ECRAN INIT STATE ---");
    // _loadPayesConnus();

    _montantController.addListener(() {});
    _montantFocusNode.addListener(() {
      if (_montantFocusNode.hasFocus && _montantController.text == '0.00') {
        _montantController.selection = TextSelection(
            baseOffset: 0, extentOffset: _montantController.text.length);
      }
    });
  }

  /*
  Future<void> _loadPayesConnus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _payesConnus.clear();
      _payesConnus.addAll(prefs.getStringList('payesConnus') ?? ['Epicerie Max', 'Pharmacie Jean Coutu', 'Shell']);
      if (_payesConnus.isEmpty) {
        _payesConnus.addAll(['Epicerie Max', 'Pharmacie Jean Coutu', 'Shell']);
      }
    });
    print("Payés connus chargés: $_payesConnus");
  }

  Future<void> _savePayesConnus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('payesConnus', _payesConnus);
    print("Payés connus sauvegardés: $_payesConnus");
  }
  */

  @override
  void dispose() {
    print("--- ECRAN DISPOSE ---");
    _montantController.dispose();
    _montantFocusNode.dispose();
    _payeController.dispose();
    _noteController.dispose();
    // _autocompleteFocusNode.dispose(); // Si vous l'aviez créé explicitement
    super.dispose();
  }

  Widget _buildSelecteurTypeTransaction() {
    final bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color selectorBackgroundColor = isDark ? Colors.grey[800]! : Colors
        .grey[300]!;
    final Color selectedOptionColor = isDark ? Colors.black54 : Colors
        .blueGrey[700]!;
    final Color unselectedTextColor = isDark ? Colors.grey[400]! : Colors
        .grey[600]!;
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
          _buildOptionType(
              TypeTransaction.depense, '- Dépense', selectedOptionColor,
              selectedTextColor, unselectedTextColor),
          _buildOptionType(
              TypeTransaction.revenu, '+ Revenu', selectedOptionColor,
              selectedTextColor, unselectedTextColor),
        ],
      ),
    );
  }

  Widget _buildOptionType(TypeTransaction type, String libelle,
      Color selectedBackgroundColor, Color selectedTextColor,
      Color unselectedTextColor) {
    final estSelectionne = _typeSelectionne == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeSelectionne = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: estSelectionne ? selectedBackgroundColor : Colors
                .transparent,
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

  Widget _buildChampMontant() {
    final Color couleurMontant = _typeSelectionne == TypeTransaction.depense
        ? (Theme
        .of(context)
        .colorScheme
        .error)
        : Colors.greenAccent[700] ?? Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      child: TextField(
        controller: _montantController,
        focusNode: _montantFocusNode,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: couleurMontant,
        ),
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true, signed: false),
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey[600])),
        onTap: () {
          if (_montantController.text == '0.00') {
            _montantController.selection = TextSelection(
                baseOffset: 0, extentOffset: _montantController.text.length);
          }
        },
      ),
    );
  }

  Widget _buildSectionInformationsCles() {
    final cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? (Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.grey[850]! : Colors.white);
    final cardShape = Theme
        .of(context)
        .cardTheme
        .shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    );
    print(
        "--- _buildSectionInformationsCles RECONSTRUIT --- _payeController.text: ${_payeController
            .text}");

    return Card(
      color: cardColor,
      shape: cardShape,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: <Widget>[
            _buildChampDetail(
              icone: Icons.swap_horiz,
              libelle: 'Provenance',
              widgetContenu: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  print('>>> Autocomplete: optionsBuilder appelé avec texte: "${textEditingValue.text}"');
                  final String query = textEditingValue.text;

                  if (query.isEmpty) {
                    print('>>> Autocomplete: optionsBuilder - Texte vide, retourne TOUS les _payesConnus: $_payesConnus');
                    return _payesConnus;
                  }

                  final suggestions = _payesConnus.where((String option) {
                    return option.toLowerCase().contains(query.toLowerCase());
                  }).toList(); // Convertir en liste ici

                  print('>>> Autocomplete: optionsBuilder - Suggestions filtrées trouvées: ${suggestions.toList()} pour "$query"');

                  // SI AUCUNE SUGGESTION TROUVÉE ET QUE LE CHAMP N'EST PAS VIDE,
                  // ON VEUT QUAND MÊME AFFICHER L'OPTION "AJOUTER..."
                  if (suggestions.isEmpty && query.isNotEmpty) {
                    print('>>> Autocomplete: optionsBuilder - Aucune suggestion pour "$query", mais query non vide. Retourne une liste avec la query elle-même pour forcer optionsViewBuilder.');
                    // Retourner une liste contenant la query actuelle (ou une valeur sentinelle)
                    // pour que Autocomplete appelle optionsViewBuilder.
                    // Cette valeur sera ignorée ou gérée dans optionsViewBuilder si besoin,
                    // car notre logique "Ajouter..." se base sur _payeController.text.
                    return <String>[query]; // Ou une chaîne spéciale comme "_ADD_NEW_" si vous préférez la filtrer explicitement
                  }

                  return suggestions;
                },
                onSelected: (String selection) {
                  print(
                      '>>> Autocomplete: onSelected appelé avec: "$selection"');
                  setState(() { // setState pour reconstruire si _payeController change affecte autre chose
                    _payeController.text = selection;
                  });
                  print(
                      '>>> Autocomplete: onSelected - _payeController.text mis à jour à: "${_payeController
                          .text}"');
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldTextEditingController,
                    // Contrôleur interne d'Autocomplete
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  print(
                      ">>> Autocomplete: fieldViewBuilder construit. fieldTextEditingController.text: '${fieldTextEditingController
                          .text}', fieldFocusNode.hasFocus: ${fieldFocusNode
                          .hasFocus}");

                  // Synchronisation initiale si _payeController a une valeur (ex: chargement d'une transaction)
                  // WidgetsBinding.instance.addPostFrameCallback((_) {
                  //   if (_payeController.text.isNotEmpty && fieldTextEditingController.text != _payeController.text) {
                  //      print(">>> fieldViewBuilder postFrameCallback: Synchronisation de fieldTextEditingController avec _payeController.text: ${_payeController.text}");
                  //     fieldTextEditingController.text = _payeController.text;
                  //   }
                  // });

                  fieldFocusNode.addListener(() {
                    print(
                        ">>> Autocomplete fieldFocusNode Listener: hasFocus: ${fieldFocusNode
                            .hasFocus}, fieldTextEditingController.text: '${fieldTextEditingController
                            .text}'");
                    if (fieldFocusNode.hasFocus &&
                        fieldTextEditingController.text.isEmpty) {
                      // On s'attend à ce que Autocomplete appelle optionsBuilder et ouvre la liste
                      // car optionsBuilder retourne maintenant _payesConnus.
                      print(
                          ">>> Autocomplete fieldFocusNode Listener: A LE FOCUS & TEXTE VIDE. optionsBuilder devrait être appelé.");
                    }
                  });

                  return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Payé à / Reçu de',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 10.0),
                      ),
                      onTap: () {
                        print(
                            ">>> Autocomplete fieldViewBuilder TextField TAPPED! fieldTextEditingController.text: '${fieldTextEditingController
                                .text}'");
                        // Si le texte est vide au tap, on veut que la liste s'ouvre.
                        // Autocomplete devrait le faire si optionsBuilder retourne des options.
                      },
                      onChanged: (text) {
                        print(
                            '>>> Autocomplete fieldViewBuilder onChanged: text = "$text"');
                        // Mettre à jour _payeController pour que la logique "Ajouter..." ait la valeur actuelle.
                        _payeController.value = TextEditingValue(
                          text: text,
                          selection: TextSelection.collapsed(offset: text
                              .length),
                        );
                        print(
                            '>>> Autocomplete fieldViewBuilder onChanged: _payeController mis à jour à: "${_payeController
                                .text}"');
                      },
                      onSubmitted: (value) {
                        print(
                            '>>> Autocomplete fieldViewBuilder onSubmitted: value = "$value"');
                        onFieldSubmitted(); // Important pour que Autocomplete puisse gérer la soumission
                      }
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<String> onSelectedCallback,
                    Iterable<String> options /* options peut maintenant contenir la query elle-même */) {
                  print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                  print('>>> Autocomplete: optionsViewBuilder APPELÉ !');
                  print('>>> Autocomplete: optionsViewBuilder - options reçues de optionsBuilder: ${options.toList()}');
                  final String currentValue = _payeController.text.trim();
                  print('>>> Autocomplete: optionsViewBuilder - _payeController.text (currentValue): "$currentValue"');

                  // Créer les widgets pour les VRAIES suggestions (celles de _payesConnus)
                  List<Widget> optionWidgets = options
                      .where((option) => _payesConnus.any((known) => known.toLowerCase() == option.toLowerCase()) || option.toLowerCase() == currentValue.toLowerCase()) // Filtrer pour n'afficher que les vraies suggestions ou la query si elle est la seule "option"
                      .map((String option) {
                    // Si l'option est la query elle-même et qu'elle n'est pas une "vraie" suggestion connue,
                    // on ne veut peut-être pas l'afficher comme une suggestion normale si "Ajouter..." va apparaître.
                    // Pour l'instant, laissons-la, elle sera surchargée par "Ajouter..." si elle est identique.
                    return GestureDetector(
                      onTap: () {
                        print('>>> Autocomplete optionsViewBuilder: Option "$option" TAPÉE');
                        onSelectedCallback(option);
                      },
                      child: ListTile(
                        title: Text(option),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
                        dense: true,
                      ),
                    );
                  }).toList();

                  // Si la seule "option" passée était la query elle-même (pour forcer l'ouverture),
                  // et que cette query ne correspond à aucun payé connu, alors optionWidgets ne devrait contenir
                  // que le ListTile pour cette query. On va le remplacer/compléter par "Ajouter..."
                  // Ou, si options était vide (cas du focus sur champ vide), optionWidgets est vide ici.

                  if (options.length == 1 && options.first.toLowerCase() == currentValue.toLowerCase() && !_payesConnus.any((p) => p.toLowerCase() == currentValue.toLowerCase())) {
                    print('>>> Autocomplete: optionsViewBuilder - La seule option est la query elle-même ("$currentValue"), et elle n\'est pas dans _payesConnus. On vide optionWidgets pour prioriser "Ajouter..."');
                    optionWidgets.clear(); // Vider pour que seul "Ajouter..." apparaisse si c'est le cas
                  }


                  print('>>> Autocomplete: optionsViewBuilder - optionWidgets après mapping initial (et filtrage potentiel): ${optionWidgets.length} éléments');

                  // bool alreadyExistsInSuggestions = options.any((opt) => opt.toLowerCase() == currentValue.toLowerCase()); // L'ancienne logique
                  // NOUVELLE logique pour alreadyExists: on vérifie contre _payesConnus directement
                  bool isAlreadyAKnownPayee = _payesConnus.any((p) => p.toLowerCase() == currentValue.toLowerCase());
                  print('>>> Autocomplete: optionsViewBuilder - isAlreadyAKnownPayee (pour "$currentValue" dans _payesConnus): $isAlreadyAKnownPayee');

                  if (currentValue.isNotEmpty && !isAlreadyAKnownPayee) { // <<< CONDITION MODIFIÉE ICI
                    print('>>> Autocomplete: optionsViewBuilder - Condition "Ajouter..." VRAIE pour "$currentValue". Ajout du widget.');
                    // Vérifier si un widget pour "currentValue" existe déjà (par le mapping précédent) et le retirer
                    // pour éviter doublon si "Ajouter currentValue" est plus approprié.
                    // C'est déjà géré par le clear() plus haut si c'était le seul élément.
                    optionWidgets.add(
                        GestureDetector(
                          onTap: () {
                            print('>>> Autocomplete optionsViewBuilder: Option "Ajouter $currentValue" TAPÉE');
                            onSelectedCallback(currentValue);
                          },
                          child: ListTile(
                            title: Text('Ajouter "$currentValue"'),
                            leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
                            dense: true,
                          ),
                        )
                    );
                  } else {
                    print('>>> Autocomplete: optionsViewBuilder - Condition "Ajouter..." FAUSSE pour "$currentValue". isAlreadyAKnownPayee: $isAlreadyAKnownPayee');
                  }
                  print('>>> Autocomplete: optionsViewBuilder - optionWidgets après "Ajouter...": ${optionWidgets.length} éléments');

                  // ... reste du code de optionsViewBuilder (SizedBox.shrink, Align, etc.)
                  if (optionWidgets.isEmpty) {
                    print(">>> Autocomplete: optionsViewBuilder - optionWidgets est VIDE. currentValue: '$currentValue'. Retourne SizedBox.shrink (Cas 1)");
                    return const SizedBox.shrink();
                  }

                  print(">>> Autocomplete: optionsViewBuilder - Va retourner Align avec Material et ListView. Nombre d'options: ${optionWidgets.length}");
                  print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      color: cardColor,
                      shape: cardShape,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          shrinkWrap: true,
                          children: optionWidgets,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildSeparateurDansCarte(),
            _buildChampDetail(
              icone: Icons.wallet_outlined,
              libelle: 'Enveloppe',
              widgetContenu: _buildDropdown(
                  _listeEnveloppes, _enveloppeSelectionnee, (val) {
                setState(() => _enveloppeSelectionnee = val);
              }, 'Choisir une enveloppe'),
            ),
            _buildSeparateurDansCarte(),
            _buildChampDetail(
              icone: Icons.account_balance_outlined,
              libelle: 'Compte',
              widgetContenu: _buildDropdown(
                  _listeComptes, _compteSelectionne, (val) {
                setState(() => _compteSelectionne = val);
              }, 'Choisir un compte'),
            ),
            _buildSeparateurDansCarte(),
            _buildChampDetailInteraction(
              icone: Icons.calendar_today_outlined,
              libelle: 'Date',
              valeur: "${_dateSelectionnee.year}-${_dateSelectionnee.month
                  .toString().padLeft(2, '0')}-${_dateSelectionnee.day
                  .toString().padLeft(2, '0')}",
              onTap: _choisirDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparateurDansCarte() {
    return Divider(height: 0.5, indent: 0, endIndent: 0, color: Theme
        .of(context)
        .dividerColor
        .withOpacity(0.5));
  }

  Widget _buildChampDetail(
      {required IconData icone, required String libelle, required Widget widgetContenu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Icon(icone, color: Theme
              .of(context)
              .iconTheme
              .color
              ?.withOpacity(0.7) ?? Colors.grey[500], size: 22),
          const SizedBox(width: 16),
          Expanded(child: widgetContenu),
        ],
      ),
    );
  }

  Widget _buildChampDetailInteraction(
      {required IconData icone, required String libelle, required String valeur, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: <Widget>[
            Icon(icone, color: Theme
                .of(context)
                .iconTheme
                .color
                ?.withOpacity(0.7) ?? Colors.grey[500], size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(valeur, style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                color: Theme
                    .of(context)
                    .textTheme
                    .bodyLarge
                    ?.color,
              )),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? currentValue,
      ValueChanged<String?> onChanged, String hintText) {
    const EdgeInsets internalContentPadding = EdgeInsets.symmetric(
        vertical: 10.0, horizontal: 10.0);
    return DropdownButtonFormField<String>(
      value: currentValue,
      items: items.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: internalContentPadding.left / 2),
            child: Text(val, style: Theme
                .of(context)
                .textTheme
                .bodyMedium),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        isDense: true,
        contentPadding: internalContentPadding,
      ),
      isExpanded: true,
    );
  }

  Future<void> _choisirDate() async {
    final DateTime? dateChoisie = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (dateChoisie != null && dateChoisie != _dateSelectionnee) {
      setState(() {
        _dateSelectionnee = dateChoisie;
      });
    }
  }

  Widget _buildSectionOptionsAdditionnelles() {
    final cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? (Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.grey[850]! : Colors.white);
    final cardShape = Theme
        .of(context)
        .cardTheme
        .shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    );

    return Card(
        color: cardColor,
        shape: cardShape,
        child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildChampDetail(
                  icone: Icons.flag_outlined,
                  libelle: 'Marqueur',
                  widgetContenu: _buildDropdown(
                    _listeMarqueurs,
                    _marqueurSelectionne,
                        (val) {
                      setState(() => _marqueurSelectionne = val);
                    },
                    'Choisir un marqueur',
                  ),
                ),
                _buildSeparateurDansCarte(),
                _buildChampDetail(
                    icone: Icons.notes_outlined,
                    libelle: 'Note',
                    widgetContenu: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                          hintText: 'Ajouter une note (optionnel)',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 10.0)),
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                    ))
              ],
            ))
    );
  }

  @override
  Widget build(BuildContext context) {
    print("--- ECRAN BUILD RECONSTRUIT ---");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(child: _buildSelecteurTypeTransaction()),
            _buildChampMontant(),
            _buildSectionInformationsCles(),
            const SizedBox(height: 20),
            Text(
              'Options additionnelles',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildSectionOptionsAdditionnelles(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                print('--- BOUTON SAUVEGARDER PRESSÉ ---');
                print('Type: $_typeSelectionne');
                print('Montant: ${_montantController.text}');
                print('Payé/Reçu de: ${_payeController
                    .text}'); // Devrait avoir la valeur sélectionnée ou ajoutée
                print('Enveloppe: $_enveloppeSelectionnee');
                print('Compte: $_compteSelectionne');
                print('Date: $_dateSelectionnee');
                print('Marqueur: $_marqueurSelectionne');
                print('Note: ${_noteController.text}');

                // Logique pour ajouter à _payesConnus si c'est une nouvelle entrée et sélectionnée via "Ajouter..."
                // Cela est géré implicitement par le onSelected qui met à jour _payeController.
                // Si l'utilisateur a tapé "Nouveau Payé" et cliqué sur "Ajouter Nouveau Payé",
                // alors _payeController.text sera "Nouveau Payé".
                // Il faut s'assurer que _payesConnus est réellement mis à jour AVANT la sauvegarde si nécessaire.

                final String finalPayeValue = _payeController.text.trim();
                if (finalPayeValue.isNotEmpty &&
                    !_payesConnus.any((p) =>
                    p.toLowerCase() ==
                        finalPayeValue.toLowerCase())) {
                  print(
                      'Sauvegarde: "$finalPayeValue" est un nouveau payé, ajout à _payesConnus.');
                  setState(() { // setState pour que la liste soit à jour pour la prochaine fois
                    _payesConnus.add(finalPayeValue);
                    // _savePayesConnus(); // Sauvegarder si la persistance est active
                  });
                  print(
                      '_payesConnus après ajout par sauvegarde: $_payesConnus');
                }


                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }
}