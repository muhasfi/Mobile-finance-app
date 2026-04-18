import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/router.dart';
import '../../core/widgets/shared_widgets.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String? email;
  const OtpVerifyScreen({super.key, this.email});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final List<TextEditingController> _ctrs =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool    _loading   = false;
  String? _error;
  int     _countdown = 60;
  Timer?  _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _ctrs) c.dispose();
    for (final f in _nodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  String get _otp => _ctrs.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().post('/auth/2fa/verify', data: {'code': _otp});
      final token = res['data']?['token'] as String?;
      if (token != null) {
        await ApiService().saveToken(token);
        if (mounted) {
          ref.read(authStateProvider.notifier).state = true;
          context.go('/dashboard');
        }
      } else {
        setState(() => _error = 'Verifikasi gagal, coba lagi');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    // Auto submit saat digit ke-6 diisi
    if (_otp.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = widget.email != null
        ? _maskEmail(widget.email!)
        : 'email kamu';

    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: FinaColors.icCopper,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text('📩', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 16),

              const Text(
                'Verifikasi OTP',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: FinaColors.text, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: FinaColors.text2, height: 1.5),
                  children: [
                    const TextSpan(text: 'Kode 6 digit telah dikirim ke '),
                    TextSpan(
                      text: maskedEmail,
                      style: const TextStyle(
                        color: FinaColors.copper2, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Error
              if (_error != null) ...[
                FinaCard(
                  copper: true, padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: FinaColors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                      style: const TextStyle(color: FinaColors.red, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // 6 OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => SizedBox(
                  width: 46,
                  child: TextField(
                    controller: _ctrs[i],
                    focusNode: _nodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: FinaColors.text),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FinaColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FinaColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FinaColors.copper, width: 2),
                      ),
                      filled: true,
                      fillColor: FinaColors.surface2,
                    ),
                    onChanged: (v) => _onDigitChanged(i, v),
                  ),
                )),
              ),
              const SizedBox(height: 32),

              FinaButton(
                label: 'Verifikasi',
                onPressed: _verify,
                isLoading: _loading,
              ),
              const SizedBox(height: 20),

              // Resend
              Center(
                child: _countdown > 0
                    ? Text(
                        'Kirim ulang dalam $_countdown detik',
                        style: const TextStyle(
                          fontSize: 13, color: FinaColors.text2),
                      )
                    : GestureDetector(
                        onTap: () {
                          _startTimer();
                          // Kirim ulang OTP ke API
                          if (widget.email != null) {
                            ApiService().post('/auth/2fa/resend',
                              data: {'email': widget.email});
                          }
                        },
                        child: const Text(
                          'Kirim Ulang Kode',
                          style: TextStyle(
                            color: FinaColors.copper,
                            fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name   = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${'*' * name.length}@$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }
}
