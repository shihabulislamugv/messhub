import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/calculations/meal_rate_calculator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  String? _selectedPaidBy;
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;

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
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final messProvider = context.read<MessProvider>();
    setState(() => _isLoading = true);

    await messProvider.addExpense(
      title: _titleController.text.trim(),
      amount: amount,
      category: _category,
      paidBy: _selectedPaidBy ?? messProvider.memberIds.first,
      expenseDate: _expenseDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final members = messProvider.members;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('add_expense')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Expense Title',
              hint: 'e.g. Floor Cleaner, Gas transport, Emergency spices',
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _amountController,
              label: '${context.tr("amount")} (৳)',
              hint: 'e.g. 450',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_lira,
              validator: (v) {
                final val = double.tryParse(v?.trim() ?? '');
                if (val == null || val <= 0) return context.tr('enter_valid_amount');
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Category Selection
            Text(
              context.tr('category'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _category == cat;
                String label;
                switch (cat) {
                  case ExpenseCategory.bazar:
                    label = context.tr('bazar');
                    break;
                  case ExpenseCategory.food:
                    label = context.tr('food');
                    break;
                  case ExpenseCategory.cleaning:
                    label = context.tr('cleaning');
                    break;
                  case ExpenseCategory.repair:
                    label = context.tr('repair');
                    break;
                  case ExpenseCategory.transport:
                    label = context.tr('transport');
                    break;
                  case ExpenseCategory.other:
                    label = 'Other';
                    break;
                }

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Paid By dropdown
            Text(
              context.tr('paid_by'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaidBy,
                  isExpanded: true,
                  hint: const Text('Select who paid'),
                  items: members.map((m) {
                    return DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.userName ?? 'Member'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPaidBy = val),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expense Date picker
            Text(
              context.tr('date'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expenseDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _expenseDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatShortDate(_expenseDate),
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _noteController,
              label: context.tr('note'),
              hint: 'Optional notes...',
            ),
            const SizedBox(height: 28),

            CustomButton(
              text: context.tr('save'),
              icon: Icons.check_circle_outline,
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
