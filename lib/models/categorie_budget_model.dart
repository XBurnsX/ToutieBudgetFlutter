import 'dart:ui'; // Nécessaire pour le type Color

import 'package:flutter/material.dart'; // Nécessaire pour IconData (et Color si vous ne l'importez pas de dart:ui)

// Vous pouvez garder ces modèles dans ce fichier ou les déplacer dans leurs propres fichiers
// par exemple, 'models/categorie_budget_model.dart' et 'models/enveloppe_model.dart'

class CategorieBudgetModel {
  String id;
  String nom;
  Color couleur; // Couleur de base pour la catégorie
  double alloueTotal;
  double depenseTotal;
  double disponibleTotal;
  String info;
  List<EnveloppeModel> enveloppes;

  CategorieBudgetModel({
    required this.id,
    required this.nom,
    required this.couleur, // Ajouté au constructeur
    this.alloueTotal = 0.0,
    this.depenseTotal = 0.0,
    this.disponibleTotal = 0.0,
    this.info = "",
    List<EnveloppeModel>? enveloppes,
  }) : enveloppes = enveloppes ?? [];

// Vous pouvez ajouter ici des méthodes factory pour la conversion depuis/vers Firestore
// si vous prévoyez de stocker ces modèles directement.
// Exemple: factory CategorieBudgetModel.fromFirestore(DocumentSnapshot doc) { ... }
// Map<String, dynamic> toFirestore() { ... }
}

class EnveloppeModel {
  String id;
  String nom;
  IconData? icone;
  Color? couleur; // Optionnel: Couleur spécifique pour l'enveloppe,
  // peut hériter ou moduler la couleur de la catégorie parente sinon.
  double montantBudgete; // Souvent le même que montantAlloue au début du mois
  double montantAlloue; // Montant effectivement assigné à cette enveloppe
  double depense;
  double disponible;
  String? messageSous; // Un petit message ou une note sous l'enveloppe

  EnveloppeModel({
    required this.id,
    required this.nom,
    this.icone,
    this.couleur, // Ajouté au constructeur (optionnel)
    this.montantBudgete = 0.0,
    this.montantAlloue = 0.0,
    this.depense = 0.0,
    this.disponible = 0.0,
    this.messageSous,
  });

// De même, des méthodes from/to Firestore peuvent être ajoutées ici.
}