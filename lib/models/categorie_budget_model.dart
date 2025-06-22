import 'package:cloud_firestore/cloud_firestore.dart';

class CategorieBudgetModel {
  final String id;
  final String nom;
  final String userId;
  final int ordre; // Pour la réorganisation par glisser-déposer
  final Timestamp dateCreation;

  // final bool estArchivee; // Décommentez si vous implémentez l'archivage

  CategorieBudgetModel({
    required this.id,
    required this.nom,
    required this.userId,
    required this.ordre,
    required this.dateCreation,
    // this.estArchivee = false,
  });

  factory CategorieBudgetModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception(
          "Document data was null!"); // Ou une gestion d'erreur plus douce
    }
    return CategorieBudgetModel(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom Inconnu',
      userId: data['userId'] as String? ?? '',
      ordre: data['ordre'] as int? ?? 0,
      dateCreation: data['dateCreation'] as Timestamp? ?? Timestamp.now(),
      // estArchivee: data['estArchivee'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'userId': userId,
      'ordre': ordre,
      'dateCreation': dateCreation,
      // Pour une nouvelle catégorie, vous pouvez utiliser FieldValue.serverTimestamp() lors de l'écriture
      // 'estArchivee': estArchivee,
    };
  }
}