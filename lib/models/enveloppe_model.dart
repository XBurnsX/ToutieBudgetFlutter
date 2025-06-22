import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Pour la couleur de la bulle, bien que la couleur elle-même viendra du compte

// L'enum peut être ici ou dans un fichier d'utilitaires séparé si utilisé ailleurs
enum StatutEnveloppe { Vide, EnCours, Atteint, Negatif }

class EnveloppeModel {
  final String id;
  final String categorieId; // ID de la CategorieBudgetModel parente
  final String userId;
  final String nom;
  final int ordre; // Si vous voulez ordonner les enveloppes dans une catégorie

  double montantAlloueActuellement;
  String? compteSourceIdDeLaDerniereAllocation; // ID du CompteModel source

  // Objectifs (facultatif mais utile pour les barres de statut)
  double? objectifMontantPeriodique; // Ex: besoin de 300€ ce mois-ci
  // Pourrait être un enum: enum TypeObjectif { MensuelFixe, DateFixe, AnnuelSurMois, Aucun }
  String? typeObjectif;
  DateTime? objectifDateEcheance; // Pour les objectifs à date fixe

  Timestamp dateCreation;
  Timestamp derniereModification;

  EnveloppeModel({
    required this.id,
    required this.categorieId,
    required this.userId,
    required this.nom,
    required this.ordre,
    this.montantAlloueActuellement = 0.0,
    this.compteSourceIdDeLaDerniereAllocation,
    this.objectifMontantPeriodique,
    this.typeObjectif,
    this.objectifDateEcheance,
    required this.dateCreation,
    required this.derniereModification,
  });

  // Le statut est calculé, pas stocké directement, car il dépend de plusieurs facteurs.
  // Cette logique peut être affinée.
  StatutEnveloppe get statut {
    if (montantAlloueActuellement < 0) return StatutEnveloppe.Negatif;
    if (montantAlloueActuellement == 0 &&
        (objectifMontantPeriodique == null || objectifMontantPeriodique == 0)) {
      // Si aucun objectif et vide, c'est Vide. Si objectif > 0 et vide, c'est EnCours.
      return StatutEnveloppe.Vide;
    }
    if (objectifMontantPeriodique != null && objectifMontantPeriodique! > 0) {
      if (montantAlloueActuellement >= objectifMontantPeriodique!) {
        return StatutEnveloppe.Atteint;
      }
    }
    // Si alloué > 0 mais < objectif, ou si pas d'objectif mais alloué > 0
    if (montantAlloueActuellement > 0) return StatutEnveloppe.EnCours;

    return StatutEnveloppe.Vide; // Cas par défaut
  }

  factory EnveloppeModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception(
          "Document data was null!"); // Ou une gestion d'erreur plus douce
    }
    return EnveloppeModel(
      id: doc.id,
      categorieId: data['categorieId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      nom: data['nom'] as String? ?? 'Nom Inconnu',
      ordre: data['ordre'] as int? ?? 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categorieId': categorieId,
      'userId': userId,
      'nom': nom,
      'ordre': ordre,
      'montantAlloueActuellement': montantAlloueActuellement,
      'compteSourceIdDeLaDerniereAllocation': compteSourceIdDeLaDerniereAllocation,
      'objectifMontantPeriodique': objectifMontantPeriodique,
      'typeObjectif': typeObjectif,
      'objectifDateEcheance': objectifDateEcheance != null ? Timestamp.fromDate(
          objectifDateEcheance!) : null,
      'dateCreation': dateCreation,
      'derniereModification': derniereModification,
      // Pour une nouvelle, FieldValue.serverTimestamp()
    };
  }
}