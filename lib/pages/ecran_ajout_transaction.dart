// lib/pages/ecran_ajout_transaction.dart
import 'package:flutter/material.dart';

enum TypeTransaction { depense, revenu }

class EcranAjoutTransaction extends StatefulWidget {
  const EcranAjoutTransaction({super.key});

  @override
  State<EcranAjoutTransaction> createState() => _EcranAjoutTransactionState();
}

class _EcranAjoutTransactionState extends State<EcranAjoutTransaction> {
  TypeTransaction _typeSelectionne = TypeTransaction.depense;
  final TextEditingController _montantController = TextEditingController(text: '0.00');
  final FocusNode _montantFocusNode = FocusNode();

  // Variables d'état pour les champs de détails
  final TextEditingController _payeController = TextEditingController();
  String? _enveloppeSelectionnee;
  String? _compteSelectionne;
  DateTime _dateSelectionnee = DateTime.now();
  String? _marqueurSelectionne; // Sera utilisé dans la section options additionnelles
  final TextEditingController _noteController = TextEditingController(); // Sera utilisé dans la section options additionnelles

  // Données factices pour les Dropdowns (à remplacer par vos vraies données plus tard)
  // TODO: Remplacer par vos données réelles (ex: depuis Firebase)
  final List<String> _listeEnveloppes = ['Nourriture', 'Transport', 'Loisirs', 'Factures'];
  final List<String> _listeComptes = ['Compte Courant', 'Épargne', 'Carte de Crédit'];
  final List<String> _listeMarqueurs = ['Aucun', 'Important', 'À vérifier'];


  @override
  void initState() {
    super.initState();
    _montantController.addListener(() {
      final text = _montantController.text;
      // La logique de préfixe automatique du signe a été commentée pour éviter les problèmes de curseur.
      // La couleur du champ montant indique déjà le type.
    });

    _montantFocusNode.addListener(() {
      if (_montantFocusNode.hasFocus) {
        // La sélection du texte "0.00" est gérée dans onTap du TextField
      }
    });
  }

  @override
  void dispose() {
    _montantController.dispose();
    _montantFocusNode.dispose();
    _payeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildSelecteurTypeTransaction() {
    // Le style du container du sélecteur pourrait aussi venir du thème si vous avez beaucoup de sélecteurs similaires.
    // Pour l'instant, c'est un style local.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color selectorBackgroundColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final Color selectedOptionColor = isDark ? Colors.black54 : Colors.blueGrey[700]!; // Ajustez pour thème clair
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

  Widget _buildOptionType(TypeTransaction type, String libelle, Color selectedBackgroundColor, Color selectedTextColor, Color unselectedTextColor) {
    final estSelectionne = _typeSelectionne == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeSelectionne = type;
            String valeurActuelle = _montantController.text.replaceAll('-', '');
            if (valeurActuelle.isEmpty || double.tryParse(valeurActuelle) == 0.0) {
              _montantController.text = '0.00';
            }
            // Pas de préfixe automatique du signe
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

  Widget _buildChampMontant() {
    // La couleur du texte est gérée par le thème ou explicitement pour le contraste
    final Color couleurMontant = _typeSelectionne == TypeTransaction.depense
        ? (Theme.of(context).colorScheme.error) // Utilise la couleur d'erreur du thème pour les dépenses
        : Colors.greenAccent; // Ou une couleur spécifique pour les revenus

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
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false), // signed: false car on gère visuellement
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey[600]) // Le thème devrait le gérer, mais on peut forcer
        ),
        onTap: () {
          if (_montantController.text == '0.00') {
            _montantController.selection = TextSelection(baseOffset: 0, extentOffset: _montantController.text.length);
          }
        },
      ),
    );
  }

  Widget _buildSectionInformationsCles() {
    final cardColor = Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white);
    final cardShape = Theme.of(context).cardTheme.shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    );

    return Card(
        color: cardColor,
        shape: cardShape,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0), // Padding vertical réduit
    child: Column(
    children: <Widget>[
    _buildChampDetail(
    icone: Icons.swap_horiz,
    libelle: 'Provenance', // Ce libellé n'est pas affiché par _buildChampDetail pour l'instant
    widgetContenu: TextField(
    controller: _payeController,
    decoration: InputDecoration(
    hintText: 'Provenance',
    border: InputBorder.none, // Pour un look épuré dans la carte
    isDense: true, // Réduit la hauteur du champ
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0)
    ),
    ),
    ),
    _buildSeparateurDansCarte(),
    _buildChampDetail(
    icone: Icons.wallet_outlined,
    libelle: 'Enveloppe',
    widgetContenu: _buildDropdown(_listeEnveloppes, _enveloppeSelectionnee, (val) {
    setState(() => _enveloppeSelectionnee = val);
    }, 'Choisir une enveloppe'),
    ),
    _buildSeparateurDansCarte(),
    _buildChampDetail(
    icone: Icons.account_balance_outlined,
    libelle: 'Compte',
    widgetContenu: _buildDropdown(_listeComptes, _compteSelectionne, (val) {
    setState(() => _compteSelectionne = val);
    }, 'Choisir un compte'),
    ),
    _buildSeparateurDansCarte(),
    _buildChampDetailInteraction(
    icone: Icons.calendar_today_outlined,
    libelle: 'Date',
    valeur: "${_dateSelectionnee.year}-${_dateSelectionnee.month.toString().padLeft(2, '0')}-${_dateSelectionnee.day.toString().padLeft(2, '0')}", // Format AAAA-MM-JJ
      onTap: () async {
        final DateTime? dateChoisie = await showDatePicker(
          context: context,
          initialDate: _dateSelectionnee,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          // Vous pouvez utiliser builder pour styler le DatePicker
          // builder: (context, child) {
          //   return Theme(
          //     data: Theme.of(context).copyWith(
          //       colorScheme: Theme.of(context).colorScheme.copyWith(
          //         primary: Theme.of(context).colorScheme.primary, // Couleur primaire pour la sélection
          //         onPrimary: Colors.white, // Texte sur la couleur primaire
          //       ),
          //       // ... autres personnalisations du thème du DatePicker
          //     ),
          //     child: child!,
          //   );
          // },
        );
        if (dateChoisie != null && dateChoisie != _dateSelectionnee) {
          setState(() {
            _dateSelectionnee = dateChoisie;
          });
        }
      },
    ),
    ],
    ),
        ),
    );
  }

  // TODO: Implémenter _buildSectionOptionsAdditionnelles() ici
  Widget _buildSectionOptionsAdditionnelles() {
    // Structure similaire à _buildSectionInformationsCles
    // Avec les champs "Marqueur" et "Note"
    final cardColor = Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white);
    final cardShape = Theme.of(context).cardTheme.shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    );

    return Card(
        color: cardColor,
        shape: cardShape,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0),
            child: Column(
                children: [
                  // Placeholder pour le contenu de la section
                  _buildChampDetailInteraction(
                      icone: Icons.flag_outlined,
                      libelle: 'Marqueur',
                      valeur: _marqueurSelectionne ?? _listeMarqueurs.first, // Affiche 'Aucun' ou la valeur sélectionnée
                      onTap: () {
                        // Logique pour choisir un marqueur (peut-être un autre Dropdown ou une modale)
                        // Pour l'instant, on va simuler un cycle simple via setState
                        // Ou mieux, utiliser un Dropdown comme pour Enveloppe/Compte
                        print('Choisir un marqueur...');
                      }
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
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0)
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3, // Permet plusieurs lignes pour la note
                        minLines: 1,
                      )
                  )
                ]
            )
        )
    );
    // return const Text('Section Options Additionnelles à venir...', style: TextStyle(fontStyle: FontStyle.italic));
  }


  Widget _buildChampDetail({required IconData icone, required String libelle, required Widget widgetContenu}) {
    // Le libellé est actuellement utilisé dans hintText des champs ou dans _buildChampDetailInteraction.
    // Si vous voulez un libellé visible au-dessus du champ, vous pouvez le décommenter ici.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Padding vertical réduit pour compacter
      child: Row(
        children: <Widget>[
          Icon(icone, color: Colors.grey[500], size: 22), // Icône un peu plus petite
          const SizedBox(width: 16),
          Expanded(
            child: widgetContenu, // Le widgetContenu (TextField, Dropdown) gère son propre hintText/label
          ),
        ],
      ),
    );
  }

  Widget _buildChampDetailInteraction({
    required IconData icone,
    required String libelle,
    required String valeur,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0), // Padding vertical un peu plus grand
        child: Row(
          children: <Widget>[
            Icon(icone, color: Colors.grey[500], size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(libelle, style: Theme.of(context).textTheme.bodyMedium)),
            Text(valeur, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? currentValue,
      ValueChanged<String?> onChanged, String hintText) {
    // Le contentPadding pour le champ fermé (hint/valeur sélectionnée)
    const EdgeInsets internalContentPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0); // Valeur de référence

    return DropdownButtonFormField<String>(
      value: currentValue,
      items: items.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Padding( // AJOUTÉ : Padding pour chaque item dans le menu déroulant
            padding: EdgeInsets.symmetric(horizontal: internalContentPadding.left), // Utilise la même valeur horizontale
            child: Text(val, style: Theme.of(context).textTheme.bodyMedium),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        isDense: true,
        contentPadding: internalContentPadding, // Applique le padding de référence
      ),
      isExpanded: true,
      // Optionnel: Définir la couleur du fond du menu déroulant si ce n'est pas géré par le thème
      // dropdownColor: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white),
    );
  }

  Widget _buildSeparateurDansCarte() {
    return Divider(
      height: 1,
      thickness: 1,
      color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300]),
      indent: 38, // Pour aligner après l'icône
    );
  }


  @override
  Widget build(BuildContext context) {
    // Le thème global de main.dart devrait gérer le fond, etc.
    // final Color fondEcran = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      // backgroundColor: fondEcran, // Géré par le thème
      appBar: AppBar(
        // backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Géré par le thème
        // elevation: Theme.of(context).appBarTheme.elevation, // Géré par le thème
        leading: IconButton(
          icon: const Icon(Icons.close /*, color: Theme.of(context).appBarTheme.iconTheme?.color*/), // Géré par le thème
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Ajouter une Transaction'/*, style: Theme.of(context).appBarTheme.titleTextStyle*/), // Géré par le thème
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
          Center(child: _buildSelecteurTypeTransaction()),
      _buildChampMontant(),

      _buildSectionInformationsCles(),
      const SizedBox(height: 16),
      _buildSectionOptionsAdditionnelles(), // Placeholder pour l'instant

      const SizedBox(height: 30),
      ],
    ),
    ),
    bottomNavigationBar: Padding(
    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + MediaQuery.of(context).padding.bottom), // Ajoute le padding du bas de l'écran (pour notch, etc.)
    child: ElevatedButton.icon(
    icon: const Icon(Icons.check), // La couleur vient du foregroundColor du thème du bouton
    label: const Text(
    'Enregistrer',
    // Le style du texte vient du thème du bouton, sauf si surchargé ici
    // style: TextStyle(fontSize: 18), // Exemple de surcharge de taille
    ),
    onPressed: () {
    // TODO: Logique d'enregistrement complète
    print('Type: $_typeSelectionne');
    print('Montant: ${_montantController.text}');
    print('Payé: ${_payeController.text}');
    print('Enveloppe: $_enveloppeSelectionnee');
    print('Compte: $_compteSelectionne');
    print('Date: $_dateSelectionnee');
    print('Marqueur: $_marqueurSelectionne');
    print('Note: ${_noteController.text}');

    // Validation des champs importants
    if (_montantController.text.isEmpty || double.tryParse(_montantController.text.replaceAll(',', '.')) == 0.0) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Veuillez entrer un montant valide.'))
    );
    return;
    }
    if (_payeController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Veuillez indiquer la provenance.'))
    );
    return;
    }
    // ... autres validations (enveloppe, compte peuvent être optionnels ou non selon votre logique)

    // Si tout est valide, sauvegarder et fermer
    // Navigator.of(context).pop(); // Exemple de fermeture après sauvegarde
    },
    // Le style du bouton vient du elevatedButtonTheme global
    // Vous pouvez toujours surcharger ici si ce bouton doit être différent:
    // style: ElevatedButton.styleFrom(
    //   backgroundColor: Theme.of(context).colorScheme.primary,
    //   padding: const EdgeInsets.symmetric(vertical: 16.0),
    //   textStyle: const TextStyle(fontSize: 18),
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(30.0),
    //   ),
    // ),
    ),
    ),
    );
  }
}