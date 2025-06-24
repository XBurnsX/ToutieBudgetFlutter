import 'dart:ui'; // Pour Color
import 'package:flutter/material.dart'; // Pour IconData

// Si vous prévoyez de séparer EnveloppePourAffichageBudget dans son propre fichier,
// vous importerez ce fichier ici. Pour l'instant, les deux sont dans ce fichier.

class EnveloppePourAffichageBudget {
  final String id;
  final String nom;
  final double montantAlloue;
  final double disponible;
  final double depense;
  final Color couleur;
  final IconData? icone;
  final String? messageSous;

  EnveloppePourAffichageBudget({
    required this.id,
    required this.nom,
    required this.montantAlloue,
    required this.disponible,
    required this.depense,
    required this.couleur,
    this.icone,
    this.messageSous,
  });
}

class CategorieBudgetModel {
  final String id;
  final String nom;
  final Color couleur;
  final String info;
  final double alloueTotal;
  final double depenseTotal;
  final double disponibleTotal;
  final List<EnveloppePourAffichageBudget> enveloppes; // Référence EnveloppePourAffichageBudget

  CategorieBudgetModel({
    required this.id,
    required this.nom,
    required this.couleur,
    required this.info,
    required this.alloueTotal,
    required this.depenseTotal,
    required this.disponibleTotal,
    required this.enveloppes,
  });
}