import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/utils/router.dart';
import '../../core/widgets/shared_widgets.dart';

/// Helper: tampilkan bottom sheet sambil sembunyikan navbar dengan animasi.
Future<T?> _showProfileSheet<T>(
  BuildContext context,
  WidgetRef ref,
  WidgetBuilder builder,
) async {
  // Sembunyikan navbar
  ref.read(navbarVisibleProvider.notifier).state = false;

  final result = await showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FinaColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: builder,
  );

  // Tampilkan kembali navbar
  if (context.mounted) {
    ref.read(navbarVisibleProvider.notifier).state = true;
  }

  return result;
}

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
      body: async.when(
        data: (user) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ProfileHeader(user: user, ref: ref)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionLabel('Akun'),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconBg: FinaColors.icBlue,
                      iconColor: FinaColors.blue,
                      label: 'Nama',
                      value: user.name,
                      onTap: () => _showEditProfile(context, ref, user),
                    ),
                    _MenuItem(
                      icon: Icons.email_outlined,
                      iconBg: FinaColors.icBlue,
                      iconColor: FinaColors.blue,
                      label: 'Email',
                      value: user.email,
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconBg: FinaColors.icPurple,
                      iconColor: FinaColors.purple,
                      label: 'Ganti Password',
                      onTap: () => _showChangePassword(context, ref),
                    ),
                    _MenuItem(
                      icon: Icons.currency_exchange_rounded,
                      iconBg: FinaColors.icCopper,
                      iconColor: FinaColors.copper2,
                      label: 'Mata Uang',
                      value: user.currency,
                      onTap: () => _showEditProfile(context, ref, user),
                    ),
                    _MenuItem(
                      icon: Icons.schedule_rounded,
                      iconBg: FinaColors.icBlue,
                      iconColor: FinaColors.blue,
                      label: 'Timezone',
                      value: user.timezone,
                      onTap: () => _showEditProfile(context, ref, user),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _LogoutButton(onTap: () => _confirmLogout(context, ref)),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Fina v1.0.0',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: FinaColors.muted),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: FinaColors.copper)),
        error: (e, _) => FinaErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(profileProvider),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, UserModel user) {
    _showProfileSheet(
      context,
      ref,
      (_) => _EditProfileSheet(
        user: user,
        onSaved: () => ref.refresh(profileProvider),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    _showProfileSheet(
      context,
      ref,
      (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FinaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Fina?'),
        content: const Text(
          'Semua data lokal akan dihapus. Kamu perlu login kembali.',
          style: TextStyle(color: FinaColors.text2, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child:
                const Text('Batal', style: TextStyle(color: FinaColors.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar',
                style: TextStyle(
                    color: FinaColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthRepository().logout();
    if (!context.mounted) return;
    ref.read(authStateProvider.notifier).state = false;
    context.go('/login');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final WidgetRef ref;
  const _ProfileHeader({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final initials = user.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1520), FinaColors.bg],
        ),
      ),
      child: Column(children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: kCopperGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: FinaColors.copper.withOpacity(0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: FinaColors.copper.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isNotEmpty ? initials : 'U',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showEdit(context),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: FinaColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: FinaColors.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.edit_rounded,
                    size: 13, color: FinaColors.text2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FinaColors.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(fontSize: 13, color: FinaColors.text2),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Chip(
                label: user.role,
                color: FinaColors.copper,
                bg: FinaColors.icCopper),
            const SizedBox(width: 8),
            _Chip(
              label: user.currency,
              color: FinaColors.blue,
              bg: FinaColors.icBlue,
              icon: Icons.currency_exchange_rounded,
            ),
          ],
        ),
      ]),
    );
  }

  void _showEdit(BuildContext context) {
    _showProfileSheet(
      context,
      ref,
      (_) => _EditProfileSheet(
        user: user,
        onSaved: () => ref.refresh(profileProvider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip kecil
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  const _Chip(
      {required this.label, required this.color, required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

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

// ─────────────────────────────────────────────────────────────────────────────
// Menu Card
// ─────────────────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return FinaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(
            items.length,
            (i) => Column(children: [
                  if (i > 0) const FinaDivider(indent: 56),
                  items[i],
                ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Item
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: valueColor ?? iconColor),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Feature Card
// ─────────────────────────────────────────────────────────────────────────────
class _AiFeatureCard extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onInsight;
  const _AiFeatureCard({required this.onChat, required this.onInsight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16112A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x30A078DC)),
      ),
      child: Column(children: [
        _AiTile(
          icon: Icons.smart_toy_outlined,
          title: 'Fina AI Chat',
          subtitle: 'Tanya apa saja soal keuangan kamu',
          onTap: onChat,
        ),
        const Divider(
            height: 1, thickness: 1, color: Color(0x20A078DC), indent: 56),
        _AiTile(
          icon: Icons.auto_awesome_outlined,
          title: 'AI Insight Bulanan',
          subtitle: 'Analisa otomatis pengeluaran & tren',
          onTap: onInsight,
        ),
      ]),
    );
  }
}

class _AiTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AiTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x30A078DC),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: FinaColors.purple),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: FinaColors.text)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: FinaColors.text2)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: FinaColors.text2, size: 18),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x14E05C5C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x30E05C5C)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: FinaColors.red, size: 18),
            SizedBox(width: 8),
            Text('Keluar dari Akun',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FinaColors.red)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Sheet
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
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: FinaColors.border,
              borderRadius: BorderRadius.circular(99)),
        ),
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
                      Text(c, style: const TextStyle(color: FinaColors.text))))
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
// Change Password Sheet
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
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: FinaColors.border,
              borderRadius: BorderRadius.circular(99)),
        ),
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
