class MonthlyCycle {
  final String id;
  final String messId;
  final int year;
  final int month; // 1 to 12
  final bool isClosed;
  final DateTime? closedAt;
  final DateTime createdAt;

  const MonthlyCycle({
    required this.id,
    required this.messId,
    required this.year,
    required this.month,
    this.isClosed = false,
    this.closedAt,
    required this.createdAt,
  });

  String get label => '$month/$year';

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'year': year,
    'month': month,
    'is_closed': isClosed,
    'closed_at': closedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory MonthlyCycle.fromJson(Map<String, dynamic> json) => MonthlyCycle(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    year: json['year'] as int,
    month: json['month'] as int,
    isClosed: json['is_closed'] as bool? ?? false,
    closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
