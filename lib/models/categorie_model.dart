import 'package:cloud_firestore/cloud_firestore.dart';

// Importez EnveloppeModel si votre Categorie doit contenir des enveloppes
// import './enveloppe_model.dart';

class CategorieModel {
  // J'utilise CategorieModel pour éviter toute confusion avec l'ancienne
  String id;
  String nom;

  // Optionnel: si une catégorie dans votre logique de vue DOIT avoir une liste d'enveloppes.
  // List<EnveloppeModel> enveloppes;

  CategorieModel({
    required this.id,
    required this.nom,
    // this.enveloppes = const [],
  });

  factory CategorieModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Données manquantes pour la catégorie ID: ${doc.id}');
    }
    return CategorieModel(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom non défini',
    );
  }

  // toJson si vous en avez besoin pour écrire dans Firestore (généralement seulement nom)
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      // Ne stockez pas l'ID dans le document lui-même si c'est l'ID du document
    };
  }
}