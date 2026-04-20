import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/repositories.dart';
import '../../core/utils/router.dart';
import '../../core/widgets/shared_widgets.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _resending = false;
  bool _checking = false;
  bool _resentOk = false;
  String? _error;

  // Cooldown kirim ulang 60 detik
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown--);
      }
    });
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
      _resentOk = false;
    });
    try {
      await AuthRepository().resendVerification();
      if (mounted) {
        setState(() => _resentOk = true);
        _startCooldown();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final verified = await AuthRepository().checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        ref.read(authStateProvider.notifier).state = true;
        context.go('/dashboard');
      } else {
        setState(() => _error =
            'Email belum diverifikasi. Cek inbox atau folder spam kamu.');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout() async {
    await AuthRepository().logout();
    if (mounted) {
      ref.read(authStateProvider.notifier).state = false;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        FinaColors.copper.withOpacity(0.2),
                        FinaColors.copper2.withOpacity(0.1),
                      ],
                    ),
                    border:
                        Border.all(color: FinaColors.copper.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 38,
                    color: FinaColors.copper,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: ShaderMask(
                  shaderCallback: (b) => kCopperGradient.createShader(b),
                  child: const Text(
                    'Verifikasi Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Kami telah mengirim link verifikasi ke',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FinaColors.text2,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.email,
                  style: const TextStyle(
                    color: FinaColors.copper,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Buka email tersebut dan klik link verifikasi,\nlalu kembali ke sini.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinaColors.text2,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // ── Error / Success banner ───────────────────────────────────
              if (_error != null) ...[
                FinaCard(
                  copper: true,
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: FinaColors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: FinaColors.red, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              if (_resentOk && _error == null) ...[
                FinaCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: FinaColors.green, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Email verifikasi berhasil dikirim ulang!',
                          style:
                              TextStyle(color: FinaColors.green, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Tombol sudah verifikasi ──────────────────────────────────
              FinaButton(
                label: 'Saya Sudah Verifikasi',
                onPressed: _checkVerified,
                isLoading: _checking,
              ),
              const SizedBox(height: 12),

              // ── Tombol kirim ulang ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (_cooldown > 0 || _resending) ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _cooldown > 0
                          ? FinaColors.border
                          : FinaColors.copper.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FinaColors.copper,
                          ),
                        )
                      : Text(
                          _cooldown > 0
                              ? 'Kirim Ulang (${_cooldown}s)'
                              : 'Kirim Ulang Email',
                          style: TextStyle(
                            color: _cooldown > 0
                                ? FinaColors.text2
                                : FinaColors.copper,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Divider ──────────────────────────────────────────────────
              Row(children: [
                const Expanded(child: Divider(color: FinaColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('atau',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: FinaColors.text2,
                          )),
                ),
                const Expanded(child: Divider(color: FinaColors.border)),
              ]),

              const SizedBox(height: 24),

              // ── Logout ───────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _logout,
                  child: Text(
                    'Kembali ke halaman login',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FinaColors.text2,
                          decoration: TextDecoration.underline,
                          decorationColor: FinaColors.text2,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
