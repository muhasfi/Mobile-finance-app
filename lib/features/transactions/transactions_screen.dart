import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_app_mobile/core/widgets/icon_circle.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart' hide IconCircle;

// ── State ─────────────────────────────────────────────────────────────────────
// == dan hashCode wajib agar FutureProvider.family cache benar
class _TxFilter {
  final int month, year;
  final String? type;

  const _TxFilter({required this.month, required this.year, this.type});

  @override
  bool operator ==(Object other) =>
      other is _TxFilter &&
      other.month == month &&
      other.year == year &&
      other.type == type;

  @override
  int get hashCode => Object.hash(month, year, type);
}

final _txFilterProvider = StateProvider((ref) => _TxFilter(
      month: DateTime.now().month,
      year: DateTime.now().year,
    ));

final transactionsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<TransactionModel>, _TxFilter>((ref, filter) {
  return TransactionRepository().getAll(
    month: filter.month,
    year: filter.year,
    type: filter.type,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_txFilterProvider);
    final async = ref.watch(transactionsProvider(filter));

    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text('Transaksi',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                      )),
              const Spacer(),
              _FilterButton(
                filter: filter,
                onChanged: (f) =>
                    ref.read(_txFilterProvider.notifier).state = f,
              ),
            ]),
          ),

          // ── Type tabs ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _TypeTabs(
              current: filter.type,
              onChanged: (t) => ref.read(_txFilterProvider.notifier).state =
                  _TxFilter(month: filter.month, year: filter.year, type: t),
            ),
          ),

          const SizedBox(height: 16),

          // ── List ────────────────────────────────────────────────────────────
          Expanded(
            child: async.when(
              data: (page) => page.data.isEmpty
                  ? const FinaEmptyState(
                      emoji: '📭',
                      title: 'Tidak ada transaksi',
                      subtitle: 'Coba ubah filter atau tambah transaksi baru',
                    )
                  : RefreshIndicator(
                      color: FinaColors.copper,
                      backgroundColor: FinaColors.surface,
                      onRefresh: () =>
                          ref.refresh(transactionsProvider(filter).future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: page.data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _TxTile(tx: page.data[i]),
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: FinaColors.copper),
              ),
              error: (e, _) => FinaErrorWidget(
                message: e.toString(),
                onRetry: () => ref.refresh(transactionsProvider(filter)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type Tabs
// ─────────────────────────────────────────────────────────────────────────────
class _TypeTabs extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _TypeTabs({required this.current, required this.onChanged});

  static const _tabs = [
    (label: 'Semua', value: null),
    (label: 'Pemasukan', value: 'income'),
    (label: 'Pengeluaran', value: 'expense'),
    (label: 'Transfer', value: 'transfer'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _tabs.map((t) {
        final active = current == t.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t.value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? FinaColors.copper : FinaColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? FinaColors.copper : FinaColors.border),
              ),
              alignment: Alignment.center,
              child: Text(t.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : FinaColors.text2,
                  )),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Button (month picker)
// ─────────────────────────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final _TxFilter filter;
  final ValueChanged<_TxFilter> onChanged;
  const _FilterButton({required this.filter, required this.onChanged});

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FinaColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FinaColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_month_outlined,
              size: 14, color: FinaColors.copper),
          const SizedBox(width: 6),
          Text(
            '${_months[filter.month - 1]} ${filter.year}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(filter.year, filter.month),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: FinaColors.copper),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(
          _TxFilter(month: picked.month, year: picked.year, type: filter.type));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Tile
// ─────────────────────────────────────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final bgColor = tx.isIncome
        ? FinaColors.icGreen
        : tx.isTransfer
            ? FinaColors.icBlue
            : FinaColors.icRed;

    return GestureDetector(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: FinaCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconCircle(
            icon: tx.category?.icon ??
                (tx.isIncome
                    ? '📥'
                    : tx.isTransfer
                        ? '🔄'
                        : '📤'),
            bgColor: bgColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                tx.category?.name ?? tx.type,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                tx.note ?? tx.account?.name ?? '',
                style: const TextStyle(fontSize: 11, color: FinaColors.text2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(formatDate(tx.date),
                  style:
                      const TextStyle(fontSize: 10, color: FinaColors.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AmountText(amount: tx.amount, type: tx.type, fontSize: 14),
            if (tx.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FinaPill(tx.tags.first, variant: PillVariant.blue),
              ),
            if (tx.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.attach_file_rounded,
                        size: 11, color: FinaColors.text2),
                    SizedBox(width: 2),
                    Text('Bukti',
                        style:
                            TextStyle(fontSize: 10, color: FinaColors.text2)),
                  ],
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}
