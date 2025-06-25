// Pour Color
import 'package:flutter/material.dart';

import '../pages/gestion_categories_enveloppes_screen.dart'; // Pour IconData

// Si vous prévoyez de séparer EnveloppePourAffichageBudget dans son propre fichier,
// vous importerez ce fichier ici. Pour l'instant, les deux sont dans ce fichier.

class EnveloppePourAffichageBudget {
  final String id;
  final String nom;
  final double montantAlloue;
  final double disponible; // deviendra soldeActuel pour EnveloppeUIData
  final double depense;    // Peut être utilisé par EnveloppeCard si besoin, sinon moins critique si EnveloppeCard recalcule.
  final Color couleur;      // deviendra couleurThemeValue et couleurSoldeCompteValue
  final IconData? icone;
  final TypeObjectif typeObjectif;
  final double? montantCible;   // (montantObjectif dans votre logique précédente peut-être)
  final DateTime? dateCible;    // (dateObjectif dans votre logique précédente peut-être)
  final int? ordre;

  EnveloppePourAffichageBudget({
    required this.id,
    required this.nom,
    required this.montantAlloue,
    required this.disponible,
    required this.depense, // Gardez-le pour l'instant, EnveloppeCard pourrait l'utiliser ou le calculer
    required this.couleur,
    this.icone,
    this.typeObjectif = TypeObjectif.aucun, // Valeur par défaut si non fourni
    this.montantCible,
    this.dateCible,
    this.ordre,
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