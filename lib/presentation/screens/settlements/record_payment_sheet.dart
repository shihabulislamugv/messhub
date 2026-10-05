import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({super.key});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(text: 'Paid via bKash / Nagad');

  String? _selectedSender;
  String? _selectedReceiver;
  final DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final messProvider = context.read<MessProvider>();
    final ids = messProvider.memberIds;
    if (ids.length >= 2) {
      _selectedSender ??= ids[1];
      _selectedReceiver ??= ids[0];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || _selectedSender == null || _selectedReceiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and select members.')),
      );
      return;
    }

    if (_selectedSender == _selectedReceiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sender and receiver cannot be the same person.')),
      );
      return;
    }

    final messProvider = context.read<MessProvider>();
    setState(() => _isLoading = true);

    await messProvider.recordPayment(
      senderId: _selectedSender!,
      receiverId: _selectedReceiver!,
      amount: amount,
      paymentDate: _paymentDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement payment recorded successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final members = messProvider.members;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('record_payment'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // Sender Dropdown
          Text(context.tr('sender'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSender,
                isExpanded: true,
                items: members.map((m) {
                  return DropdownMenuItem(value: m.userId, child: Text(m.userName ?? 'Member'));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSender = val),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Receiver Dropdown
          Text(context.tr('receiver'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReceiver,
                isExpanded: true,
                items: members.map((m) {
                  return DropdownMenuItem(value: m.userId, child: Text(m.userName ?? 'Member'));
                }).toList(),
                onChanged: (val) => setState(() => _selectedReceiver = val),
              ),
            ),
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _amountController,
            label: '${context.tr("amount")} (৳)',
            hint: 'e.g. 600',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_lira,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _noteController,
            label: context.tr('note'),
            hint: 'e.g. Paid via bKash / Cash',
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: context.tr('save'),
            icon: Icons.check_circle_outline,
            isLoading: _isLoading,
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }
}
