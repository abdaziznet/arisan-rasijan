import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../../../routing/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    if (_email.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Masukkan email Anda terlebih dahulu.');
      return;
    }
    Navigator.pushReplacementNamed(context, AppRouter.home);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selamat datang di', style: AppTypography.bodyLarge),
                const SizedBox(height: AppSpacing.sm),
                const Text('BANI RASIJAN', style: AppTypography.display),
                const SizedBox(height: AppSpacing.xs),
                const Text('Arisan Keluarga', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.xxxl),
                const Text('Masuk dengan email', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kami akan mengirim kode atau magic link ke email Anda.',
                  style: AppTypography.body.copyWith(color: Colors.blueGrey),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email',
                  hintText: 'nama@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Kirim Kode / Magic Link',
                  icon: Icons.mail_outline,
                  onPressed: _continue,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => AppSnackbar.show(
                      context,
                      'Fitur kode undangan menunggu kontrak database.',
                    ),
                    child: const Text(
                      'Belum bergabung? Gunakan kode undangan.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
