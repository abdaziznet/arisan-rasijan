import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../members/domain/member_model.dart';
import '../../domain/draw_model.dart';
import '../providers/draw_providers.dart';
import '../widgets/winner_reveal_dialog.dart';

class DrawAnimationScreen extends ConsumerStatefulWidget {
  const DrawAnimationScreen({
    super.key,
    required this.periodId,
    required this.candidates,
  });

  final String periodId;
  final List<MemberModel> candidates;

  @override
  ConsumerState<DrawAnimationScreen> createState() => _DrawAnimationScreenState();
}

class _DrawAnimationScreenState extends ConsumerState<DrawAnimationScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _currentIndex = 0;
  int _countdown = 3;
  bool _isFinished = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startSpinning();

    // Mulai panggil API runDraw segera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(drawControllerProvider.notifier).runDraw(widget.periodId);
    });
  }

  void _startSpinning() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = Random().nextInt(widget.candidates.length);
      });
    });

    // Countdown timer
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          timer.cancel();
          _checkResult();
        }
      });
    });
  }

  void _checkResult() {
    // Tunggu sampai drawController punya data (API selesai)
    final state = ref.read(drawControllerProvider);
    if (state.hasValue && state.value != null) {
      _finishAnimation(state.value!);
    } else if (state.hasError) {
      // Jika API error, kembali dan tunjukkan pesan
      _timer.cancel();
      Navigator.pop(context); // kembali ke DrawScreen, state.error ditangani di sana
    } else {
      // API masih berjalan, tunggu 500ms lalu cek lagi
      Future.delayed(const Duration(milliseconds: 500), _checkResult);
    }
  }

  void _finishAnimation(DrawModel result) {
    if (!mounted) return;
    _timer.cancel();
    setState(() {
      _isFinished = true;
      // Set nama ke pemenang asli
      _currentIndex = widget.candidates.indexWhere((c) => c.id == result.winnerId);
      if (_currentIndex == -1) _currentIndex = 0; // fallback
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      // Ganti screen ini dengan dialog winner (biar animasi screen hilang)
      Navigator.pop(context);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WinnerRevealDialog(draw: result),
      );
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidates.isEmpty
      ? null
      : widget.candidates[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.casino_rounded, size: 64, color: AppColors.accent),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  _isFinished ? 'MENETAPKAN PEMENANG...' : 'MENGOCOK...',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.05).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: candidate != null
                      ? Text(
                          candidate.fullName,
                          style: AppTypography.display.copyWith(color: AppColors.primary),
                          textAlign: TextAlign.center,
                        )
                      : const CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (!_isFinished) ...[
                  Text(
                    '$_countdown',
                    style: AppTypography.display.copyWith(
                      color: AppColors.accent,
                      fontSize: 72,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
