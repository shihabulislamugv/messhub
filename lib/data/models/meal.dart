class MealEntry {
  final String id;
  final String messId;
  final String cycleId;
  final String memberId;
  final DateTime mealDate;
  final double breakfast;
  final double lunch;
  final double dinner;
  final DateTime createdAt;
  final String? memberName;

  const MealEntry({
    required this.id,
    required this.messId,
    required this.cycleId,
    required this.memberId,
    required this.mealDate,
    this.breakfast = 0.0,
    this.lunch = 0.0,
    this.dinner = 0.0,
    required this.createdAt,
    this.memberName,
  });

  double get dailyTotal => breakfast + lunch + dinner;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'cycle_id': cycleId,
    'member_id': memberId,
    'meal_date': mealDate.toIso8601String().split('T')[0],
    'breakfast': breakfast,
    'lunch': lunch,
    'dinner': dinner,
    'created_at': createdAt.toIso8601String(),
  };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    cycleId: json['cycle_id'] as String,
    memberId: json['member_id'] as String,
    mealDate: DateTime.parse(json['meal_date'] as String),
    breakfast: (json['breakfast'] as num?)?.toDouble() ?? 0.0,
    lunch: (json['lunch'] as num?)?.toDouble() ?? 0.0,
    dinner: (json['dinner'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.parse(json['created_at'] as String),
    memberName: json['profiles']?['name'] as String?,
  );

  MealEntry copyWith({
    double? breakfast,
    double? lunch,
    double? dinner,
  }) => MealEntry(
    id: id,
    messId: messId,
    cycleId: cycleId,
    memberId: memberId,
    mealDate: mealDate,
    breakfast: breakfast ?? this.breakfast,
    lunch: lunch ?? this.lunch,
    dinner: dinner ?? this.dinner,
    createdAt: createdAt,
    memberName: memberName,
  );
}

class SettlementRecord {
  final String id;
  final String messId;
  final String cycleId;
  final String senderId;
  final String receiverId;
  final double amount;
  final DateTime paymentDate;
  final String? note;
  final DateTime createdAt;
  final String? senderName;
  final String? receiverName;

  const SettlementRecord({
    required this.id,
    required this.messId,
    required this.cycleId,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.paymentDate,
    this.note,
    required this.createdAt,
    this.senderName,
    this.receiverName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'cycle_id': cycleId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'amount': amount,
    'payment_date': paymentDate.toIso8601String().split('T')[0],
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory SettlementRecord.fromJson(Map<String, dynamic> json) => SettlementRecord(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    cycleId: json['cycle_id'] as String,
    senderId: json['sender_id'] as String,
    receiverId: json['receiver_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    paymentDate: DateTime.parse(json['payment_date'] as String),
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    senderName: json['sender']?['name'] as String?,
    receiverName: json['receiver']?['name'] as String?,
  );
}
