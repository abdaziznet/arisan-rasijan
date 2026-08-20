import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../providers/auth_providers.dart';
import '../../../../features/auth/domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _sendMagicLink() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).sendMagicLink(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthScreenState>(authControllerProvider, (_, state) {
      if (state is AuthMagicLinkSent) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.magicLinkSent,
          arguments: state.email,
        );
      } else if (state is AuthError) {
        AppSnackbar.show(context, state.message);
      }
    });

    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang di',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('BANI RASIJAN', style: AppTypography.display),
                    const SizedBox(height: AppSpacing.xs),
                    const Text('Arisan Keluarga', style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.xxxl),
                    const Text(
                      'Masuk dengan email',
                      style: AppTypography.h2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Kami akan mengirim magic link ke email Anda.',
                      style: AppTypography.body.copyWith(
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                      ),
                      validator: Validators.validateEmail,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _sendMagicLink(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Kirim Magic Link',
                      icon: Icons.mail_outline,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _sendMagicLink,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pushNamed(
                                  context,
                                  AppRouter.invite,
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
      ),
    );
  }
}
