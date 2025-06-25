// lib/services/service_transfert_argent.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Assurez-vous que ce chemin est correct

class ServiceTransfertArgent {
  final FirebaseFirestore _firestore;

  // Constante pour l'ID "Prêt à placer"
  // Assurez-vous qu'elle est définie et accessible
  static const String idPretAPlacer = "##PRET_A_PLACER##";

  ServiceTransfertArgent(this._firestore);

  Future<void> transfererArgent({
    required String utilisateurId,
    required String sourceId,
    required String destinationId,
    required double montant,
    required Map<String, dynamic> mapEnveloppes, // Ou Map<String, EnveloppeModel> si vous passez des modèles typés
    required Map<String, String> mapEnveloppeIdACategorieId,
    required bool sourceEstPretAPlacer,
    required bool destinationEstPretAPlacer,
  }) async {
    print("[ServiceTransfertArgent] Début du transfert.");
    print("  Utilisateur: $utilisateurId");
    print("  Source: $sourceId (estPrêtÀPlacer: $sourceEstPretAPlacer)");
    print("  Destination: $destinationId (estPrêtÀPlacer: $destinationEstPretAPlacer)");
    print("  Montant: $montant");

    if (montant <= 0) {
      throw Exception("Le montant du transfert doit être positif.");
    }
    if (sourceId == destinationId) {
      throw Exception("La source et la destination ne peuvent pas être identiques.");
    }

    // Récupérer la référence du document utilisateur
    final DocumentReference userDocRef = _firestore.collection('users').doc(utilisateurId);

    // Effectuer les opérations Firestore dans une transaction pour garantir l'atomicité
    await _firestore.runTransaction((transaction) async {
      // --- Logique pour la SOURCE ---
      if (sourceEstPretAPlacer) {
        print("[ServiceTransfertArgent] La source est 'Prêt à placer'.");
        // Lire la valeur actuelle de soldePretAPlacerGlobal
        DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
        if (!userSnapshot.exists || userSnapshot.data() == null) {
          throw Exception("Document utilisateur source introuvable pendant la transaction.");
        }
        num soldeActuelPap = (userSnapshot.data()! as Map<String, dynamic>)['soldePretAPlacerGlobal'] as num? ?? 0.0;

        if (soldeActuelPap < montant) {
          throw Exception("Solde 'Prêt à placer' insuffisant (actuel: $soldeActuelPap, demandé: $montant).");
        }
        transaction.update(userDocRef, {
          'soldePretAPlacerGlobal': FieldValue.increment(-montant),
        });
        print("[ServiceTransfertArgent] 'Prêt à placer' (source) mis à jour. Nouveau solde (théorique): ${soldeActuelPap - montant}");
      } else {
        // La source est une enveloppe normale
        print("[ServiceTransfertArgent] La source est une enveloppe normale : $sourceId.");
        String? categorieIdSource = mapEnveloppeIdACategorieId[sourceId];
        if (categorieIdSource == null) {
          throw Exception("Catégorie ID introuvable pour l'enveloppe source ID: $sourceId");
        }
        DocumentReference enveloppeSourceRef = userDocRef
            .collection('categories')
            .doc(categorieIdSource)
            .collection('enveloppes')
            .doc(sourceId);

        // Lire l'enveloppe source pour vérifier le solde
        DocumentSnapshot enveloppeSourceSnapshot = await transaction.get(enveloppeSourceRef);
        if (!enveloppeSourceSnapshot.exists || enveloppeSourceSnapshot.data() == null) {
          throw Exception("Enveloppe source ID '$sourceId' introuvable.");
        }
        num soldeActuelEnvSource = (enveloppeSourceSnapshot.data()! as Map<String, dynamic>)['montantAlloueActuellement'] as num? ?? 0.0;

        if (soldeActuelEnvSource < montant) {
          throw Exception("Solde insuffisant dans l'enveloppe source '${(enveloppeSourceSnapshot.data()! as Map<String, dynamic>)['nom'] ?? sourceId}' (actuel: $soldeActuelEnvSource, demandé: $montant).");
        }

        transaction.update(enveloppeSourceRef, {
          'montantAlloueActuellement': FieldValue.increment(-montant),
        });
        print("[ServiceTransfertArgent] Enveloppe source '$sourceId' mise à jour. Nouveau solde (théorique): ${soldeActuelEnvSource - montant}");
      }

      // --- Logique pour la DESTINATION ---
      if (destinationEstPretAPlacer) {
        print("[ServiceTransfertArgent] La destination est 'Prêt à placer'.");
        // Il n'est pas nécessaire de relire le document utilisateur si la source n'était pas "Prêt à placer"
        // car FieldValue.increment s'occupe de l'atomicité sur le champ.
        // Si la source ET la destination sont "Prêt à placer", les deux increments seront appliqués.
        transaction.update(userDocRef, {
          'soldePretAPlacerGlobal': FieldValue.increment(montant),
        });
        print("[ServiceTransfertArgent] 'Prêt à placer' (destination) mis à jour par +$montant.");
      } else {
        // La destination est une enveloppe normale
        print("[ServiceTransfertArgent] La destination est une enveloppe normale : $destinationId.");
        String? categorieIdDest = mapEnveloppeIdACategorieId[destinationId];
        if (categorieIdDest == null) {
          throw Exception("Catégorie ID introuvable pour l'enveloppe destination ID: $destinationId");
        }
        DocumentReference enveloppeDestinationRef = userDocRef
            .collection('categories')
            .doc(categorieIdDest)
            .collection('enveloppes')
            .doc(destinationId);

        // Il n'est pas nécessaire de lire l'enveloppe destination avant de mettre à jour
        // car FieldValue.increment gère cela.
        transaction.update(enveloppeDestinationRef, {
          'montantAlloueActuellement': FieldValue.increment(montant),
        });
        print("[ServiceTransfertArgent] Enveloppe destination '$destinationId' mise à jour par +$montant.");
      }
    });
    print("[ServiceTransfertArgent] Transaction de transfert terminée avec succès.");
  }
}

class TransfertException implements Exception {
  final String message;

  TransfertException(this.message);

  @override
  String toString() => 'TransfertException: $message';
}