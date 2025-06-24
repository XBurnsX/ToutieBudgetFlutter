// lib/services/service_transfert_argent.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enveloppe_model.dart'; // Assurez-vous que ce chemin est correct

class ServiceTransfertArgent {
  final FirebaseFirestore _firestore;
  static const String idPretAPlacer = '--PRET-A-PLACER--';

  ServiceTransfertArgent(this._firestore);

  Future<double?> effectuerVirement({
    required String userId,
    required double montant,
    required String sourceId,
    EnveloppeModel? enveloppeSourceDetails, // Fourni si sourceId n'est pas idPretAPlacer
    required String destinationId,
    EnveloppeModel? enveloppeDestinationDetails, // Fourni si destinationId n'est pas idPretAPlacer
    required double soldePretAPlacerActuel,
    String? idCategorieSource, // Juste l'ID de la catégorie source
    String? idCategorieDestination, // Juste l'ID de la catégorie destination
  }) async {
    if (montant <= 0) {
      throw TransfertException("Le montant du virement doit être positif.");
    }
    if (sourceId == destinationId) {
      throw TransfertException(
          "La source et la destination doivent être différentes.");
    }

    // Pré-vérification des soldes (déjà faite dans l'UI, mais bonne pratique)
    if (sourceId == idPretAPlacer) {
      if (soldePretAPlacerActuel < montant) {
        throw TransfertException(
            "Solde 'Prêt à placer' insuffisant (service).");
      }
    } else {
      if (enveloppeSourceDetails == null) {
        throw TransfertException(
            "Détails de l'enveloppe source manquants pour l'ID $sourceId.");
      }
      if (enveloppeSourceDetails.montantAlloueActuellement < montant) {
        throw TransfertException(
            "Solde de l'enveloppe source '${enveloppeSourceDetails
                .nom}' insuffisant (service).");
      }
    }

    double nouveauSoldePretAPlacer = soldePretAPlacerActuel;
    bool pretAPlacerAEteModifie = false;

    await _firestore.runTransaction((transaction) async {
      // 1. Débiter la source
      if (sourceId == idPretAPlacer) {
        // La modification de nouveauSoldePretAPlacer se fait en dehors de la transaction
        // pour éviter les contentions si plusieurs transactions affectent PAP en même temps.
        // On marque juste qu'il doit être modifié.
      } else {
        // La source est une enveloppe
        if (enveloppeSourceDetails == null || idCategorieSource == null) {
          throw TransfertException(
              "Informations manquantes pour l'enveloppe source ID: $sourceId.");
        }
        final enveloppeSourceRef = _firestore
            .collection('users').doc(userId)
            .collection('categories').doc(
            idCategorieSource) // Utilise idCategorieSource
            .collection('enveloppes').doc(sourceId);

        final snapEnveloppeSource = await transaction.get(enveloppeSourceRef);
        if (!snapEnveloppeSource.exists) {
          throw TransfertException("Enveloppe source '${enveloppeSourceDetails
              .nom}' introuvable dans la transaction.");
        }
        EnveloppeModel enveloppeSourceTransaction = EnveloppeModel.fromSnapshot(
            snapEnveloppeSource as DocumentSnapshot<Map<String, dynamic>>);

        if (enveloppeSourceTransaction.montantAlloueActuellement < montant) {
          throw TransfertException(
              "Solde de l'enveloppe source '${enveloppeSourceDetails
                  .nom}' insuffisant (vérifié dans la transaction).");
        }
        transaction.update(enveloppeSourceRef, {
          'montantAlloueActuellement': enveloppeSourceTransaction
              .montantAlloueActuellement - montant,
          'derniereModification': Timestamp.now(),
        });
      }

      // 2. Créditer la destination
      if (destinationId == idPretAPlacer) {
        // Idem que pour la source PAP
      } else {
        // La destination est une enveloppe
        if (enveloppeDestinationDetails == null ||
            idCategorieDestination == null) {
          throw TransfertException(
              "Informations manquantes pour l'enveloppe destination ID: $destinationId.");
        }
        final enveloppeDestinationRef = _firestore
            .collection('users').doc(userId)
            .collection('categories').doc(
            idCategorieDestination) // Utilise idCategorieDestination
            .collection('enveloppes').doc(destinationId);

        final snapEnveloppeDestination = await transaction.get(
            enveloppeDestinationRef);
        if (!snapEnveloppeDestination.exists) {
          throw TransfertException(
              "Enveloppe destination '${enveloppeDestinationDetails
                  .nom}' introuvable dans la transaction.");
        }
        EnveloppeModel enveloppeDestinationTransaction = EnveloppeModel
            .fromSnapshot(
            snapEnveloppeDestination as DocumentSnapshot<Map<String, dynamic>>);

        transaction.update(enveloppeDestinationRef, {
          'montantAlloueActuellement': enveloppeDestinationTransaction
              .montantAlloueActuellement + montant,
          'derniereModification': Timestamp.now(),
        });
      }
    }); // Fin de la transaction Firestore

    // 3. Appliquer les modifications au solde Prêt à placer après la transaction réussie
    if (sourceId == idPretAPlacer) {
      nouveauSoldePretAPlacer -= montant;
      pretAPlacerAEteModifie = true;
    }
    if (destinationId == idPretAPlacer) {
      nouveauSoldePretAPlacer += montant;
      pretAPlacerAEteModifie = true;
    }

    // 4. Si Prêt à placer a été modifié, mettre à jour le solde global de l'utilisateur
    if (pretAPlacerAEteModifie) {
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.update({
        'soldePretAPlacerGlobal': nouveauSoldePretAPlacer,
        // Optionnel: 'derniereModificationVirementPAP': Timestamp.now(),
      });
      return nouveauSoldePretAPlacer; // Retourne le nouveau solde PAP
    }

    return null; // Retourne null si Prêt à placer n'a pas été affecté.
  }
}

class TransfertException implements Exception {
  final String message;

  TransfertException(this.message);

  @override
  String toString() => 'TransfertException: $message';
}