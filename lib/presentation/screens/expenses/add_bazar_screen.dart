import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/expense.dart';
import '../../../domain/calculations/meal_rate_calculator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class _BazarItemRow {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController priceCtrl = TextEditingController();
  String unit = 'kg';

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class AddBazarScreen extends StatefulWidget {
  const AddBazarScreen({super.key});

  @override
  State<AddBazarScreen> createState() => _AddBazarScreenState();
}

class _AddBazarScreenState extends State<AddBazarScreen> {
  final _titleController = TextEditingController(text: 'Daily / Weekly Bazar');
  final _noteController = TextEditingController();
  final List<_BazarItemRow> _itemRows = [];

  String? _selectedPaidBy;
  DateTime _bazarDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 initial item rows
    _addNewItem(name: 'Miniket Rice', qty: '5', unit: 'kg', price: '350');
    _addNewItem(name: 'Farm Eggs', qty: '12', unit: 'pcs', price: '150');
    _addNewItem(name: 'Fresh Vegetables', qty: '1', unit: 'pack', price: '280');
  }

  void _addNewItem({String name = '', String qty = '1', String unit = 'kg', String price = ''}) {
    final row = _BazarItemRow();
    row.nameCtrl.text = name;
    row.qtyCtrl.text = qty;
    row.unit = unit;
    row.priceCtrl.text = price;
    row.priceCtrl.addListener(() => setState(() {}));
    setState(() => _itemRows.add(row));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final messProvider = context.read<MessProvider>();
    final auth = context.read<AuthProvider>();
    _selectedPaidBy ??= auth.currentUser?.id ?? (messProvider.memberIds.isNotEmpty ? messProvider.memberIds.first : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  double _calculateTotalBazar() {
    double sum = 0.0;
    for (final row in _itemRows) {
      final p = double.tryParse(row.priceCtrl.text.trim()) ?? 0.0;
      sum += p;
    }
    return sum;
  }

  Future<void> _handleSave() async {
    final total = _calculateTotalBazar();
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one bazar item with price.')),
      );
      return;
    }

    final messProvider = context.read<MessProvider>();
    setState(() => _isLoading = true);

    final bazarItems = <BazarItem>[];
    for (int i = 0; i < _itemRows.length; i++) {
      final row = _itemRows[i];
      final price = double.tryParse(row.priceCtrl.text.trim()) ?? 0.0;
      if (price > 0 && row.nameCtrl.text.trim().isNotEmpty) {
        bazarItems.add(
          BazarItem(
            id: 'bazar_${DateTime.now().millisecondsSinceEpoch}_$i',
            itemName: row.nameCtrl.text.trim(),
            quantity: double.tryParse(row.qtyCtrl.text.trim()) ?? 1.0,
            unit: row.unit,
            price: price,
          ),
        );
      }
    }

    await messProvider.addExpense(
      title: _titleController.text.trim().isEmpty ? 'Bazar' : _titleController.text.trim(),
      amount: total,
      category: ExpenseCategory.bazar,
      paidBy: _selectedPaidBy ?? messProvider.memberIds.first,
      expenseDate: _bazarDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      bazarItems: bazarItems,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bazar recorded! Total: ৳${total.toStringAsFixed(0)}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final members = messProvider.members;
    final total = _calculateTotalBazar();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bazar Items'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomTextField(
            controller: _titleController,
            label: 'Bazar Title',
            hint: 'e.g. Weekly Bazar, Morning Fish Bazar',
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('paid_by'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaidBy,
                          isExpanded: true,
                          items: members.map((m) {
                            return DropdownMenuItem(
                              value: m.userId,
                              child: Text(m.userName ?? 'Member', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedPaidBy = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('date'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _bazarDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _bazarDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          DateFormatter.formatShortDate(_bazarDate),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Bazar Highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Bazar:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                ),
                Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('bazar_items'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => _addNewItem(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dynamic Item rows
          ...List.generate(_itemRows.length, (i) {
            final row = _itemRows[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: row.nameCtrl,
                          decoration: InputDecoration(
                            hintText: 'Item (e.g. Rice, Egg, Fish)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.negative),
                        onPressed: () {
                          if (_itemRows.length > 1) {
                            setState(() {
                              final removed = _itemRows.removeAt(i);
                              removed.dispose();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: row.qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: row.unit,
                          isDense: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                            DropdownMenuItem(value: 'litre', child: Text('litre')),
                            DropdownMenuItem(value: 'gm', child: Text('gm')),
                            DropdownMenuItem(value: 'pack', child: Text('pack')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => row.unit = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: row.priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '৳ ',
                            hintText: 'Price',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
          CustomButton(
            text: context.tr('save'),
            icon: Icons.check_circle_outline,
            isLoading: _isLoading,
            onPressed: _handleSave,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
