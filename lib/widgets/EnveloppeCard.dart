import 'package:cloud_firestore/cloud_firestore.dart'; // NÉCESSAIRE pour Timestamp
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum TypeObjectif
enum TypeObjectif { mensuel, dateFixe, aucun }

// Helper pour convertir TypeObjectif en String et vice-versa (important pour Firestore)
String typeObjectifToString(TypeObjectif type) {
  switch (type) {
    case TypeObjectif.mensuel:
      return 'mensuel';
    case TypeObjectif.dateFixe:
      return 'dateFixe';
    case TypeObjectif.aucun:
    default:
      return 'aucun';
  }
}

TypeObjectif stringToTypeObjectif(String? typeStr) {
  switch (typeStr) {
    case 'mensuel':
      return TypeObjectif.mensuel;
    case 'dateFixe':
      return TypeObjectif.dateFixe;
    case 'aucun':
    default:
      return TypeObjectif.aucun;
  }
}

class EnveloppeTestData {
  final String id;
  final String nom;
  final int? iconeCodePoint;
  final double soldeActuel;
  final double montantAlloue;
  final TypeObjectif typeObjectif;
  final double? montantCible;
  final DateTime? dateCible;
  final int couleurThemeValue;
  final int couleurSoldeCompteValue;
  final int ordre;

  // Valeurs par défaut constantes pour les couleurs
  static const int _defaultCouleurThemeValue = 0xFF2196F3; // Équivalent à Colors.blue.shade500.value
  static const int _defaultCouleurSoldeCompteValue = 0xFF9E9E9E; // Équivalent à Colors.grey.shade500.value

  EnveloppeTestData({
    required this.id,
    required this.nom,
    this.iconeCodePoint,
    required this.soldeActuel,
    required this.montantAlloue,
    this.typeObjectif = TypeObjectif.aucun,
    this.montantCible,
    this.dateCible,
    this.couleurThemeValue = _defaultCouleurThemeValue,
    required this.couleurSoldeCompteValue,
    this.ordre = 0,
  });

  // Propriétés calculées pour récupérer les objets Color et IconData originaux
  IconData? get icone =>
      iconeCodePoint != null ? IconData(
          iconeCodePoint!, fontFamily: 'MaterialIcons') : null;

  Color get couleurTheme => Color(couleurThemeValue);

  Color get couleurSoldeCompte => Color(couleurSoldeCompteValue);

  // Méthode pour convertir un objet EnveloppeTestData en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Assurez-vous que l'ID EST SAUVEGARDÉ DANS LA MAP
      'nom': nom,
      'iconeCodePoint': iconeCodePoint,
      'soldeActuel': soldeActuel,
      'montantAlloue': montantAlloue,
      'typeObjectif': typeObjectifToString(typeObjectif),
      'montantCible': montantCible,
      'dateCible': dateCible != null ? Timestamp.fromDate(dateCible!) : null,
      'couleurThemeValue': couleurThemeValue,
      'couleurSoldeCompteValue': couleurSoldeCompteValue,
      'ordre': ordre,
    };
  }

  // Votre fromFirestore existant
  factory EnveloppeTestData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return EnveloppeTestData(
      id: doc.id, // ID vient du DocumentSnapshot
      nom: data['nom'] as String? ?? '',
      iconeCodePoint: data['iconeCodePoint'] as int?,
      soldeActuel: (data['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      montantAlloue: (data['montantAlloue'] as num?)?.toDouble() ?? 0.0,
      typeObjectif: stringToTypeObjectif(data['typeObjectif'] as String?),
      montantCible: (data['montantCible'] as num?)?.toDouble(),
      dateCible: (data['dateCible'] as Timestamp?)?.toDate(),
      couleurThemeValue: data['couleurThemeValue'] as int? ?? _defaultCouleurThemeValue,
      couleurSoldeCompteValue: data['couleurSoldeCompteValue'] as int? ?? _defaultCouleurSoldeCompteValue,
      ordre: data['ordre'] as int? ?? 0,
    );
  }

  // **** NOUVELLE MÉTHODE À AJOUTER ****
  factory EnveloppeTestData.fromMap(Map<String, dynamic> map) {
    return EnveloppeTestData(
      // L'ID doit être dans la map elle-même, car nous n'avons pas de DocumentSnapshot ici
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(), // Fournir un fallback pour l'ID si manquant
      nom: map['nom'] as String? ?? '',
      iconeCodePoint: map['iconeCodePoint'] as int?,
      soldeActuel: (map['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      montantAlloue: (map['montantAlloue'] as num?)?.toDouble() ?? 0.0,
      typeObjectif: stringToTypeObjectif(map['typeObjectif'] as String?),
      montantCible: (map['montantCible'] as num?)?.toDouble(),
      // Adaptez la gestion de la date si vous stockez différemment dans la map imbriquée
      // Si c'est un Timestamp dans la map imbriquée :
      dateCible: (map['dateCible'] as Timestamp?)?.toDate(),
      // Si c'est une String ISO dans la map imbriquée :
      // dateCible: map['dateCible'] != null ? DateTime.parse(map['dateCible'] as String) : null,
      couleurThemeValue: map['couleurThemeValue'] as int? ?? _defaultCouleurThemeValue,
      couleurSoldeCompteValue: map['couleurSoldeCompteValue'] as int? ?? _defaultCouleurSoldeCompteValue,
      ordre: map['ordre'] as int? ?? 0,
    );
  }
}

class EnveloppeCard extends StatelessWidget {
  final EnveloppeTestData enveloppe;

  const EnveloppeCard({Key? key, required this.enveloppe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
        locale: 'fr_CA', symbol: '\$');

    // Détermination des couleurs pour la bulle de solde
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

    // Détermination de la couleur de la barre latérale
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
        } else {
          couleurBarreLaterale = Colors.grey.shade400;
        }
      } else if (enveloppe.soldeActuel > 0) {
        couleurBarreLaterale = Colors.green.shade500;
      } else {
        couleurBarreLaterale = Colors.grey.shade400;
      }
    }

    // Calculs pour la barre de progression et messages
    double progressionValue = 0;
    String messageObjectifText = '';
    String messageSousBarreText = '';
    bool afficherBarreProgressionPrincipale = false;

    if (enveloppe.soldeActuel >= 0) {
      if (enveloppe.typeObjectif == TypeObjectif.mensuel &&
          enveloppe.montantCible != null &&
          enveloppe.montantCible! > 0) {
        if (enveloppe.dateCible != null) {
          messageObjectifText =
          '${currencyFormatter.format(
              enveloppe.montantCible)} d\'ici le ${DateFormat('d', 'fr_CA')
              .format(enveloppe.dateCible!)}';
        } else {
          messageObjectifText =
          'Obj: ${currencyFormatter.format(enveloppe.montantCible)}/mois';
        }
        progressionValue =
            (enveloppe.montantAlloue / enveloppe.montantCible!).clamp(0.0, 1.0);
        messageSousBarreText =
        '${currencyFormatter.format(
            enveloppe.montantAlloue)} / ${currencyFormatter.format(
            enveloppe.montantCible)} alloué(s)';
        afficherBarreProgressionPrincipale = true;
      } else if (enveloppe.typeObjectif == TypeObjectif.dateFixe &&
          enveloppe.montantCible != null &&
          enveloppe.montantCible! > 0) {
        if (enveloppe.dateCible != null) {
          messageObjectifText =
          '${currencyFormatter.format(
              enveloppe.montantCible)} d\'ici le ${DateFormat('d', 'fr_CA')
              .format(enveloppe.dateCible!)}';
        } else {
          messageObjectifText =
          'Obj: ${currencyFormatter.format(enveloppe.montantCible)}';
        }
        progressionValue =
            (enveloppe.soldeActuel / enveloppe.montantCible!).clamp(0.0, 1.0);
        messageSousBarreText =
        '${currencyFormatter.format(
            enveloppe.soldeActuel)} / ${currencyFormatter.format(
            enveloppe.montantCible)} épargné(s)';
        afficherBarreProgressionPrincipale = true;
      } else if (enveloppe.typeObjectif == TypeObjectif.aucun &&
          enveloppe.montantAlloue > 0 &&
          enveloppe.soldeActuel >= 0) {
        progressionValue = ((enveloppe.montantAlloue - enveloppe.soldeActuel) /
            enveloppe.montantAlloue).clamp(0.0, 1.0);
        messageSousBarreText =
        '${currencyFormatter.format(enveloppe.montantAlloue -
            enveloppe.soldeActuel)} dépensé(s) / ${currencyFormatter.format(
            enveloppe.montantAlloue)}';
        afficherBarreProgressionPrincipale = enveloppe.montantAlloue > 0;
      }
    }

    if (messageSousBarreText.isEmpty &&
        enveloppe.soldeActuel != 0 &&
        enveloppe.typeObjectif == TypeObjectif.aucun &&
        !(enveloppe.montantAlloue > 0 && enveloppe.soldeActuel >= 0)) {
      messageSousBarreText =
      'Report: ${currencyFormatter.format(enveloppe.soldeActuel)}';
    }

    Color couleurProgression = couleurBarreLaterale;
    if (couleurBarreLaterale == Colors.grey.shade400 &&
        afficherBarreProgressionPrincipale) {
      couleurProgression = Colors.grey.shade600;
    }

    const double paddingVerticalInterneCompact = 1.0;
    const double paddingVerticalSousBarreCompact = 0.5;

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
                  print('Carte ${enveloppe.nom} cliquée (ID: ${enveloppe.id})');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      if (messageObjectifText.isNotEmpty ||
                          afficherBarreProgressionPrincipale)
                        const SizedBox(height: 2.0),
                      if (messageObjectifText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: paddingVerticalInterneCompact,
                              bottom: paddingVerticalInterneCompact),
                          child: Text(
                            messageObjectifText,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.9),
                                fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (afficherBarreProgressionPrincipale)
                        Padding(
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
                          padding: const EdgeInsets.only(
                              top: paddingVerticalSousBarreCompact),
                          child: Text(
                            messageSousBarreText,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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