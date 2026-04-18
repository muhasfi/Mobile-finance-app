import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/shared_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent    = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Masukkan email yang valid');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().post(ApiConstants.forgotPass, data: {'email': email});
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      // Tetap tampilkan success untuk menghindari email enumeration
      // kecuali server mengembalikan error validasi
      if (e.statusCode == 422) {
        setState(() => _error = e.message);
      } else {
        setState(() => _sent = true);
      }
    } catch (_) {
      // Network error tetap tampilkan success
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Text('🔑', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 16),

              const Text(
                'Reset\nPassword',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: FinaColors.text, height: 1.2, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kami kirimkan link reset ke email kamu.',
                style: TextStyle(fontSize: 13, color: FinaColors.text2, height: 1.5),
              ),
              const SizedBox(height: 32),

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

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: FinaColors.text),
                enabled: !_sent,
                decoration: const InputDecoration(
                  labelText: 'Alamat Email',
                  prefixIcon: Icon(Icons.email_outlined, color: FinaColors.text2),
                ),
              ),
              const SizedBox(height: 20),

              FinaButton(
                label: _sent ? 'Email Terkirim ✓' : 'Kirim Link Reset',
                onPressed: _sent ? null : _submit,
                isLoading: _loading,
              ),

              if (_sent) ...[
                const SizedBox(height: 20),
                FinaCard(
                  copper: true,
                  padding: const EdgeInsets.all(16),
                  child: const Row(children: [
                    Text('✉️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email Terkirim!', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Cek inbox & spam. Link aktif 15 menit.',
                            style: TextStyle(fontSize: 11, color: FinaColors.text2)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        color: FinaColors.copper,
                        fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
