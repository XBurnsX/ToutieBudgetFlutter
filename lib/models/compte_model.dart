import 'package:flutter/material.dart'; // NÉCESSAIRE pour 'Color' et 'Colors'
import 'package:cloud_firestore/cloud_firestore.dart'; // Si vous utilisez Timestamp pour dateCreation

// Assurez-vous que votre enum TypeDeCompte est défini ici ou importé
enum TypeDeCompte {
  compteBancaire,
  credit, // Exemple, ajoutez tous vos types
  dette,
  investissement,
}

class Compte {
  final String id;
  final String nom;
  final TypeDeCompte type;
  double solde;
  final int couleurValue; // Stocke la valeur entière de la couleur
  // final DateTime? dateCreation; // Optionnel

  Compte({
    required this.id,
    required this.nom,
    required this.type,
    required this.solde,
    required this.couleurValue, // Assurez-vous que ce paramètre est requis
    // this.dateCreation,
  });

  // GETTER POUR 'couleur'
  Color get couleur => Color(couleurValue);

  // OPTIONNEL MAIS RECOMMANDÉ : Méthode toJson pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'type': type
          .toString()
          .split('.')
          .last,
      // Stocke l'enum comme une chaîne
      'soldeInitial': solde,
      // Ou ce qui est pertinent lors de la création
      'soldeActuel': solde,
      'couleurValue': couleurValue,
      'dateCreation': FieldValue.serverTimestamp(),
      // Pour utiliser le timestamp du serveur
    };
  }

  // OPTIONNEL MAIS RECOMMANDÉ : Factory constructor fromSnapshot pour la lecture
  factory Compte.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Gérer le cas où les données sont nulles, peut-être lever une exception
      // ou retourner un objet Compte avec des valeurs par défaut et un ID d'erreur.
      // Pour l'instant, nous supposons que les données sont toujours là si le document existe.
      throw Exception(
          "Données manquantes pour le document Compte avec ID: ${doc.id}");
    }

    return Compte(
      id: doc.id,
      nom: data['nom'] as String? ?? 'Nom inconnu',
      type: TypeDeCompte.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == (data['type'] as String?),
        orElse: () => TypeDeCompte.compteBancaire, // Valeur par défaut
      ),
      solde: (data['soldeActuel'] as num?)?.toDouble() ?? 0.0,
      // Lecture de la couleurValue et valeur par défaut si non trouvée
      couleurValue: data['couleurValue'] as int? ?? Colors.grey.value,
      // dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
    );
  }
}