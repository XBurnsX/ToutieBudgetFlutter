// Nom du fichier : models/enveloppe_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Pour Color et IconData

// L'enum peut être ici ou dans un fichier d'utilitaires séparé si utilisé ailleurs
enum StatutEnveloppe { Vide, EnCours, Atteint, Negatif }

class EnveloppeModel {
  final String id;
  final String categorieId;
  final String userId;
  final String nom;
  final int ordre;
  Color? couleur; // Couleur spécifique pour l'enveloppe

  double montantAlloueActuellement; // C'est le SOLDE actuel
  String? compteSourceIdDeLaDerniereAllocation;

  double? objectifMontantPeriodique; // Le montant total visé pour la période
  String? typeObjectif; // ex: 'mensuel', 'dateFixe', 'aucun'
  DateTime? objectifDateEcheance;

  Timestamp dateCreation;
  Timestamp derniereModification;

  // --- Champs optionnels que vous pourriez vouloir ajouter ---
  // int? iconeCodePoint; // Pour stocker IconData.codePoint
  // String? iconeFontFamily; // Pour stocker IconData.fontFamily (ex: 'MaterialIcons')
  // String? messageSous;

  EnveloppeModel({
    required this.id,
    required this.categorieId,
    required this.userId,
    required this.nom,
    required this.ordre,
    this.couleur,
    this.montantAlloueActuellement = 0.0,
    this.compteSourceIdDeLaDerniereAllocation,
    this.objectifMontantPeriodique,
    this.typeObjectif,
    this.objectifDateEcheance,
    required this.dateCreation,
    required this.derniereModification,
    // this.iconeCodePoint, // Décommentez si vous ajoutez l'icône
    // this.iconeFontFamily, // Décommentez si vous ajoutez l'icône
    // this.messageSous,    // Décommentez si vous ajoutez messageSous
  });

  // Getter pour IconData si vous stockez codePoint et fontFamily
  // IconData? get icone {
  //   if (iconeCodePoint != null && iconeFontFamily != null) {
  //     return IconData(iconeCodePoint!, fontFamily: iconeFontFamily);
  //   }
  //   return null;
  // }

  StatutEnveloppe get statut {
    if (montantAlloueActuellement < 0) return StatutEnveloppe.Negatif;
    if (montantAlloueActuellement == 0 &&
        (objectifMontantPeriodique == null || objectifMontantPeriodique == 0)) {
      return StatutEnveloppe.Vide;
    }
    if (objectifMontantPeriodique != null && objectifMontantPeriodique! > 0) {
      if (montantAlloueActuellement >= objectifMontantPeriodique!) {
        return StatutEnveloppe.Atteint;
      }
    }
    if (montantAlloueActuellement > 0) return StatutEnveloppe
        .EnCours; // Même sans objectif, s'il y a de l'argent, c'est en cours.
    return StatutEnveloppe.Vide; // Cas par défaut
  }

  factory EnveloppeModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Gérer le cas où le document n'existe pas ou n'a pas de données
      // Vous pourriez lancer une exception ou retourner une instance par défaut
      throw Exception("Données du document null pour l'ID: ${doc.id}");
    }

    Color? parsedColor;
    if (data['couleur'] != null) {
      try {
        String couleurHex = data['couleur'] as String;
        // Gère les formats #RRGGBB, RRGGBB, #AARRGGBB, AARRGGBB
        if (couleurHex.startsWith('#')) {
          couleurHex = couleurHex.substring(1);
        }
        if (couleurHex.length == 6) { // RRGGBB
          couleurHex = 'FF$couleurHex'; // Ajoute alpha opaque
        }
        if (couleurHex.length == 8) { // AARRGGBB
          parsedColor = Color(int.parse(couleurHex, radix: 16));
        }
      } catch (e) {
        print("Erreur de parsing de la couleur pour l'enveloppe ${doc
            .id}: $e. Couleur brute: ${data['couleur']}");
        // Optionnel: assigner une couleur par défaut ou laisser null
      }
    }

    return EnveloppeModel(
      id: doc.id,
      categorieId: data['categorieId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      nom: data['nom'] as String? ?? 'Nom Inconnu',
      ordre: data['ordre'] as int? ?? 0,
      couleur: parsedColor,
      montantAlloueActuellement: (data['montantAlloueActuellement'] as num?)
          ?.toDouble() ?? 0.0,
      compteSourceIdDeLaDerniereAllocation: data['compteSourceIdDeLaDerniereAllocation'] as String?,
      objectifMontantPeriodique: (data['objectifMontantPeriodique'] as num?)
          ?.toDouble(),
      typeObjectif: data['typeObjectif'] as String?,
      objectifDateEcheance: (data['objectifDateEcheance'] as Timestamp?)
          ?.toDate(),
      dateCreation: data['dateCreation'] as Timestamp? ?? Timestamp.now(),
      // Valeur par défaut si null
      derniereModification: data['derniereModification'] as Timestamp? ??
          Timestamp.now(), // Valeur par défaut si null
      // iconeCodePoint: data['iconeCodePoint'] as int?,       // Décommentez
      // iconeFontFamily: data['iconeFontFamily'] as String?, // Décommentez
      // messageSous: data['messageSous'] as String?,         // Décommentez
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categorieId': categorieId,
      'userId': userId,
      'nom': nom,
      'ordre': ordre,
      'couleur': couleur != null ? '#${couleur!.value.toRadixString(16).padLeft(
          8, '0').substring(2)}' : null,
      // RRGGBB, sans alpha
      // Pour stocker avec Alpha (AARRGGBB): '#${couleur!.value.toRadixString(16).padLeft(8, '0')}'
      'montantAlloueActuellement': montantAlloueActuellement,
      'compteSourceIdDeLaDerniereAllocation': compteSourceIdDeLaDerniereAllocation,
      'objectifMontantPeriodique': objectifMontantPeriodique,
      'typeObjectif': typeObjectif,
      'objectifDateEcheance': objectifDateEcheance != null ? Timestamp.fromDate(
          objectifDateEcheance!) : null,
      'dateCreation': dateCreation,
      'derniereModification': derniereModification,
      // 'iconeCodePoint': iconeCodePoint,     // Décommentez
      // 'iconeFontFamily': iconeFontFamily,  // Décommentez
      // 'messageSous': messageSous,          // Décommentez
    };
  }
}