import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/calculations/bill_split_validator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  BillType _selectedType = BillType.rent;
  SplitMethod _splitMethod = SplitMethod.custom;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedPaidBy;
  DateTime? _dueDate;

  // Custom allocation controllers: memberId -> TextEditingController
  final Map<String, TextEditingController> _allocationControllers = {};
  bool _isLoading = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Basha Vara (House Rent)';
    // Default to Custom Split for Rent
    _splitMethod = SplitMethod.custom;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final messProvider = context.read<MessProvider>();
    final auth = context.read<AuthProvider>();

    _selectedPaidBy ??= auth.currentUser?.id ?? (messProvider.memberIds.isNotEmpty ? messProvider.memberIds.first : null);

    for (final id in messProvider.memberIds) {
      if (!_allocationControllers.containsKey(id)) {
        _allocationControllers[id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final ctrl in _allocationControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onBillTypeChanged(BillType type) {
    setState(() {
      _selectedType = type;
      // Auto-set reasonable default titles
      switch (type) {
        case BillType.rent:
          _titleController.text = 'Basha Vara (House Rent)';
          _splitMethod = SplitMethod.custom; // MANDATORY: Rent only supports Custom Split!
          break;
        case BillType.electricity:
          _titleController.text = 'Electricity Bill';
          break;
        case BillType.water:
          _titleController.text = 'Pani (Water) Bill';
          break;
        case BillType.housekeeper:
          _titleController.text = 'Bua (Housekeeper) Bill';
          break;
        case BillType.gas:
          _titleController.text = 'Gas Bill';
          break;
        case BillType.internet:
          _titleController.text = 'Internet / Wi-Fi Bill';
          break;
        case BillType.other:
          _titleController.text = 'Other Bill';
          break;
      }
      _validationError = null;
    });
  }

  double _getCustomAllocationsSum() {
    double sum = 0.0;
    for (final ctrl in _allocationControllers.values) {
      final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
      sum += val;
    }
    return sum;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (totalAmount <= 0) {
      setState(() => _validationError = context.tr('enter_valid_amount'));
      return;
    }

    final messProvider = context.read<MessProvider>();
    Map<String, double>? customAllocations;

    if (_splitMethod == SplitMethod.custom) {
      customAllocations = {};
      for (final id in messProvider.memberIds) {
        final ctrl = _allocationControllers[id];
        final val = double.tryParse(ctrl?.text.trim() ?? '') ?? 0.0;
        customAllocations[id] = val;
      }

      // Check sum equality
      final allocatedSum = customAllocations.values.fold<double>(0.0, (s, a) => s + a);
      if ((allocatedSum - totalAmount).abs() > 0.01) {
        setState(() {
          _validationError = '${context.tr("validation_custom_mismatch")} (Allocated: ৳${allocatedSum.toStringAsFixed(2)}, Total: ৳${totalAmount.toStringAsFixed(2)})';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _validationError = null;
    });

    final result = await messProvider.addBill(
      billType: _selectedType,
      title: _titleController.text.trim(),
      totalAmount: totalAmount,
      paidBy: _selectedPaidBy ?? messProvider.memberIds.first,
      splitMethod: _splitMethod,
      customAllocations: customAllocations,
      dueDate: _dueDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill added successfully!')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      setState(() => _validationError = result.errorMessage ?? 'Failed to save bill.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final members = messProvider.members;
    final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isRent = _selectedType == BillType.rent;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('add_bill')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // STEP 1: Select Bill Type
            Text(
              '1. ${context.tr("category")}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: BillType.values.map((type) {
                  final isSelected = _selectedType == type;
                  String label;
                  switch (type) {
                    case BillType.rent:
                      label = context.tr('basha_vara');
                      break;
                    case BillType.electricity:
                      label = context.tr('electricity');
                      break;
                    case BillType.water:
                      label = context.tr('pani');
                      break;
                    case BillType.housekeeper:
                      label = context.tr('bua');
                      break;
                    case BillType.gas:
                      label = context.tr('gas');
                      break;
                    case BillType.internet:
                      label = context.tr('internet');
                      break;
                    case BillType.other:
                      label = context.tr('other_bill');
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => _onBillTypeChanged(type),
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // STEP 2: Bill Details
            Text(
              '2. Bill Information',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _titleController,
              label: 'Bill Title',
              hint: 'e.g. March 2027 House Rent',
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _amountController,
              label: '${context.tr("amount")} (৳)',
              hint: 'e.g. 15000',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_lira,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final val = double.tryParse(v?.trim() ?? '');
                if (val == null || val <= 0) return context.tr('enter_valid_amount');
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Paid By dropdown
            const Text(
              'Paid by',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                  hint: const Text('Select member who paid'),
                  items: members.map((m) {
                    return DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.userName ?? 'Member', style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPaidBy = val),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _noteController,
              label: context.tr('note'),
              hint: 'Optional notes...',
            ),
            const SizedBox(height: 24),

            // STEP 3: Split Method (CRITICAL BUSINESS RULE ENFORCEMENT)
            Text(
              '3. ${context.tr("split_method")}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            if (isRent) ...[
              // Basha Vara MUST ONLY show Custom Split
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8B4FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF7E22CE), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('custom_split_mandatory_note'),
                        style: const TextStyle(
                          color: Color(0xFF581C87),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SegmentedButton<SplitMethod>(
                segments: [
                  ButtonSegment(value: SplitMethod.equal, label: Text(context.tr('equal_split'))),
                  ButtonSegment(value: SplitMethod.custom, label: Text(context.tr('custom_split'))),
                ],
                selected: {_splitMethod},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) setState(() => _splitMethod = set.first);
                },
              ),
            ],
            const SizedBox(height: 20),

            // STEP 4: Member Allocations
            Text(
              '4. ${context.tr("member_shares")}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (_splitMethod == SplitMethod.equal && !isRent) ...[
              // Equal Split Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: members.map((m) {
                    final share = members.isNotEmpty ? totalAmount / members.length : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.userName ?? 'Member', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(
                            CurrencyFormatter.format(share),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              // Custom Split Form Inputs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ...members.map((m) {
                      final ctrl = _allocationControllers[m.userId] ?? TextEditingController();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                m.userName ?? 'Member',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  prefixText: '৳ ',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                  hintText: '0',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Allocated Total:',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          CurrencyFormatter.format(_getCustomAllocationsSum()),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: (_getCustomAllocationsSum() - totalAmount).abs() <= 0.01
                                ? AppColors.positive
                                : AppColors.negative,
                          ),
                        ),
                      ],
                    ),
                    if (totalAmount > 0 && (_getCustomAllocationsSum() - totalAmount).abs() > 0.01) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Difference: ৳${(totalAmount - _getCustomAllocationsSum()).toStringAsFixed(2)} remaining',
                        style: const TextStyle(color: AppColors.negative, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Validation Error Alert
            if (_validationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.negativeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.negative.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.negative, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: AppColors.negative, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
            CustomButton(
              text: context.tr('save'),
              icon: Icons.check_circle_outline,
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
