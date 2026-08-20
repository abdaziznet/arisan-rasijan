import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../providers/auth_providers.dart';

class InviteCodeScreen extends ConsumerStatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    super.dispose();
  }

  void _redeem() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).redeemInviteAndSendLink(
      code: _code.text,
      email: _email.text,
    );
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
      appBar: AppBar(title: const Text('Kode Undangan')),
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
                      'Bergabung dengan kode undangan',
                      style: AppTypography.h2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Masukkan kode undangan yang Anda terima dari admin keluarga.',
                      style: AppTypography.body.copyWith(
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _code,
                      decoration: const InputDecoration(
                        labelText: 'Kode Undangan',
                        hintText: 'Contoh: ABC12345',
                      ),
                      validator: Validators.validateInviteCode,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                      ),
                      validator: Validators.validateEmail,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _redeem(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Gunakan Kode',
                      icon: Icons.vpn_key_outlined,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _redeem,
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
