import 'package:cloud_firestore/cloud_firestore.dart';

class EnveloppeModel {
  // ... autres champs existants ...
  String id;
  String nom;
  String userId;
  String categorieId;
  // String? compteSourceId; // L'ancien nom, à remplacer ou supprimer
  String? compteSourceAttacheId; // NOUVEAU : ID du compte bancaire lié après le 1er virement
  int? couleurCompteSourceHex;  // NOUVEAU : Couleur du compte bancaire lié
  double soldeEnveloppe;
  int ordre;
  String typeObjectifString;
  double? objectifMontantPeriodique;
  Timestamp? objectifDateEcheance;
  Timestamp dateCreation;
  Timestamp derniereModification;
  int? couleurThemeValue; // Ce champ est-il toujours pertinent ou est-il remplacé par couleurCompteSourceHex pour l'affichage ?

  EnveloppeModel({
    required this.id,
    required this.nom,
    required this.userId,
    required this.categorieId,
    this.compteSourceAttacheId, // Initialisé à null
    this.couleurCompteSourceHex, // Initialisé à null
    required this.soldeEnveloppe,
    required this.ordre,
    required this.typeObjectifString,
    this.objectifMontantPeriodique,
    this.objectifDateEcheance,
    required this.dateCreation,
    required this.derniereModification,
    this.couleurThemeValue,
  });

  factory EnveloppeModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour l\'enveloppe ID: ${doc.id}');
    }
    return EnveloppeModel(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom inconnu',
      userId: data['userId'] as String,
      categorieId: data['categorieId'] as String,
      compteSourceAttacheId: data['compteSourceAttacheId'] as String?, // Lire depuis Firestore
      couleurCompteSourceHex: data['couleurCompteSourceHex'] as int?, // Lire depuis Firestore
      soldeEnveloppe: (data['soldeEnveloppe'] as num? ?? 0).toDouble(),
      ordre: data['ordre'] as int? ?? 0,
      typeObjectifString: data['typeObjectifString'] as String? ?? TypeObjectif.aucun.name,
      objectifMontantPeriodique: (data['objectifMontantPeriodique'] as num?)?.toDouble(),
      objectifDateEcheance: data['objectifDateEcheance'] as Timestamp?,
      dateCreation: data['dateCreation'] as Timestamp? ?? Timestamp.now(),
      derniereModification: data['derniereModification'] as Timestamp? ?? Timestamp.now(),
      couleurThemeValue: data['couleurThemeValue'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'userId': userId,
      'categorieId': categorieId,
      'compteSourceAttacheId': compteSourceAttacheId, // Écrire dans Firestore
      'couleurCompteSourceHex': couleurCompteSourceHex, // Écrire dans Firestore
      'soldeEnveloppe': soldeEnveloppe,
      'ordre': ordre,
      'typeObjectifString': typeObjectifString,
      'objectifMontantPeriodique': objectifMontantPeriodique,
      'objectifDateEcheance': objectifDateEcheance,
      'dateCreation': dateCreation,
      'derniereModification': derniereModification,
      'couleurThemeValue': couleurThemeValue,
    };
  }
}