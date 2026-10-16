// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

enum PaymentMethod {
  cash,
  transfer,
}

class Payment {
  final String id;
  final String periodId;
  final String memberId;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime paidAt;
  final String recordedBy;
  final double allocatedToFund; // Amount allocated to fund gathering

  Payment({
    required this.id,
    required this.periodId,
    required this.memberId,
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    required this.recordedBy,
    required this.allocatedToFund,
  });

  Payment copyWith({
    String? id,
    String? periodId,
    String? memberId,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? paidAt,
    String? recordedBy,
    double? allocatedToFund,
  }) {
    return Payment(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      recordedBy: recordedBy ?? this.recordedBy,
      allocatedToFund: allocatedToFund ?? this.allocatedToFund,
    );
  }

  Map<String, dynamic> toMap({String? recordedBy}) {
    return <String, dynamic>{
      'id': id,
      'period_id': periodId,
      'member_id': memberId,
      'amount': amount,
      'payment_method': paymentMethod.name,
      'paid_at': paidAt.toIso8601String(),
      'allocated_to_fund': allocatedToFund,
      if (recordedBy != null) 'recorded_by': recordedBy,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      periodId: map['period_id'] as String,
      memberId: map['member_id'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.values
          .byName(map['payment_method'] as String? ?? 'cash'),
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : DateTime.now(),
      recordedBy: map['recorded_by'] as String? ?? '',
      allocatedToFund: (map['allocated_to_fund'] as num?)?.toDouble() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Payment.fromJson(String source) =>
      Payment.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Payment(id: $id, periodId: $periodId, memberId: $memberId, amount: $amount, paymentMethod: $paymentMethod, paidAt: $paidAt, recordedBy: $recordedBy, allocatedToFund: $allocatedToFund)';
  }

  @override
  bool operator ==(covariant Payment other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.periodId == periodId &&
        other.memberId == memberId &&
        other.amount == amount &&
        other.paymentMethod == paymentMethod &&
        other.paidAt == paidAt &&
        other.recordedBy == recordedBy &&
        other.allocatedToFund == allocatedToFund;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        periodId.hashCode ^
        memberId.hashCode ^
        amount.hashCode ^
        paymentMethod.hashCode ^
        paidAt.hashCode ^
        recordedBy.hashCode ^
        allocatedToFund.hashCode;
  }
}

class Donation {
  final String id;
  final String periodId;
  final String? memberId;
  final double amount;
  final String? notes;
  final DateTime donatedAt;
  final String? paymentMethod;
  final String status;
  final int? uniqueCode;
  final double? paymentAmount;
  final double? receivedAmount;
  final String? paymentReference;
  final String? paymentProofPath;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNote;

  Donation({
    required this.id,
    required this.periodId,
    this.memberId,
    required this.amount,
    this.notes,
    required this.donatedAt,
    this.paymentMethod,
    this.status = 'verified',
    this.uniqueCode,
    this.paymentAmount,
    this.receivedAmount,
    this.paymentReference,
    this.paymentProofPath,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNote,
  });

  Donation copyWith({
    String? id,
    String? periodId,
    String? memberId,
    double? amount,
    String? notes,
    DateTime? donatedAt,
    String? paymentMethod,
    String? status,
    int? uniqueCode,
    double? paymentAmount,
    double? receivedAmount,
    String? paymentReference,
    String? paymentProofPath,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? verificationNote,
  }) {
    return Donation(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      donatedAt: donatedAt ?? this.donatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentProofPath: paymentProofPath ?? this.paymentProofPath,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }

  Map<String, dynamic> toMap({String? paymentMethod, String? status}) {
    return <String, dynamic>{
      'period_id': periodId,
      'member_id': memberId,
      'amount': amount,
      'note': notes,
      'created_at': donatedAt.toIso8601String(),
      if ((paymentMethod ?? this.paymentMethod) != null)
        'payment_method': paymentMethod ?? this.paymentMethod,
      if (status != null) 'status': status,
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id'] as String,
      periodId: map['period_id'] as String,
      memberId: map['member_id'] != null ? map['member_id'] as String : null,
      amount: (map['amount'] as num).toDouble(),
      notes: map['note'] != null ? map['note'] as String : null,
      donatedAt: DateTime.parse(map['created_at'] as String),
      paymentMethod: map['payment_method'] as String?,
      status: map['status'] as String? ?? 'verified',
      uniqueCode: (map['unique_code'] as num?)?.toInt(),
      paymentAmount: (map['payment_amount'] as num?)?.toDouble(),
      receivedAmount: (map['received_amount'] as num?)?.toDouble(),
      paymentReference: map['payment_reference'] as String?,
      paymentProofPath: map['payment_proof_path'] as String?,
      verifiedBy: map['verified_by'] as String?,
      verifiedAt: map['verified_at'] == null
          ? null
          : DateTime.tryParse(map['verified_at'].toString()),
      verificationNote: map['verification_note'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Donation.fromJson(String source) =>
      Donation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Donation(id: $id, periodId: $periodId, memberId: $memberId, amount: $amount, paymentMethod: $paymentMethod, status: $status, uniqueCode: $uniqueCode, paymentAmount: $paymentAmount)';
  }

  @override
  bool operator ==(covariant Donation other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.periodId == periodId &&
        other.memberId == memberId &&
        other.amount == amount &&
        other.notes == notes &&
        other.donatedAt == donatedAt &&
        other.paymentMethod == paymentMethod &&
        other.status == status &&
        other.uniqueCode == uniqueCode &&
        other.paymentAmount == paymentAmount &&
        other.receivedAmount == receivedAmount &&
        other.paymentReference == paymentReference &&
        other.paymentProofPath == paymentProofPath &&
        other.verifiedBy == verifiedBy &&
        other.verifiedAt == verifiedAt &&
        other.verificationNote == verificationNote;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        periodId.hashCode ^
        memberId.hashCode ^
        amount.hashCode ^
        notes.hashCode ^
        donatedAt.hashCode ^
        paymentMethod.hashCode ^
        status.hashCode ^
        uniqueCode.hashCode ^
        paymentAmount.hashCode ^
        receivedAmount.hashCode ^
        paymentReference.hashCode ^
        paymentProofPath.hashCode ^
        verifiedBy.hashCode ^
        verifiedAt.hashCode ^
        verificationNote.hashCode;
  }
}

class DonationPaymentSettings {
  const DonationPaymentSettings({
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.qrisImagePath,
    this.paymentInstructions,
  });

  factory DonationPaymentSettings.fromMap(Map<String, dynamic> map) =>
      DonationPaymentSettings(
        bankName: map['bank_name'] as String?,
        bankAccountName: map['bank_account_name'] as String?,
        bankAccountNumber: map['bank_account_number'] as String?,
        qrisImagePath: map['qris_image_path'] as String?,
        paymentInstructions: map['payment_instructions'] as String?,
      );

  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? qrisImagePath;
  final String? paymentInstructions;
}

class FundLedgerEntry {
  final String id;
  final String? periodId;
  final String description;
  final double amount;
  final DateTime transactionDate;
  FundLedgerEntry({
    required this.id,
    this.periodId,
    required this.description,
    required this.amount,
    required this.transactionDate,
  });

  FundLedgerEntry copyWith({
    String? id,
    String? periodId,
    String? description,
    double? amount,
    DateTime? transactionDate,
  }) {
    return FundLedgerEntry(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'period_id': periodId,
      'description': description,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }

  factory FundLedgerEntry.fromMap(Map<String, dynamic> map) {
    return FundLedgerEntry(
      id: map['id'] as String,
      periodId: map['period_id'] != null ? map['period_id'] as String : null,
      description: map['description'] as String,
      amount: map['amount'] as double,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory FundLedgerEntry.fromJson(String source) =>
      FundLedgerEntry.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FundLedgerEntry(id: $id, periodId: $periodId, description: $description, amount: $amount, transactionDate: $transactionDate)';
  }

  @override
  bool operator ==(covariant FundLedgerEntry other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.periodId == periodId &&
        other.description == description &&
        other.amount == amount &&
        other.transactionDate == transactionDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        periodId.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        transactionDate.hashCode;
  }
}

/// Status pembayaran anggota untuk satu periode (gabungan data profiles + payments).
class MemberPaymentStatus {
  final String memberId;
  final String fullName;
  final String? photoUrl;
  final bool isPaid;
  final double? amount;
  final String? paymentMethod;
  final DateTime? paidAt;

  const MemberPaymentStatus({
    required this.memberId,
    required this.fullName,
    this.photoUrl,
    required this.isPaid,
    this.amount,
    this.paymentMethod,
    this.paidAt,
  });
}
