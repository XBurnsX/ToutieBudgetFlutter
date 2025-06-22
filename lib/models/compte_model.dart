import 'package:flutter/foundation.dart'; // Pour @required si vous utilisez d'anciennes versions, ou pour d'autres annotations

enum TypeDeCompte {
  compteBancaire,
  dette,
  investissement,
}

class Compte {
  String id;
  String nom;
  TypeDeCompte type;
  double solde;

  Compte({
    required this.id,
    required this.nom,
    required this.type,
    required this.solde,
  });

// Vous pourriez ajouter d'autres méthodes ici à l'avenir,
// comme des méthodes toJson/fromJson pour la persistance des données.
}