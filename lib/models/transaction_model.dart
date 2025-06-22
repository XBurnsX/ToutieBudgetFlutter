enum TypeTransaction { depense, revenu }

enum TypeMouvementFinancier {
  depenseNormale,
  revenuNormal,
  pretAccorde,
  remboursementRecu,
  detteContractee,
  remboursementEffectue,
}

extension TypeMouvementFinancierProperties on TypeMouvementFinancier {
  bool get estDepense {
    return [
      TypeMouvementFinancier.depenseNormale,
      TypeMouvementFinancier.pretAccorde,
      TypeMouvementFinancier.remboursementEffectue, // Un remboursement que vous faites est une dépense
    ].contains(this);
  }

  bool get estRevenu {
    return [
      TypeMouvementFinancier.revenuNormal,
      TypeMouvementFinancier.remboursementRecu, // Un remboursement que vous recevez est un revenu
      TypeMouvementFinancier.detteContractee,  // Une dette contractée est une entrée d'argent
      // TypeMouvementFinancier.perceptionRemboursementPret, // Si vous utilisez ce type aussi
    ].contains(this);
  }
}

class Transaction {
  final String id;
  final TypeTransaction type;
  final TypeMouvementFinancier typeMouvement;
  final double montant;
  final String tiers;
  final String compteId;
  final String? compteDePassifAssocie;
  final DateTime date;
  final String? enveloppeId;
  final String? marqueur;
  final String? note;

  Transaction({
    required this.id,
    required this.type,
    required this.typeMouvement,
    required this.montant,
    required this.tiers,
    required this.compteId,
    this.compteDePassifAssocie,
    required this.date,
    this.enveloppeId,
    this.marqueur,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'typeMouvement': typeMouvement.name,
      'montant': montant,
      'tiers': tiers,
      'compteId': compteId,
      'compteDePassifAssocie': compteDePassifAssocie,
      'date': date.toIso8601String(),
      'enveloppeId': enveloppeId,
      'marqueur': marqueur,
      'note': note,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: TypeTransaction.values.byName(json['type'] as String),
      typeMouvement: TypeMouvementFinancier.values.byName(json['typeMouvement'] as String),
      montant: json['montant'] as double,
      tiers: json['tiers'] as String,
      compteId: json['compteId'],
      compteDePassifAssocie: json['compteDePassifAssocie'],
      date: DateTime.parse(json['date'] as String),
      enveloppeId: json['enveloppeId'] as String?,
      marqueur: json['marqueur'] as String?,
      note: json['note'] as String?,
    );
  }
}