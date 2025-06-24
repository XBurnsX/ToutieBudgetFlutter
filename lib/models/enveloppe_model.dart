import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Pour Color et potentiellement IconData si vous l'ajoutez ici

// L'enum peut être ici ou dans un fichier d'utilitaires séparé si utilisé ailleurs
enum StatutEnveloppe { Vide, EnCours, Atteint, Negatif }

class EnveloppeModel {
  final String id;
  final String categorieId;
  final String userId;
  final String nom;
  final int ordre;
  Color? couleur; // <--- AJOUTER CETTE LIGNE (rendre optionnel avec '?')

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
    this.couleur, // <--- AJOUTER AU CONSTRUCTEUR
    this.montantAlloueActuellement = 0.0,
    this.compteSourceIdDeLaDerniereAllocation,
    this.objectifMontantPeriodique,
    this.typeObjectif,
    this.objectifDateEcheance,
    required this.dateCreation,
    required this.derniereModification,
  });

  StatutEnveloppe get statut {
    // ... (votre logique de statut existante) ...
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
    if (montantAlloueActuellement > 0) return StatutEnveloppe.EnCours;
    return StatutEnveloppe.Vide;
  }

  factory EnveloppeModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Document data was null!");
    }
    // Gérer la lecture de la couleur depuis Firestore (si stockée comme String Hex ou int)
    String? couleurHex = data['couleur'] as String?;
    Color? couleurObjet;
    if (couleurHex != null && couleurHex.isNotEmpty) {
      try {
        // Supposer un format #RRGGBB ou #AARRGGBB
        final buffer = StringBuffer();
        if (couleurHex.length == 6 || couleurHex.length == 7) buffer.write(
            'ff'); // Opaque si alpha non fourni
        buffer.write(couleurHex.replaceFirst('#', ''));
        couleurObjet = Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        print("Erreur de parsing de la couleur pour l'enveloppe ${doc.id}: $e");
        // Gérer l'erreur, par exemple en utilisant une couleur par défaut ou null
      }
    }

    return EnveloppeModel(
      id: doc.id,
      categorieId: data['categorieId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      nom: data['nom'] as String? ?? 'Nom Inconnu',
      ordre: data['ordre'] as int? ?? 0,
      couleur: couleurObjet,
      // <--- ASSIGNER LA COULEUR LUE
      montantAlloueActuellement:
      (data['montantAlloueActuellement'] as num?)?.toDouble() ?? 0.0,
      compteSourceIdDeLaDerniereAllocation:
      data['compteSourceIdDeLaDerniereAllocation'] as String?,
      objectifMontantPeriodique:
      (data['objectifMontantPeriodique'] as num?)?.toDouble(),
      typeObjectif: data['typeObjectif'] as String?,
      objectifDateEcheance:
      (data['objectifDateEcheance'] as Timestamp?)?.toDate(),
      dateCreation: data['dateCreation'] as Timestamp? ?? Timestamp.now(),
      derniereModification:
      data['derniereModification'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categorieId': categorieId,
      'userId': userId,
      'nom': nom,
      'ordre': ordre,
      // Gérer la sauvegarde de la couleur (par exemple, en String Hex)
      'couleur': couleur != null
          ? '#${couleur!.value.toRadixString(16).padLeft(8, '0').substring(
          2)}' // Format RRGGBB
      // Ou '#${couleur!.value.toRadixString(16).padLeft(8, '0')}' pour AARRGGBB
          : null,
      'montantAlloueActuellement': montantAlloueActuellement,
      'compteSourceIdDeLaDerniereAllocation':
      compteSourceIdDeLaDerniereAllocation,
      'objectifMontantPeriodique': objectifMontantPeriodique,
      'typeObjectif': typeObjectif,
      'objectifDateEcheance': objectifDateEcheance != null
          ? Timestamp.fromDate(objectifDateEcheance!)
          : null,
      'dateCreation': dateCreation,
      'derniereModification': derniereModification,
    };
  }
}