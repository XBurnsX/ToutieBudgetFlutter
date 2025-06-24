// lib/models/compte_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Énumération pour les différents types de comptes possibles
enum TypeDeCompte {
  compteBancaire, // Compte chèque, compte courant
  especes, // Argent liquide
  credit, // Carte de crédit
  dette, // Prêt (pas compte d'épargne)
  investissement, // Compte d'investissement (actions, obligations, etc.)
  autre // Pour tout autre type non listé
}

class Compte {
  final String? id; // L'ID unique du document Firestore
  final String nom; // Le nom donné au compte par l'utilisateur
  final double soldeInitial; // Le solde du compte au moment de sa création
  final double soldeActuel; // Le solde actuel du compte
  final TypeDeCompte type; // Le type de compte
  final Color couleur; // Une couleur associée au compte
  final Timestamp dateCreation; // La date et l'heure de création du compte
  final String devise; // La devise du compte (ex: "CAD", "USD", "EUR")

  Compte({
    this.id,
    required this.nom,
    required this.soldeInitial,
    required this.soldeActuel,
    required this.type,
    required this.couleur,
    required this.dateCreation,
    this.devise = 'CAD',
  });

  /// Méthode statique pour créer une instance de Compte à partir d'un DocumentSnapshot de Firestore.
  /// C'est la source de vérité pour lire les données d'un compte.
  static Compte fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data() ??
        {}; // Si data est null, utilise une map vide.

    // 1. Gestion de la Couleur
    Color parsedCouleur = Colors.grey; // Couleur par défaut universelle
    if (data['couleurHex'] is String) {
      String couleurHex = data['couleurHex'] as String;
      if (couleurHex.startsWith('#') &&
          (couleurHex.length == 7 || couleurHex.length == 9)) {
        try {
          String hexValue = couleurHex.substring(1);
          if (hexValue.length == 6) { // Format RRGGBB
            hexValue = 'FF$hexValue'; // Ajoute un canal alpha opaque par défaut
          }
          parsedCouleur = Color(int.parse(hexValue, radix: 16));
        } catch (e) {
          debugPrint(
              "ERREUR PARSING Compte.fromSnapshot pour couleurHex ('$couleurHex') compte ${doc
                  .id}: $e. Utilisation couleur par défaut.");
        }
      } else {
        debugPrint(
            "FORMAT INATTENDU Compte.fromSnapshot pour couleurHex ('$couleurHex') compte ${doc
                .id}. Utilisation couleur par défaut.");
      }
    } else if (data.containsKey('couleurValue') &&
        data['couleurValue'] is int) { // Ancien format pour rétrocompatibilité
      try {
        parsedCouleur = Color(data['couleurValue'] as int);
      } catch (e) {
        debugPrint(
            "ERREUR PARSING Compte.fromSnapshot pour couleurValue ('${data['couleurValue']}') compte ${doc
                .id}: $e. Utilisation couleur par défaut.");
      }
    } else {
      // Ce debugPrint n'est utile que si vous vous attendez TOUJOURS à avoir une couleur.
      // Si la couleur est optionnelle et que l'absence de 'couleurHex' signifie "utiliser le défaut", alors ce n'est pas une erreur.
      debugPrint(
          "INFO Compte.fromSnapshot: Aucun champ 'couleurHex' ou 'couleurValue' valide trouvé pour le compte ${doc
              .id}. Utilisation de la couleur par défaut.");
    }

    // 2. Gestion de la Date de Création
    Timestamp parsedDateCreation;
    if (data['dateCreation'] is Timestamp) {
      parsedDateCreation = data['dateCreation'] as Timestamp;
    } else if (data['dateCreation'] is String) {
      try {
        DateTime dt = DateTime.parse(data['dateCreation'] as String);
        parsedDateCreation = Timestamp.fromDate(dt);
      } catch (e) {
        debugPrint(
            "ERREUR PARSING Compte.fromSnapshot pour dateCreation String ('${data['dateCreation']}') compte ${doc
                .id}: $e. Utilisation now().");
        parsedDateCreation = Timestamp.now();
      }
    } else {
      debugPrint(
          "CHAMP DATE CREATION MANQUANT/INVALIDE Compte.fromSnapshot pour compte ${doc
              .id}. Utilisation now().");
      parsedDateCreation = Timestamp.now();
    }

    // 3. Gestion des Soldes
    double parsedSoldeInitial = (data['soldeInitial'] as num?)?.toDouble() ??
        0.0;
    double parsedSoldeActuel = (data['soldeActuel'] as num?)?.toDouble() ??
        parsedSoldeInitial;

    // 4. Gestion de la Devise
    String parsedDevise = data['devise'] as String? ?? 'CAD';

    // 5. Gestion du Type de Compte
    TypeDeCompte parsedType = TypeDeCompte.autre; // Valeur par défaut
    if (data['type'] is String) {
      try {
        parsedType = TypeDeCompte.values.firstWhere(
              (e) =>
          e
              .toString()
              .split('.')
              .last == data['type'],
        );
      } catch (e) {
        debugPrint(
            "TYPE INCONNU Compte.fromSnapshot ('${data['type']}') pour compte ${doc
                .id}: $e. Utilisation 'autre'.");
        // parsedType reste TypeDeCompte.autre
      }
    } else {
      debugPrint(
          "CHAMP TYPE MANQUANT/INVALIDE Compte.fromSnapshot pour compte ${doc
              .id}. Utilisation 'autre'.");
    }

    return Compte(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom inconnu',
      soldeInitial: parsedSoldeInitial,
      soldeActuel: parsedSoldeActuel,
      type: parsedType,
      couleur: parsedCouleur,
      dateCreation: parsedDateCreation,
      devise: parsedDevise,
    );
  }

  /// Méthode pour convertir une instance de [Compte] en une [Map] pour l'écriture dans Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'soldeInitial': soldeInitial,
      'soldeActuel': soldeActuel,
      'type': type
          .toString()
          .split('.')
          .last,
      'couleurHex': '#${couleur.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)
          .toUpperCase()}', // Assure le format #RRGGBB
      'dateCreation': dateCreation,
      'devise': devise,
    };
  }

  /// Fournit une représentation textuelle de l'objet Compte.
  @override
  String toString() {
    return 'Compte(id: $id, nom: $nom, type: $type, soldeActuel: $soldeActuel $devise, couleur: $couleur)';
  }

  /// Méthode utilitaire pour obtenir le nom affichable du type de compte.
  String get typeDisplayName {
    String name = type
        .toString()
        .split('.')
        .last;
    name = name.replaceAllMapped(
        RegExp(r'(?!^)(?=[A-Z])'), (match) => ' ${match.group(0)}');
    name = name[0].toUpperCase() + name.substring(1).toLowerCase();
    // Corrections spécifiques
    if (name == "Compte bancaire") return "Compte bancaire";
    if (name == "Carte de credit") return "Carte de crédit";
    if (name == "Especes") return "Espèces";
    return name;
  }
}