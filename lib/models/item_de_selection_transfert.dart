// lib/models/item_de_selection_transfert.dart (ou le chemin que vous préférez)

import 'package:flutter/foundation.dart'; // Pour @required ou required dans les versions récentes de Flutter/Dart

class ItemDeSelectionTransfert {
  final String id;
  final String nom;
  final double solde;
  final bool estPretAPlacer;

  // Ajoutez d'autres champs si nécessaire (par exemple, icône, catégorie, etc.)

  ItemDeSelectionTransfert({
    required this.id,
    required this.nom,
    required this.solde,
    this.estPretAPlacer = false, // Valeur par défaut si non spécifié
  });

  // Optionnel : Si vous avez besoin de comparer des instances pour les DropdownButtonFormField
  // ou pour d'autres logiques de sélection.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ItemDeSelectionTransfert &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    // Utile pour le débogage
    return 'ItemDeSelectionTransfert(id: $id, nom: $nom, solde: $solde, estPretAPlacer: $estPretAPlacer)';
  }
}