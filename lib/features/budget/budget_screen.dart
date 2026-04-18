import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:finance_app_mobile/core/widgets/icon_circle.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart' hide IconCircle;

// ── Period wrapper — wajib ada == dan hashCode untuk FutureProvider.family ────
class _BudgetPeriod {
  final int month, year;
  const _BudgetPeriod(this.month, this.year);

  @override
  bool operator ==(Object o) =>
      o is _BudgetPeriod && o.month == month && o.year == year;

  @override
  int get hashCode => Object.hash(month, year);
}

final _budgetPeriodProvider = StateProvider(
    (_) => _BudgetPeriod(DateTime.now().month, DateTime.now().year));

final budgetProvider = FutureProvider.autoDispose
    .family<List<BudgetModel>, _BudgetPeriod>((ref, p) {
  return BudgetRepository().getAll(month: p.month, year: p.year);
});

// ─────────────────────────────────────────────────────────────────────────────
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_budgetPeriodProvider);
    final async = ref.watch(budgetProvider(period));

    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text('Budget',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 22)),
              const Spacer(),
              Row(children: [
                GestureDetector(
                  onTap: () {
                    final d = DateTime(period.year, period.month - 1);
                    ref.read(_budgetPeriodProvider.notifier).state =
                        _BudgetPeriod(d.month, d.year);
                  },
                  child: const Icon(Icons.chevron_left_rounded,
                      color: FinaColors.text2),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${_months[period.month - 1]} ${period.year}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final now = DateTime.now();
                    final d = DateTime(period.year, period.month + 1);
                    if (!d.isAfter(DateTime(now.year, now.month))) {
                      ref.read(_budgetPeriodProvider.notifier).state =
                          _BudgetPeriod(d.month, d.year);
                    }
                  },
                  child: const Icon(Icons.chevron_right_rounded,
                      color: FinaColors.text2),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              data: (budgets) {
                final totalBudget = budgets.fold(0.0, (s, b) => s + b.amount);
                final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
                return RefreshIndicator(
                  color: FinaColors.copper,
                  backgroundColor: FinaColors.surface,
                  onRefresh: () => ref.refresh(budgetProvider(period).future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      _BudgetSummaryCard(
                          totalBudget: totalBudget, totalSpent: totalSpent),
                      const SizedBox(height: 16),
                      if (budgets.isEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () => _copyLastMonth(context, ref, period),
                          icon: const Icon(Icons.copy_outlined, size: 16),
                          label: const Text('Salin dari bulan lalu'),
                        ),
                        const SizedBox(height: 16),
                        const FinaEmptyState(
                          emoji: '🎯',
                          title: 'Belum ada budget',
                          subtitle:
                              'Set budget per kategori untuk mengontrol pengeluaran',
                        ),
                      ] else
                        ...budgets.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BudgetCard(
                                budget: b,
                                onEdit: () => _showBudgetForm(
                                    context, ref, period,
                                    budget: b),
                                onDelete: () =>
                                    _deleteBudget(context, ref, period, b.id),
                              ),
                            )),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: FinaColors.copper)),
              error: (e, _) => FinaErrorWidget(
                message: e.toString(),
                onRetry: () => ref.refresh(budgetProvider(period)),
              ),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(context, ref, period),
        backgroundColor: FinaColors.copper,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showBudgetForm(
      BuildContext context, WidgetRef ref, _BudgetPeriod period,
      {BudgetModel? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BudgetFormSheet(
        period: period,
        budget: budget,
        onSaved: () => ref.refresh(budgetProvider(period)),
      ),
    );
  }

  Future<void> _deleteBudget(BuildContext context, WidgetRef ref,
      _BudgetPeriod period, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FinaColors.surface,
        title: const Text('Hapus Budget?'),
        content: const Text('Budget ini akan dihapus.'),
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
        await BudgetRepository().delete(id);
        ref.refresh(budgetProvider(period));
      } on ApiException catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _copyLastMonth(
      BuildContext context, WidgetRef ref, _BudgetPeriod period) async {
    try {
      await BudgetRepository().copyFromLastMonth();
      ref.refresh(budgetProvider(period));
    } on ApiException catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final double totalBudget, totalSpent;
  const _BudgetSummaryCard(
      {required this.totalBudget, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final progress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final remaining = totalBudget - totalSpent;
    final isOver = remaining < 0;
    return FinaCard(
      copper: true,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Budget',
                style: TextStyle(
                    fontSize: 10,
                    color: FinaColors.text2,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(formatCurrency(totalBudget),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
          FinaPill(
            isOver
                ? 'Melebihi Budget!'
                : '${(progress * 100).toStringAsFixed(0)}% dipakai',
            variant: isOver ? PillVariant.red : PillVariant.copper,
          ),
        ]),
        const SizedBox(height: 16),
        FinaProgressBar(progress: progress.clamp(0, 1), danger: isOver),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Terpakai: ${formatCurrency(totalSpent)}',
              style: const TextStyle(fontSize: 12, color: FinaColors.text2)),
          Text(
            isOver
                ? 'Lebih ${formatCurrency(remaining.abs())}'
                : 'Sisa ${formatCurrency(remaining)}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOver ? FinaColors.red : FinaColors.green),
          ),
        ]),
      ]),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onEdit, onDelete;
  const _BudgetCard(
      {required this.budget, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return FinaCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          IconCircle(
            icon: budget.category?.icon ?? '📌',
            bgColor: FinaColors.icCopper,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(budget.category?.name ?? 'Budget',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
          FinaPill(
            budget.isOver ? 'Lebih!' : formatCurrency(budget.remaining),
            variant: budget.isOver ? PillVariant.red : PillVariant.green,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            color: FinaColors.surface2,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: FinaColors.text2),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('Hapus', style: TextStyle(color: FinaColors.red))),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        FinaProgressBar(progress: budget.progress, danger: budget.isOver),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${formatCurrency(budget.spent)} terpakai',
              style: const TextStyle(fontSize: 11, color: FinaColors.text2)),
          Text('dari ${formatCurrency(budget.amount)}',
              style: const TextStyle(fontSize: 11, color: FinaColors.text2)),
        ]),
      ]),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  final _BudgetPeriod period;
  final BudgetModel? budget;
  final VoidCallback onSaved;
  const _BudgetFormSheet(
      {required this.period, this.budget, required this.onSaved});

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _amountCtrl = TextEditingController();
  CategoryModel? _category;
  bool _loading = false;
  double _alertThreshold = 80;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountCtrl.text = widget.budget!.amount.toStringAsFixed(0);
      _category = widget.budget!.category;
      _alertThreshold = (widget.budget!.alertThreshold ?? 80).toDouble();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    List<CategoryModel> cats = [];
    try {
      cats = await CategoryRepository().getAll();
    } catch (_) {}
    final expense = cats.where((c) => c.type == 'expense').toList();
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
            children: expense
                .map((c) => ListTile(
                      leading: IconCircle(
                          icon: c.icon ?? '📌', bgColor: FinaColors.icCopper),
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

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah budget yang valid')));
      return;
    }
    setState(() => _loading = true);
    try {
      final data = {
        'amount': amount,
        'month': widget.period.month,
        'year': widget.period.year,
        if (_category != null) 'category_id': _category!.id,
        'alert_threshold': _alertThreshold.toInt(),
      };
      if (widget.budget == null) {
        await BudgetRepository().create(data);
      } else {
        await BudgetRepository().update(widget.budget!.id, data);
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
        Text(widget.budget == null ? 'Tambah Budget' : 'Edit Budget',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(
              labelText: 'Jumlah Budget', prefixText: 'Rp '),
        ),
        const SizedBox(height: 12),
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
                    color:
                        _category != null ? FinaColors.text : FinaColors.muted),
              )),
              const Icon(Icons.chevron_right_rounded,
                  color: FinaColors.text2, size: 18),
            ]),
          ),
        ),

        // 🔽 TAMBAH DI SINI
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alert pada ${_alertThreshold.toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _alertThreshold,
              min: 50,
              max: 100,
              divisions: 10,
              label: "${_alertThreshold.toInt()}%",
              onChanged: (value) {
                setState(() {
                  _alertThreshold = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("50%"),
                Text("100%"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        FinaButton(
          label: widget.budget == null ? 'Tambah' : 'Simpan',
          onPressed: _save,
          isLoading: _loading,
        ),
      ]),
    );
  }
}
