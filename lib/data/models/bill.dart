import '../../domain/calculations/bill_split_validator.dart';

class BillSplit {
  final String id;
  final String billId;
  final String memberId;
  final double amount;
  final String? memberName;

  const BillSplit({
    required this.id,
    required this.billId,
    required this.memberId,
    required this.amount,
    this.memberName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bill_id': billId,
    'member_id': memberId,
    'amount': amount,
  };

  factory BillSplit.fromJson(Map<String, dynamic> json) => BillSplit(
    id: json['id'] as String,
    billId: json['bill_id'] as String,
    memberId: json['member_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    memberName: json['profiles']?['name'] as String?,
  );
}

class Bill {
  final String id;
  final String messId;
  final String cycleId;
  final BillType billType;
  final String title;
  final double totalAmount;
  final String paidBy;
  final SplitMethod splitMethod;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;
  final String? paidByName;
  final List<BillSplit> splits;

  const Bill({
    required this.id,
    required this.messId,
    required this.cycleId,
    required this.billType,
    required this.title,
    required this.totalAmount,
    required this.paidBy,
    required this.splitMethod,
    this.dueDate,
    this.note,
    required this.createdAt,
    this.paidByName,
    this.splits = const [],
  });

  static BillType parseBillType(String typeStr) {
    switch (typeStr.toUpperCase()) {
      case 'RENT':
        return BillType.rent;
      case 'ELECTRICITY':
        return BillType.electricity;
      case 'WATER':
        return BillType.water;
      case 'HOUSEKEEPER':
        return BillType.housekeeper;
      case 'GAS':
        return BillType.gas;
      case 'INTERNET':
        return BillType.internet;
      default:
        return BillType.other;
    }
  }

  static String billTypeToString(BillType type) {
    switch (type) {
      case BillType.rent:
        return 'RENT';
      case BillType.electricity:
        return 'ELECTRICITY';
      case BillType.water:
        return 'WATER';
      case BillType.housekeeper:
        return 'HOUSEKEEPER';
      case BillType.gas:
        return 'GAS';
      case BillType.internet:
        return 'INTERNET';
      case BillType.other:
        return 'OTHER';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'cycle_id': cycleId,
    'bill_type': billTypeToString(billType),
    'title': title,
    'total_amount': totalAmount,
    'paid_by': paidBy,
    'split_method': splitMethod == SplitMethod.equal ? 'EQUAL' : 'CUSTOM',
    'due_date': dueDate?.toIso8601String().split('T')[0],
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory Bill.fromJson(Map<String, dynamic> json, {List<BillSplit> splits = const []}) => Bill(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    cycleId: json['cycle_id'] as String,
    billType: parseBillType(json['bill_type'] as String),
    title: json['title'] as String,
    totalAmount: (json['total_amount'] as num).toDouble(),
    paidBy: json['paid_by'] as String,
    splitMethod: (json['split_method'] as String?) == 'EQUAL' ? SplitMethod.equal : SplitMethod.custom,
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    paidByName: json['profiles']?['name'] as String?,
    splits: splits,
  );
}
