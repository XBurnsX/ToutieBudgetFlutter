import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart'; // Plus besoin pour Color ici

enum StatutEnveloppe { Vide, EnCours, Atteint, Negatif }

class EnveloppeModel {
  final String id;
  final String categorieId;
  final String userId;
  final String nom;
  final int ordre;
  final String compteSourceId;

  double montantAlloueActuellement;
  String? compteSourceIdDeLaDerniereAllocation;

  double? objectifMontantPeriodique;
  String? typeObjectif;
  DateTime? objectifDateEcheance;

  Timestamp dateCreation;
  Timestamp derniereModification;

  EnveloppeModel({
    required this.id,
    required this.categorieId,
    required this.userId,
    required this.nom,
    required this.ordre,
    // this.couleur, // RETIRÉ
    this.montantAlloueActuellement = 0.0,
    this.compteSourceIdDeLaDerniereAllocation,
    this.objectifMontantPeriodique,
    this.typeObjectif,
    this.objectifDateEcheance,
    required this.dateCreation,
    required this.derniereModification,
    required this.compteSourceId,
  });

  // ... (getters comme statut restent valides) ...

  factory EnveloppeModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Données du document null pour l'ID: ${doc.id}");
    }

    // PAS DE PARSING DE COULEUR ICI

    return EnveloppeModel(
      id: doc.id,
      categorieId: data['categorieId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      nom: data['nom'] as String? ?? 'Nom Inconnu',
      ordre: data['ordre'] as int? ?? 0,
      // couleur: parsedColor, // RETIRÉ
      montantAlloueActuellement: (data['montantAlloueActuellement'] as num?)
          ?.toDouble() ?? 0.0,
      compteSourceIdDeLaDerniereAllocation: data['compteSourceIdDeLaDerniereAllocation'] as String?,
      objectifMontantPeriodique: (data['objectifMontantPeriodique'] as num?)
          ?.toDouble(),
      typeObjectif: data['typeObjectif'] as String?,
      objectifDateEcheance: (data['objectifDateEcheance'] as Timestamp?)
          ?.toDate(),
      dateCreation: data['dateCreation'] as Timestamp? ?? Timestamp.now(),
      derniereModification: data['derniereModification'] as Timestamp? ??
          Timestamp.now(),
      compteSourceId: data['compteSourceId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categorieId': categorieId,
      'userId': userId,
      'nom': nom,
      'ordre': ordre,
      // 'couleur': ... // RETIRÉ
      'montantAlloueActuellement': montantAlloueActuellement,
      'compteSourceIdDeLaDerniereAllocation': compteSourceIdDeLaDerniereAllocation,
      'objectifMontantPeriodique': objectifMontantPeriodique,
      'typeObjectif': typeObjectif,
      'objectifDateEcheance': objectifDateEcheance != null ? Timestamp.fromDate(
          objectifDateEcheance!) : null,
      'dateCreation': dateCreation,
      'derniereModification': derniereModification,
      'compteSourceId': compteSourceId,
    };
  }
}