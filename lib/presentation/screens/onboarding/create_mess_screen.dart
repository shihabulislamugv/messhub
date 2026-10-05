import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_navigation_screen.dart';
import 'join_mess_screen.dart';

class CreateMessScreen extends StatefulWidget {
  const CreateMessScreen({super.key});

  @override
  State<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends State<CreateMessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Swapno Neer (স্বপ্ন নীড়)');
  final _areaController = TextEditingController(text: 'Mirpur-2, Dhaka');
  final _cycleDayController = TextEditingController(text: '1');
  final _descController = TextEditingController(text: 'Bachelor mess for shared accommodation');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _cycleDayController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final messProvider = context.read<MessProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final success = await messProvider.createMess(
      name: _nameController.text.trim(),
      area: _areaController.text.trim(),
      cycleStartDay: int.tryParse(_cycleDayController.text.trim()) ?? 1,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      creatorId: user.id,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('create_mess')),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinMessScreen()),
            ),
            child: Text(context.tr('join_mess'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.maps_home_work_outlined, color: AppColors.primary, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup your Mess or Shared Flat',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'You will be the Admin and can invite other roommates.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _nameController,
                  label: context.tr('mess_name'),
                  hint: 'e.g. Uttara Bachelor Mess, Flat 4B',
                  prefixIcon: Icons.apartment,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter mess name' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _areaController,
                  label: context.tr('area_location'),
                  hint: 'e.g. Mirpur-2, Dhanmondi, Tilagarh',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter area/location' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _cycleDayController,
                  label: context.tr('cycle_start_day'),
                  hint: '1',
                  prefixIcon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final day = int.tryParse(v?.trim() ?? '');
                    if (day == null || day < 1 || day > 28) return 'Enter day between 1 and 28';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _descController,
                  label: 'Description (optional)',
                  hint: 'Room rules, notes, or details...',
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: context.tr('create_mess'),
                  icon: Icons.check,
                  isLoading: _isLoading,
                  onPressed: _handleCreate,
                ),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinMessScreen()),
                  ),
                  child: Text('Already have an Invite Code? ${context.tr("join_mess")}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
