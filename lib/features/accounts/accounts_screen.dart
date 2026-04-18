import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart';

final accountsProvider = FutureProvider.autoDispose<List<AccountModel>>(
    (_) => AccountRepository().getAll());

// ─────────────────────────────────────────────────────────────────────────────
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(title: const Text('Rekening')),
      body: async.when(
        data: (accounts) => RefreshIndicator(
          color: FinaColors.copper,
          backgroundColor: FinaColors.surface,
          onRefresh: () => ref.refresh(accountsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Total balance
              _TotalBalanceCard(accounts: accounts),
              const SizedBox(height: 20),

              // Account list
              if (accounts.isEmpty)
                const FinaEmptyState(
                  emoji: '💳',
                  title: 'Belum ada rekening',
                  subtitle: 'Tambah rekening untuk mulai mencatat',
                )
              else
                ...accounts.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AccountCard(
                        account: a,
                        onEdit: () =>
                            _showAccountForm(context, ref, account: a),
                        onDelete: () => _confirmDelete(context, ref, a),
                      ),
                    )),

              const SizedBox(height: 80),
            ],
          ),
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: FinaColors.copper)),
        error: (e, _) => FinaErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(accountsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(context, ref),
        backgroundColor: FinaColors.copper,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAccountForm(BuildContext context, WidgetRef ref,
      {AccountModel? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccountFormSheet(
        account: account,
        onSaved: () => ref.refresh(accountsProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AccountModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FinaColors.surface,
        title: const Text('Hapus Rekening?'),
        content: Text('Rekening "${a.name}" akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: FinaColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AccountRepository().delete(a.id);
        ref.refresh(accountsProvider);
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TotalBalanceCard extends StatelessWidget {
  final List<AccountModel> accounts;
  const _TotalBalanceCard({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold(0.0, (sum, a) => sum + a.balance);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kCopperGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total Saldo',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(formatCurrency(total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            )),
        const SizedBox(height: 8),
        Text('${accounts.length} rekening aktif',
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onEdit, onDelete;
  const _AccountCard(
      {required this.account, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return FinaCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        IconCircle(
            emoji: account.icon ?? '💳',
            bgColor: FinaColors.icCopper,
            size: 44),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(account.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              FinaPill(account.type, variant: PillVariant.copper),
            ]),
            const SizedBox(height: 4),
            Text(formatCurrency(account.balance),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FinaColors.copper2)),
          ]),
        ),
        PopupMenuButton<String>(
          color: FinaColors.surface2,
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: FinaColors.red))),
          ],
          child: const Icon(Icons.more_vert_rounded, color: FinaColors.text2),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AccountFormSheet extends StatefulWidget {
  final AccountModel? account;
  final VoidCallback onSaved;
  const _AccountFormSheet({this.account, required this.onSaved});

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _type = 'cash';
  bool _loading = false;

  static const _types = ['cash', 'bank', 'e-wallet', 'investment', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!.name;
      _balanceCtrl.text = widget.account!.balance.toStringAsFixed(0);
      _type = widget.account!.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'balance': double.tryParse(_balanceCtrl.text) ?? 0,
      };
      if (widget.account == null) {
        await AccountRepository().create(data);
      } else {
        await AccountRepository().update(widget.account!.id, data);
      }
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
        Text(widget.account == null ? 'Tambah Rekening' : 'Edit Rekening',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(labelText: 'Nama Rekening'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _balanceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(labelText: 'Saldo Awal'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type,
          dropdownColor: FinaColors.surface2,
          decoration: const InputDecoration(labelText: 'Tipe Rekening'),
          items: _types
              .map((t) => DropdownMenuItem(
                    value: t,
                    child:
                        Text(t, style: const TextStyle(color: FinaColors.text)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 24),
        FinaButton(
          label: widget.account == null ? 'Tambah' : 'Simpan',
          onPressed: _save,
          isLoading: _loading,
        ),
      ]),
    );
  }
}
