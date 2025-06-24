// lib/models/compte_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Énumération pour les différents types de comptes possibles
enum TypeDeCompte {
  compteBancaire, // Compte chèque, compte courant
  especes, // Argent liquide
  credit, // Carte de crédit
  dette, // Compte d'épargne
  investissement, // Compte d'investissement (actions, obligations, etc.)
  autre // Pour tout autre type non listé
}

class Compte {
  final String? id; // L'ID unique du document Firestore
  final String nom; // Le nom donné au compte par l'utilisateur (ex: "Compte Chèque Scotia")
  final double soldeInitial; // Le solde du compte au moment de sa création
  final double soldeActuel; // Le solde actuel du compte, mis à jour par les transactions
  final TypeDeCompte type; // Le type de compte (ex: compteBancaire, especes)
  final Color couleur; // Une couleur associée au compte pour l'affichage dans l'UI
  final Timestamp dateCreation; // La date et l'heure de création du compte
  final String devise; // La devise du compte (ex: "CAD", "USD", "EUR")

  Compte({
    this.id, // Optionnel, car Firestore génère l'ID lors de l'ajout
    required this.nom,
    required this.soldeInitial,
    required this.soldeActuel, // Doit être fourni, même si initialement égal à soldeInitial
    required this.type,
    required this.couleur,
    required this.dateCreation, // Généralement Timestamp.now() lors de la création
    this.devise = 'CAD', // Valeur par défaut si non spécifié
  });

  factory Compte.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {

    Map<String, dynamic> data = doc.data() ??
        {}; // Si data est null, utilise une map vide.


    double parsedSoldeInitial = (data['soldeInitial'] as num?)?.toDouble() ??
        0.0;

    double parsedSoldeActuel = (data['soldeActuel'] as num?)?.toDouble() ??
        parsedSoldeInitial;

    TypeDeCompte parsedType = TypeDeCompte.autre; // Valeur par défaut
    if (data['type'] is String) {
      try {
        parsedType = TypeDeCompte.values.firstWhere(
              (e) =>
          e
              .toString()
              .split('.')
              .last == data['type'],
          // orElse: () => TypeDeCompte.autre, // Déjà géré par la valeur par défaut
        );
      } catch (e) {
        // Si la valeur de 'type' dans Firestore ne correspond à aucun enum,
        // parsedType reste TypeDeCompte.autre.
        // Vous pourriez vouloir logger cette situation.
        print(
            "Avertissement: Type de compte inconnu '${data['type']}' pour le document ${doc
                .id}. Utilisation de 'autre'.");
      }
    }

    // Gestion de la couleur
    // Valeur par défaut si la couleur n'est pas définie ou mal formatée.
    Color parsedCouleur = Colors.grey;
    if (data['couleurHex'] is String) {
      String couleurHex = data['couleurHex'] as String;
      // S'assure que la chaîne est un format hexadécimal valide (ex: #RRGGBB ou #AARRGGBB)
      if (couleurHex.startsWith('#') &&
          (couleurHex.length == 7 || couleurHex.length == 9)) {
        try {
          String hexValue = couleurHex.substring(1); // Retire le '#'
          if (hexValue.length == 6) { // Format RRGGBB
            hexValue = 'FF$hexValue'; // Ajoute un canal alpha opaque par défaut
          }
          parsedCouleur = Color(int.parse(hexValue, radix: 16));
        } catch (e) {
          print(
              "Erreur: Format de couleurHex invalide ('${data['couleurHex']}') pour le compte ${doc
                  .id}. Utilisation de la couleur par défaut.");
        }
      } else {
        print(
            "Avertissement: Format de couleurHex inattendu ('${data['couleurHex']}') pour le compte ${doc
                .id}. Utilisation de la couleur par défaut.");
      }
    }


    return Compte(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom inconnu',
      soldeInitial: parsedSoldeInitial,
      soldeActuel: parsedSoldeActuel,
      type: parsedType,
      couleur: parsedCouleur,
      dateCreation: data['dateCreation'] is Timestamp
          ? data['dateCreation'] as Timestamp
          : Timestamp.now(),
      devise: data['devise'] as String? ?? 'CAD',
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
      // Stocke la version String de l'enum (ex: "compteBancaire")
      // Stocke la couleur en format hexadécimal #RRGGBB.
      // substring(2) retire les "FF" de l'alpha si la couleur est opaque par défaut (valeur ARGB).
      'couleurHex': '#${couleur.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)}',
      'dateCreation': dateCreation,
      'devise': devise,
      // On ne stocke généralement pas l'ID dans le document lui-même si Firestore le génère,
      // mais si vous gérez des ID personnalisés, vous pourriez l'ajouter ici.
    };
  }

  /// Fournit une représentation textuelle de l'objet Compte.
  /// Utile pour le débogage.
  @override
  String toString() {
    return 'Compte(id: $id, nom: $nom, type: $type, soldeActuel: $soldeActuel $devise)';
  }

  /// Méthode utilitaire pour obtenir le nom affichable du type de compte.
  /// Peut être utilisée dans l'UI pour une meilleure présentation.
  String get typeDisplayName {
    String name = type
        .toString()
        .split('.')
        .last;
    // Ajoute des espaces avant les majuscules (sauf la première) et met la première lettre en majuscule.
    name = name.replaceAllMapped(
        RegExp(r'(?!^)(?=[A-Z])'), (match) => ' ${match.group(0)}');
    name = name[0].toUpperCase() + name.substring(1).toLowerCase();
    // Corrections spécifiques si nécessaire
    if (name == "Compte bancaire") return "Compte bancaire";
    if (name == "Carte de credit") return "Carte de crédit";
    if (name == "Especes") return "Espèces";
    return name;
  }
}