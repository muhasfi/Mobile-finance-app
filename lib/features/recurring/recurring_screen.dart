import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart';

final recurringProvider = FutureProvider.autoDispose<List<RecurringPlanModel>>(
    (_) => RecurringRepository().getAll());

// ─────────────────────────────────────────────────────────────────────────────
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recurringProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      body: async.when(
        data: (plans) => plans.isEmpty
            ? const FinaEmptyState(
                emoji: '🔄',
                title: 'Belum ada transaksi berulang',
                subtitle: 'Atur tagihan atau langganan yang berulang otomatis',
              )
            : RefreshIndicator(
                color: FinaColors.copper,
                backgroundColor: FinaColors.surface,
                onRefresh: () => ref.refresh(recurringProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RecurringTile(
                    plan: plans[i],
                    onEdit: () => _showForm(context, ref, plan: plans[i]),
                    onToggle: () async {
                      try {
                        await RecurringRepository().toggle(plans[i].id);
                        ref.refresh(recurringProvider);
                      } on ApiException catch (e) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    },
                    onDelete: () => _confirmDelete(context, ref, plans[i]),
                  ),
                ),
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: FinaColors.copper)),
        error: (e, _) => FinaErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(recurringProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        backgroundColor: FinaColors.copper,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {RecurringPlanModel? plan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RecurringFormSheet(
        plan: plan,
        onSaved: () => ref.refresh(recurringProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, RecurringPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FinaColors.surface,
        title: const Text('Hapus?'),
        content: Text('Transaksi berulang "${plan.name}" akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Hapus', style: TextStyle(color: FinaColors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await RecurringRepository().delete(plan.id);
        ref.refresh(recurringProvider);
      } on ApiException catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RecurringTile extends StatelessWidget {
  final RecurringPlanModel plan;
  final VoidCallback onToggle, onDelete, onEdit;
  const _RecurringTile({
    required this.plan,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  static const _freqLabel = {
    'daily': 'Harian',
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
  };

  @override
  Widget build(BuildContext context) {
    return FinaCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        IconCircle(
          emoji: plan.category?.icon ?? (plan.type == 'income' ? '📥' : '📤'),
          bgColor: plan.isActive
              ? (plan.type == 'income' ? FinaColors.icGreen : FinaColors.icRed)
              : FinaColors.surface2,
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: plan.isActive ? FinaColors.text : FinaColors.text2,
                )),
            const SizedBox(height: 4),
            Row(children: [
              FinaPill(_freqLabel[plan.frequency] ?? plan.frequency,
                  variant: PillVariant.blue),
              const SizedBox(width: 6),
              if (plan.nextDueDate != null)
                Text(
                  'Jatuh: ${formatDate(plan.nextDueDate!, pattern: 'd MMM')}',
                  style: const TextStyle(fontSize: 10, color: FinaColors.text2),
                ),
            ]),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AmountText(amount: plan.amount, type: plan.type, fontSize: 13),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: plan.isActive ? FinaColors.icGreen : FinaColors.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        plan.isActive ? FinaColors.green : FinaColors.border),
              ),
              child: Text(
                plan.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: plan.isActive ? FinaColors.green : FinaColors.text2,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          color: FinaColors.surface2,
          icon: const Icon(Icons.more_vert_rounded,
              color: FinaColors.text2, size: 18),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: FinaColors.red))),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RecurringFormSheet extends StatefulWidget {
  final RecurringPlanModel? plan;
  final VoidCallback onSaved;
  const _RecurringFormSheet({this.plan, required this.onSaved});

  @override
  State<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends State<_RecurringFormSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  String _type = 'expense';
  String _frequency = 'monthly';
  AccountModel? _account;
  CategoryModel? _category;
  bool _loading = false;

  static const _freqs = [
    ('daily', 'Harian'),
    ('weekly', 'Mingguan'),
    ('monthly', 'Bulanan'),
    ('yearly', 'Tahunan'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _nameCtrl.text = widget.plan!.name;
      _amountCtrl.text = widget.plan!.amount.toStringAsFixed(0);
      _type = widget.plan!.type;
      _frequency = widget.plan!.frequency;
      _account = widget.plan!.account;
      _category = widget.plan!.category;
      _startDate = widget.plan!.startDate ?? DateTime.now();
      _endDate = widget.plan!.endsAt;
      _noteCtrl.text = widget.plan!.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAccount() async {
    List<AccountModel> accounts = [];
    try {
      accounts = await AccountRepository().getAll();
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pilih Rekening',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: FinaColors.text))),
          const FinaDivider(),
          Flexible(
              child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 20),
            children: accounts
                .map((a) => ListTile(
                      leading: IconCircle(
                          emoji: a.icon ?? '💳', bgColor: FinaColors.icCopper),
                      title: Text(a.name,
                          style: const TextStyle(color: FinaColors.text)),
                      subtitle: Text(formatCurrency(a.balance),
                          style: const TextStyle(
                              color: FinaColors.copper2, fontSize: 12)),
                      trailing: _account?.id == a.id
                          ? const Icon(Icons.check_rounded,
                              color: FinaColors.copper)
                          : null,
                      onTap: () {
                        setState(() => _account = a);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          )),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    List<CategoryModel> cats = [];
    try {
      cats = await CategoryRepository().getAll();
    } catch (_) {}
    final filtered = cats.where((c) => c.type == _type).toList();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pilih Kategori',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: FinaColors.text))),
          const FinaDivider(),
          Flexible(
              child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 20),
            children: filtered
                .map((c) => ListTile(
                      leading: IconCircle(
                          emoji: c.icon ?? '📌', bgColor: FinaColors.icCopper),
                      title: Text(c.name,
                          style: const TextStyle(color: FinaColors.text)),
                      trailing: _category?.id == c.id
                          ? const Icon(Icons.check_rounded,
                              color: FinaColors.copper)
                          : null,
                      onTap: () {
                        setState(() => _category = c);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          )),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }
    if (_account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih rekening terlebih dahulu')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah yang valid')));
      return;
    }
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'amount': amount,
        'frequency': _frequency,
        'account_id': _account!.id,
        if (_category != null) 'category_id': _category!.id,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'ends_at': _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
        'note': _noteCtrl.text.trim(),
      };
      if (widget.plan == null) {
        await RecurringRepository().create(data);
      } else {
        await RecurringRepository().update(widget.plan!.id, data);
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
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              widget.plan == null
                  ? 'Tambah Transaksi Berulang'
                  : 'Edit Transaksi Berulang',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),

          // Nama
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: FinaColors.text),
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 12),

          // Tipe
          Row(children: [
            Expanded(
                child: _TypeBtn(
                    'expense',
                    '📤 Pengeluaran',
                    _type == 'expense',
                    () => setState(() {
                          _type = 'expense';
                          _category = null;
                        }))),
            const SizedBox(width: 8),
            Expanded(
                child: _TypeBtn(
                    'income',
                    '📥 Pemasukan',
                    _type == 'income',
                    () => setState(() {
                          _type = 'income';
                          _category = null;
                        }))),
          ]),
          const SizedBox(height: 12),

          // Jumlah
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: FinaColors.text),
            decoration:
                const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
          ),
          const SizedBox(height: 12),

          // Frekuensi
          DropdownButtonFormField<String>(
            initialValue: _frequency,
            dropdownColor: FinaColors.surface2,
            decoration: const InputDecoration(labelText: 'Frekuensi'),
            items: _freqs
                .map((f) => DropdownMenuItem(
                      value: f.$1,
                      child: Text(f.$2,
                          style: const TextStyle(color: FinaColors.text)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          const SizedBox(height: 12),

          // Rekening (WAJIB)
          GestureDetector(
            onTap: _pickAccount,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: FinaColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _account != null
                        ? FinaColors.copper
                        : FinaColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: FinaColors.text2),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                  _account?.name ?? 'Pilih Rekening *',
                  style: TextStyle(
                      fontSize: 14,
                      color: _account != null
                          ? FinaColors.text
                          : FinaColors.muted),
                )),
                const Icon(Icons.chevron_right_rounded,
                    color: FinaColors.text2, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Kategori (opsional)
          GestureDetector(
            onTap: _pickCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: FinaColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FinaColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.category_outlined,
                    size: 16, color: FinaColors.text2),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                  _category?.name ?? 'Pilih Kategori (opsional)',
                  style: TextStyle(
                      fontSize: 14,
                      color: _category != null
                          ? FinaColors.text
                          : FinaColors.muted),
                )),
                const Icon(Icons.chevron_right_rounded,
                    color: FinaColors.text2, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickStartDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: FinaColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FinaColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal Mulai'),
                        Text(DateFormat('dd MMM yyyy', 'id_ID')
                            .format(_startDate)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickEndDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: FinaColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FinaColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Berakhir'),
                        Text(
                          _endDate == null
                              ? 'Tidak ada'
                              : DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(_endDate!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: const TextStyle(color: FinaColors.text),
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
            ),
          ),
          const SizedBox(height: 16),

          FinaButton(
            label: widget.plan == null ? 'Tambah' : 'Simpan',
            onPressed: _save,
            isLoading: _loading,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String value, label;
  final bool active;
  final VoidCallback onTap;
  const _TypeBtn(this.value, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? FinaColors.copper : FinaColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? FinaColors.copper : FinaColors.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : FinaColors.text2,
              )),
        ),
      );
}
