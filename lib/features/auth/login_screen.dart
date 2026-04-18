import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/repositories.dart';
import '../../core/utils/router.dart';
import '../../core/widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AuthRepository().login(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await ApiService().saveToken(result.token);
      // Update auth state → GoRouter redirect otomatis ke /dashboard
      if (mounted) {
        ref.read(authStateProvider.notifier).state = true;
        context.go('/dashboard');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                ShaderMask(
                  shaderCallback: (bounds) => kCopperGradient.createShader(bounds),
                  child: const Text(
                    'Fina',
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola keuangan dengan cerdas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FinaColors.text2,
                  ),
                ),

                const SizedBox(height: 48),

                if (_error != null) ...[
                  FinaCard(
                    copper: true,
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: FinaColors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                        style: const TextStyle(color: FinaColors.red, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: FinaColors.text),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: FinaColors.text2),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: FinaColors.text),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: FinaColors.text2),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: FinaColors.text2, size: 18,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(color: FinaColors.copper2, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                FinaButton(
                  label: 'Masuk',
                  onPressed: _submit,
                  isLoading: _loading,
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun? ',
                      style: Theme.of(context).textTheme.bodySmall),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Daftar sekarang',
                        style: TextStyle(
                          color: FinaColors.copper,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
