import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/utils/router.dart';
import '../../core/widgets/shared_widgets.dart';

final profileProvider =
    FutureProvider.autoDispose<UserModel>((_) => AuthRepository().getMe());

// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: SafeArea(
        child: async.when(
          data: (user) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),

              // ── Avatar + name ──────────────────────────────────────────────
              Center(
                child: Column(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: kCopperGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  FinaPill(user.role, variant: PillVariant.copper),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Akun ───────────────────────────────────────────────────────
              const _SectionTitle('Akun'),
              FinaCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    label: 'Nama',
                    value: user.name,
                    onTap: () => _showEditProfile(context, ref, user),
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.currency_exchange,
                    label: 'Mata Uang',
                    value: user.currency,
                    onTap: () => _showEditProfile(context, ref, user),
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.schedule_outlined,
                    label: 'Timezone',
                    value: user.timezone,
                    onTap: () => _showEditProfile(context, ref, user),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('Keamanan'),
              FinaCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _ProfileTile(
                    icon: Icons.lock_outline,
                    label: 'Ganti Password',
                    onTap: () => _showChangePassword(context),
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.category_outlined,
                    label: 'Kelola Kategori',
                    onTap: () => context.push('/categories'),
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.repeat_rounded,
                    label: 'Transaksi Berulang',
                    onTap: () => context.push('/recurring'),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('Fitur'),
              FinaCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _ProfileTile(
                    icon: Icons.smart_toy_outlined,
                    label: 'Fina AI Chat',
                    value: 'Tanya soal keuangan',
                    onTap: () => context.push('/ai/chat'),
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'AI Insight Bulanan',
                    value: 'Analisa otomatis',
                    onTap: () => context.push('/ai/insight'),
                  ),
                  const FinaDivider(indent: 56),
                  _ProfileTile(
                    icon: Icons.upload_file_outlined,
                    label: 'Import CSV Bank',
                    value: 'BCA, Mandiri, BRI, BNI',
                    onTap: () => context.push('/import'),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('Lainnya'),
              FinaCard(
                padding: EdgeInsets.zero,
                child: _ProfileTile(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  valueColor: FinaColors.red,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text('Fina v1.0.0',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: FinaColors.muted)),
              ),
              const SizedBox(height: 20),
            ],
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: FinaColors.copper)),
          error: (e, _) => FinaErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(profileProvider),
          ),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProfileSheet(
        user: user,
        onSaved: () => ref.refresh(profileProvider),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FinaColors.surface,
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Keluar', style: TextStyle(color: FinaColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await AuthRepository().logout();
      // Update auth state → GoRouter redirect otomatis ke /login
      ref.read(authStateProvider.notifier).state = false;
      context.go('/login');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: FinaColors.copper,
            )),
      );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: FinaColors.surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: valueColor ?? FinaColors.text2),
        ),
        title: Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? FinaColors.text,
            )),
        trailing: value != null
            ? Text(value!,
                style: const TextStyle(fontSize: 13, color: FinaColors.text2))
            : (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: FinaColors.text2, size: 18)
                : null),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  final VoidCallback onSaved;
  const _EditProfileSheet({required this.user, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  String _currency = 'IDR';
  bool _loading = false;

  static const _currencies = ['IDR', 'USD', 'EUR', 'SGD', 'MYR', 'JPY'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _currency = widget.user.currency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthRepository().updateProfile({
        'name': _nameCtrl.text.trim(),
        'currency': _currency,
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Edit Profil', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(labelText: 'Nama'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _currency,
          dropdownColor: FinaColors.surface2,
          decoration: const InputDecoration(labelText: 'Mata Uang'),
          items: _currencies
              .map((c) => DropdownMenuItem(
                    value: c,
                    child:
                        Text(c, style: const TextStyle(color: FinaColors.text)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _currency = v!),
        ),
        const SizedBox(height: 24),
        FinaButton(label: 'Simpan', onPressed: _save, isLoading: _loading),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return;
    }
    if (_newCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password minimal 8 karakter')));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthRepository().changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        newPasswordConfirmation: _confirmCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password berhasil diperbarui ✅')));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Ganti Password', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        TextField(
          controller: _currentCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(labelText: 'Password Lama'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(labelText: 'Password Baru'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: FinaColors.text),
          decoration: InputDecoration(
            labelText: 'Konfirmasi Password Baru',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: FinaColors.text2,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FinaButton(label: 'Simpan', onPressed: _save, isLoading: _loading),
      ]),
    );
  }
}
