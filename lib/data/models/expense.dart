import '../../domain/calculations/meal_rate_calculator.dart';

class BazarItem {
  final String id;
  final String? expenseId;
  final String itemName;
  final double quantity;
  final String unit; // 'kg', 'pcs', 'litre', 'gm'
  final double price;

  const BazarItem({
    required this.id,
    this.expenseId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'expense_id': expenseId,
    'item_name': itemName,
    'quantity': quantity,
    'unit': unit,
    'price': price,
  };

  factory BazarItem.fromJson(Map<String, dynamic> json) => BazarItem(
    id: json['id'] as String,
    expenseId: json['expense_id'] as String?,
    itemName: json['item_name'] as String,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    unit: json['unit'] as String? ?? 'pcs',
    price: (json['price'] as num).toDouble(),
  );
}

class Expense {
  final String id;
  final String messId;
  final String cycleId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final String paidBy;
  final DateTime expenseDate;
  final String? note;
  final String? receiptUrl;
  final DateTime createdAt;
  final String? paidByName;
  final List<BazarItem> bazarItems;

  const Expense({
    required this.id,
    required this.messId,
    required this.cycleId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.expenseDate,
    this.note,
    this.receiptUrl,
    required this.createdAt,
    this.paidByName,
    this.bazarItems = const [],
  });

  bool get isFoodOrBazar => category == ExpenseCategory.bazar || category == ExpenseCategory.food;

  static ExpenseCategory parseCategory(String catStr) {
    switch (catStr.toUpperCase()) {
      case 'BAZAR':
        return ExpenseCategory.bazar;
      case 'FOOD':
        return ExpenseCategory.food;
      case 'CLEANING':
        return ExpenseCategory.cleaning;
      case 'REPAIR':
        return ExpenseCategory.repair;
      case 'TRANSPORT':
        return ExpenseCategory.transport;
      default:
        return ExpenseCategory.other;
    }
  }

  static String categoryToString(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.bazar:
        return 'BAZAR';
      case ExpenseCategory.food:
        return 'FOOD';
      case ExpenseCategory.cleaning:
        return 'CLEANING';
      case ExpenseCategory.repair:
        return 'REPAIR';
      case ExpenseCategory.transport:
        return 'TRANSPORT';
      case ExpenseCategory.other:
        return 'OTHER';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'cycle_id': cycleId,
    'title': title,
    'amount': amount,
    'category': categoryToString(category),
    'paid_by': paidBy,
    'expense_date': expenseDate.toIso8601String().split('T')[0],
    'note': note,
    'receipt_url': receiptUrl,
    'created_at': createdAt.toIso8601String(),
  };

  factory Expense.fromJson(Map<String, dynamic> json, {List<BazarItem> items = const []}) => Expense(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    cycleId: json['cycle_id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: parseCategory(json['category'] as String),
    paidBy: json['paid_by'] as String,
    expenseDate: DateTime.parse(json['expense_date'] as String),
    note: json['note'] as String?,
    receiptUrl: json['receipt_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    paidByName: json['profiles']?['name'] as String?,
    bazarItems: items,
  );
}
