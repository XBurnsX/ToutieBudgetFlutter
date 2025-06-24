// lib/models/compte_bancaire_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeCompte {
  Courant,
  Epargne,
  Credit,
  Investissement,
  Autre,
}

String typeCompteToString(TypeCompte type) {
  switch (type) {
    case TypeCompte.Courant:
      return 'Courant';
    case TypeCompte.Epargne:
      return 'Épargne';
    case TypeCompte.Credit:
      return 'Crédit';
    case TypeCompte.Investissement:
      return 'Investissement';
    case TypeCompte.Autre:
    default:
      return 'Autre';
  }
}

TypeCompte stringToTypeCompte(String? typeStr) {
  switch (typeStr?.toLowerCase()) {
    case 'courant':
      return TypeCompte.Courant;
    case 'épargne':
    case 'epargne': // Pour la flexibilité
      return TypeCompte.Epargne;
    case 'crédit':
    case 'credit':
      return TypeCompte.Credit;
    case 'investissement':
      return TypeCompte.Investissement;
    default:
      return TypeCompte.Autre;
  }
}

class CompteBancaireModel {
  final String id;
  final String userId;
  String nom;
  double soldeInitial; // Ou soldeActuelBrut si vous préférez ce terme
  TypeCompte typeCompte;
  String? emoji; // Optionnel
  String? couleurHex; // Optionnel, stocké comme String Hex (ex: "#FF0000")
  Timestamp dateCreation;
  Timestamp derniereModification;

  // Ajoutez d'autres champs si nécessaire (numéro de compte, institution, etc.)

  CompteBancaireModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.soldeInitial,
    required this.typeCompte,
    this.emoji,
    this.couleurHex,
    required this.dateCreation,
    required this.derniereModification,
  });

  // Factory constructor pour créer une instance depuis un DocumentSnapshot Firestore
  factory CompteBancaireModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) { // doc est un DocumentSnapshot
    final data = doc.data(); // Extrait la Map<String, dynamic> ici
    if (data == null) {
      throw Exception("Données du document de compte null pour l'ID: ${doc.id}");
    }

    return CompteBancaireModel(
      id: doc.id, // Utilise doc.id
      userId: data['userId'] as String? ?? '', // Utilise data (qui est doc.data())
      nom: data['nom'] as String? ?? 'Compte Inconnu',
      soldeInitial: (data['soldeInitial'] as num?)?.toDouble() ?? 0.0,
      typeCompte: stringToTypeCompte(data['typeCompte'] as String?),
      emoji: data['emoji'] as String?,
      couleurHex: data['couleurHex'] as String?,
      dateCreation: data['dateCreation'] as Timestamp? ?? Timestamp.now(),
      derniereModification: data['derniereModification'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Méthode pour convertir une instance en Map pour l'écriture dans Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nom': nom,
      'soldeInitial': soldeInitial, // Important: nom du champ Firestore
      'typeCompte': typeCompteToString(typeCompte),
      'emoji': emoji,
      'couleurHex': couleurHex,
      'dateCreation': dateCreation,
      'derniereModification': derniereModification,
      // N'incluez pas 'id' ici car c'est l'ID du document
    };
  }
}