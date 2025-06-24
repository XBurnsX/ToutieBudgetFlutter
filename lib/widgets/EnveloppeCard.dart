import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// IMPORTANT: L'import pour TypeObjectif depuis sa source de vérité
import 'package:toutie_budget/pages/gestion_categories_enveloppes_screen.dart' show TypeObjectif;


// La fonction d'aide est définie ici, au niveau supérieur (en dehors de toute classe)
String typeObjectifToString(TypeObjectif type) {
  switch (type) {
    case TypeObjectif.mensuel:
      return 'mensuel';
    case TypeObjectif.dateFixe:
      return 'dateFixe'; // Assurez-vous que c'est bien la chaîne que vous stockez/lisez
    case TypeObjectif.aucun:
    default:
      return 'aucun';
  }
}


// La fonction de conversion est définie ici, au niveau supérieur
TypeObjectif stringToTypeObjectif(String? value) {
  switch (value?.toLowerCase()) {
    case 'mensuel':
      return TypeObjectif.mensuel;
    case 'datefixe': // Soyez cohérent avec ce qui est dans typeObjectifToString et dans Firestore
      return TypeObjectif.dateFixe;
    case 'aucun':
    default:
      return TypeObjectif.aucun;
  }
}


class EnveloppeUIData {
  final String id;
  final String nom;
  final int? iconeCodePoint;
  final double soldeActuel;
  final double montantAlloue;
  final TypeObjectif typeObjectif; // Doit utiliser le TypeObjectif importé
  final double? montantCible;
  final DateTime? dateCible;
  final int couleurThemeValue;
  final int couleurSoldeCompteValue;
  final int ordre;


  static const int _defaultCouleurThemeValue = 0xFF2196F3;
  static const int _defaultCouleurSoldeCompteValue = 0xFF9E9E9E;


  EnveloppeUIData({
    required this.id,
    required this.nom,
    this.iconeCodePoint,
    required this.soldeActuel,
    required this.montantAlloue,
    required this.typeObjectif, // Assurez-vous que le paramètre est bien TypeObjectif
    this.montantCible,
    this.dateCible,
    this.couleurThemeValue = _defaultCouleurThemeValue,
    required this.couleurSoldeCompteValue,
    this.ordre = 0,
  });


  IconData? get icone =>
      iconeCodePoint != null ? IconData(iconeCodePoint!, fontFamily: 'MaterialIcons') : null;
  Color get couleurTheme => Color(couleurThemeValue);
  Color get couleurSoldeCompte => Color(couleurSoldeCompteValue);


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'iconeCodePoint': iconeCodePoint,
      'soldeActuel': soldeActuel,
      'montantAlloue': montantAlloue,
      'typeObjectif': typeObjectifToString(typeObjectif), // Utilise la fonction globale
      'montantCible': montantCible,
      'dateCible': dateCible != null ? Timestamp.fromDate(dateCible!) : null,
      'couleurThemeValue': couleurThemeValue,
      'couleurSoldeCompteValue': couleurSoldeCompteValue,
      'ordre': ordre,
    };
  }


  factory EnveloppeUIData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;

    // ----> AJOUTEZ CES PRINTS <----
    print('Dans fromFirestore pour doc ID ${doc.id}:');
    print('  Valeur brute de typeObjectif: ${data['typeObjectif']} (Type: ${data['typeObjectif']?.runtimeType})');
    print('  Valeur brute de montantCible: ${data['montantCible']} (Type: ${data['montantCible']?.runtimeType})');

    TypeObjectif objectif = stringToTypeObjectif(data['typeObjectif'] as String?);
    double? cible = (data['montantCible'] as num?)?.toDouble();

    print('  Valeur convertie de typeObjectif: $objectif');
    print('  Valeur convertie de montantCible: $cible');
    // ---- FIN DES PRINTS ----

    return EnveloppeUIData(
      id: doc.id,
      nom: data['nom'] as String? ?? '',
      iconeCodePoint: data['iconeCodePoint'] as int?,
      soldeActuel: (data['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      montantAlloue: (data['montantAlloue'] as num?)?.toDouble() ?? 0.0,
      typeObjectif: objectif, // Utilise la valeur convertie et imprimée
      montantCible: cible,   // Utilise la valeur convertie et imprimée
      dateCible: (data['dateCible'] as Timestamp?)?.toDate(),
      couleurThemeValue: data['couleurThemeValue'] as int? ?? _defaultCouleurThemeValue,
      couleurSoldeCompteValue: data['couleurSoldeCompteValue'] as int? ?? _defaultCouleurSoldeCompteValue,
      ordre: data['ordre'] as int? ?? 0,
    );
  }


  factory EnveloppeUIData.fromMap(Map<String, dynamic> map) {
    return EnveloppeUIData(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nom: map['nom'] as String? ?? '',
      iconeCodePoint: map['iconeCodePoint'] as int?,
      soldeActuel: (map['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      montantAlloue: (map['montantAlloue'] as num?)?.toDouble() ?? 0.0,
      typeObjectif: stringToTypeObjectif(map['typeObjectif'] as String?), // APPEL CORRECT
      montantCible: (map['montantCible'] as num?)?.toDouble(),
      dateCible: (map['dateCible'] as Timestamp?)?.toDate(),
      couleurThemeValue: map['couleurThemeValue'] as int? ?? _defaultCouleurThemeValue,
      couleurSoldeCompteValue: map['couleurSoldeCompteValue'] as int? ?? _defaultCouleurSoldeCompteValue,
      ordre: map['ordre'] as int? ?? 0,
    );
  }
}


class EnveloppeCard extends StatelessWidget {
  final EnveloppeUIData enveloppe;
  final VoidCallback? onTap; // <--- NOUVEAU PARAMÈTRE


  const EnveloppeCard({
    Key? key,
    required this.enveloppe,
    this.onTap, // <--- AJOUTEZ-LE AU CONSTRUCTEUR
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'fr_CA', symbol: '\$');

    // AJOUTEZ CES PRINTS POUR DÉBOGUER
    print('--- EnveloppeCard Debug ---');
    print('Nom: ${enveloppe.nom}');
    print('ID: ${enveloppe.id}');
    print('Type Objectif: ${enveloppe.typeObjectif}'); // Très important
    print('Montant Cible: ${enveloppe.montantCible}');   // Très important
    print('Date Cible: ${enveloppe.dateCible}');       // Très important
    print('Solde Actuel: ${enveloppe.soldeActuel}');     // Important pour la condition principale
    print('Montant Alloué: ${enveloppe.montantAlloue}');
    print('---------------------------');

    Color couleurFondBulleSolde;
    Color couleurTexteBulleSolde;

    if (enveloppe.soldeActuel < 0) {
      couleurFondBulleSolde = Colors.red.shade700;
      couleurTexteBulleSolde = Colors.red.shade700;
    } else if (enveloppe.soldeActuel == 0) {
      couleurFondBulleSolde = Colors.grey.shade400;
      couleurTexteBulleSolde = Colors.grey.shade700;
    } else {
      couleurFondBulleSolde = enveloppe.couleurSoldeCompte;
      couleurTexteBulleSolde = enveloppe.couleurSoldeCompte;
    }

    Color couleurBarreLaterale;
    if (enveloppe.soldeActuel < 0) {
      couleurBarreLaterale = Colors.red.shade700;
    } else if (enveloppe.typeObjectif != TypeObjectif.aucun &&
        enveloppe.montantCible != null &&
        enveloppe.montantCible! > 0) {
      bool estObjectifMensuelAtteint = enveloppe.typeObjectif ==
          TypeObjectif.mensuel &&
          enveloppe.montantAlloue >= enveloppe.montantCible!;
      bool estObjectifDateFixeAtteint = enveloppe.typeObjectif ==
          TypeObjectif.dateFixe &&
          enveloppe.soldeActuel >= enveloppe.montantCible!;
      if (estObjectifMensuelAtteint || estObjectifDateFixeAtteint) {
        couleurBarreLaterale = Colors.green.shade600;
      } else if ((enveloppe.typeObjectif == TypeObjectif.mensuel &&
          enveloppe.montantAlloue > 0) ||
          (enveloppe.typeObjectif == TypeObjectif.dateFixe &&
              enveloppe.soldeActuel > 0) ||
          (enveloppe.montantAlloue > 0)) {
        couleurBarreLaterale = Colors.yellow.shade700;
      } else {
        couleurBarreLaterale = Colors.grey.shade400;
      }
    } else { // TypeObjectif.aucun
      if (enveloppe.montantAlloue > 0 && enveloppe.soldeActuel >= 0) {
        if (enveloppe.soldeActuel < enveloppe.montantAlloue &&
            enveloppe.soldeActuel > 0) {
          couleurBarreLaterale = Colors.yellow.shade700;
        } else if (enveloppe.soldeActuel == enveloppe.montantAlloue) {
          couleurBarreLaterale = Colors.green.shade500;
        } else if (enveloppe.soldeActuel == 0 && enveloppe.montantAlloue > 0) {
          couleurBarreLaterale = Colors.yellow.shade700;
        } else if (enveloppe.soldeActuel > 0) {
          couleurBarreLaterale = Colors.green.shade500;
        }
        else {
          couleurBarreLaterale = Colors.grey.shade400;
        }
      } else if (enveloppe.soldeActuel > 0) {
        couleurBarreLaterale = Colors.green.shade500;
      }
      else {
        couleurBarreLaterale = Colors.grey.shade400;
      }
    }

    double progressionValue = 0;
    String messageObjectifText = '';
    String messageSousBarreText = '';
    bool afficherBarreProgressionPrincipale = false;

    if (enveloppe.soldeActuel >= 0) {
      if (enveloppe.typeObjectif == TypeObjectif.mensuel &&
          enveloppe.montantCible != null &&
          enveloppe.montantCible! > 0) {
        if (enveloppe.dateCible != null) {
          messageObjectifText = '${currencyFormatter.format(
              enveloppe.montantCible)} d\'ici le ${DateFormat('d', 'fr_CA')
              .format(enveloppe.dateCible!)}';
        } else {
          messageObjectifText =
          'Obj: ${currencyFormatter.format(enveloppe.montantCible)}/mois';
        }
        progressionValue =
            (enveloppe.montantAlloue / enveloppe.montantCible!).clamp(0.0, 1.0);
        messageSousBarreText = '${currencyFormatter.format(
            enveloppe.montantAlloue)} / ${currencyFormatter.format(
            enveloppe.montantCible)} alloué(s)';
        afficherBarreProgressionPrincipale = true;
      } else if (enveloppe.typeObjectif == TypeObjectif.dateFixe &&
          enveloppe.montantCible != null &&
          enveloppe.montantCible! > 0) {
        if (enveloppe.dateCible != null) {
          messageObjectifText = '${currencyFormatter.format(
              enveloppe.montantCible)} d\'ici le ${DateFormat('d', 'fr_CA')
              .format(enveloppe.dateCible!)}';
        } else {
          messageObjectifText =
          'Obj: ${currencyFormatter.format(enveloppe.montantCible)}';
        }
        progressionValue =
            (enveloppe.soldeActuel / enveloppe.montantCible!).clamp(0.0, 1.0);
        messageSousBarreText = '${currencyFormatter.format(
            enveloppe.soldeActuel)} / ${currencyFormatter.format(
            enveloppe.montantCible)} épargné(s)';
        afficherBarreProgressionPrincipale = true;
      } else if (enveloppe.typeObjectif == TypeObjectif.aucun &&
          enveloppe.montantAlloue > 0 && enveloppe.soldeActuel >= 0) {
        progressionValue = ((enveloppe.montantAlloue - enveloppe.soldeActuel) /
            enveloppe.montantAlloue).clamp(0.0, 1.0);
        messageSousBarreText = '${currencyFormatter.format(
            enveloppe.montantAlloue -
                enveloppe.soldeActuel)} dépensé(s) / ${currencyFormatter.format(
            enveloppe.montantAlloue)}';
        afficherBarreProgressionPrincipale = enveloppe.montantAlloue > 0;
      }
    }
    if (messageSousBarreText.isEmpty && enveloppe.soldeActuel != 0 &&
        enveloppe.typeObjectif == TypeObjectif.aucun) {
      messageSousBarreText =
      'Report: ${currencyFormatter.format(enveloppe.soldeActuel)}';
    }

    Color couleurProgression = couleurBarreLaterale;
    if (couleurBarreLaterale == Colors.grey.shade400) {
      couleurProgression = Colors.grey.shade600;
    }

    // AJUSTER les paddings verticaux pour compacter
    const double paddingVerticalInterneCompact = 1.0; // Réduire de 2.0 à 1.0 ou 1.5
    const double paddingVerticalSousBarreCompact = 0.5; // Réduire de 1.0 à 0.5 ou garder 1.0

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  print('Carte ${enveloppe.nom} cliquée');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 10.0),
                  // Garder le padding global
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row( // Titre et solde
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (enveloppe.icone != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Icon(enveloppe.icone,
                                  color: enveloppe.couleurTheme.withOpacity(
                                      0.8), size: 16),
                            ),
                          Expanded(
                            child: Text(
                              enveloppe.nom.toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5.0, vertical: 2.0),
                            decoration: BoxDecoration(
                                color: couleurFondBulleSolde.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                    color: couleurFondBulleSolde.withOpacity(
                                        0.5), width: 0.5)),
                            child: Text(
                              currencyFormatter.format(enveloppe.soldeActuel),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: couleurTexteBulleSolde),
                            ),
                          ),
                        ],
                      ),

                      // Espacement après le titre/solde, avant les détails de l'objectif (si présents)
                      // On peut légèrement le réduire aussi si messageObjectifText est présent
                      if (messageObjectifText.isNotEmpty ||
                          afficherBarreProgressionPrincipale)
                        const SizedBox(height: 2.0),
                      // était implicite ou via padding top du premier élément

                      if (messageObjectifText.isNotEmpty)
                        Padding(
                          // MODIFIÉ: padding vertical réduit
                          padding: const EdgeInsets.only(
                              top: paddingVerticalInterneCompact,
                              bottom: paddingVerticalInterneCompact),
                          child: Text(
                            messageObjectifText,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.9),
                                fontStyle: FontStyle.italic),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (afficherBarreProgressionPrincipale)
                        Padding(
                          // MODIFIÉ: padding vertical réduit
                          padding: const EdgeInsets.only(
                              top: paddingVerticalInterneCompact,
                              bottom: paddingVerticalInterneCompact),
                          child: Row(children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progressionValue,
                                backgroundColor: couleurProgression.withOpacity(
                                    0.25),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    couleurProgression),
                                minHeight: 3,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(progressionValue * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: couleurProgression.withOpacity(0.9),
                                  fontWeight: FontWeight.normal),
                            ),
                          ]),
                        ),
                      if (messageSousBarreText.isNotEmpty)
                        Padding(
                          // MODIFIÉ: padding top réduit
                          padding: const EdgeInsets.only(
                              top: paddingVerticalSousBarreCompact),
                          child: Text(
                            messageSousBarreText,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 6.0,
              decoration: BoxDecoration(
                color: couleurBarreLaterale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}