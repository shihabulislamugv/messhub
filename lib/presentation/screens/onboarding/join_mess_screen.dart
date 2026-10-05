import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_navigation_screen.dart';

class JoinMessScreen extends StatefulWidget {
  const JoinMessScreen({super.key});

  @override
  State<JoinMessScreen> createState() => _JoinMessScreenState();
}

class _JoinMessScreenState extends State<JoinMessScreen> {
  final _codeController = TextEditingController(text: 'MH8824');
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final messProvider = context.read<MessProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await messProvider.joinMess(inviteCode: code, userId: user.id);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined mess successfully!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else if (mounted) {
      setState(() => _error = 'Invalid invite code. Please check with your mess admin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('join_mess')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_add_outlined, color: AppColors.secondary, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Ask your Mess Admin or roommate for the 6-digit Invite Code.',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            CustomTextField(
              controller: _codeController,
              label: context.tr('invite_code'),
              hint: 'e.g. MH8824',
              prefixIcon: Icons.key_outlined,
            ),
            const SizedBox(height: 12),

            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: AppColors.negative, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 20),
            CustomButton(
              text: context.tr('join_mess'),
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              onPressed: _handleJoin,
            ),
          ],
        ),
      ),
    );
  }
}
