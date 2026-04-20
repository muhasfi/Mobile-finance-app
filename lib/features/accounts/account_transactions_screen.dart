import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/widgets/icon_circle.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart' hide IconCircle;

// ── State & Providers ──────────────────────────────────────────────────────────
class _TxFilter {
  final int month, year;
  final String? type;
  const _TxFilter({required this.month, required this.year, this.type});

  @override
  bool operator ==(Object o) =>
      o is _TxFilter && o.month == month && o.year == year && o.type == type;

  @override
  int get hashCode => Object.hash(month, year, type);
}

class _ProviderKey {
  final String accountId;
  final _TxFilter filter;
  const _ProviderKey(this.accountId, this.filter);

  @override
  bool operator ==(Object o) =>
      o is _ProviderKey && o.accountId == accountId && o.filter == filter;

  @override
  int get hashCode => Object.hash(accountId, filter);
}

final _filterProvider =
    StateProvider.family<_TxFilter, String>((ref, accountId) =>
        _TxFilter(month: DateTime.now().month, year: DateTime.now().year));

final _txProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<TransactionModel>, _ProviderKey>((ref, key) {
  return TransactionRepository().getAll(
    accountId: key.accountId,
    month: key.filter.month,
    year: key.filter.year,
    type: key.filter.type,
  );
});

final _accountDetailProvider =
    FutureProvider.autoDispose.family<AccountModel?, String>((ref, id) async {
  final accounts = await AccountRepository().getAll();
  return accounts.where((a) => a.id == id).firstOrNull;
});

// ─────────────────────────────────────────────────────────────────────────────
class AccountTransactionsScreen extends ConsumerWidget {
  final String accountId;
  const AccountTransactionsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(_accountDetailProvider(accountId));
    final filter = ref.watch(_filterProvider(accountId));
    final txAsync =
        ref.watch(_txProvider(_ProviderKey(accountId, filter)));

    final account = accountAsync.value;

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: Text(account?.name ?? 'Transaksi Rekening'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          _MonthFilterButton(
            filter: filter,
            onChanged: (f) =>
                ref.read(_filterProvider(accountId).notifier).state = f,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [

        // ── Info rekening ─────────────────────────────────────────────────
        if (account != null) _AccountInfoCard(account: account),

        // ── Filter tipe ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _TypeTabs(
            current: filter.type,
            onChanged: (t) =>
                ref.read(_filterProvider(accountId).notifier).state =
                    _TxFilter(month: filter.month, year: filter.year, type: t),
          ),
        ),

        const SizedBox(height: 8),

        // ── List transaksi ────────────────────────────────────────────────
        Expanded(
          child: txAsync.when(
            data: (page) => page.data.isEmpty
                ? FinaEmptyState(
                    emoji: '📭',
                    title: 'Tidak ada transaksi',
                    subtitle:
                        'Belum ada transaksi untuk rekening ini\npada bulan yang dipilih',
                    action: FinaButton(
                      label: 'Tambah Transaksi',
                      onPressed: () => context
                          .push('/transactions/add?account_id=$accountId'),
                    ),
                  )
                : RefreshIndicator(
                    color: FinaColors.copper,
                    backgroundColor: FinaColors.surface,
                    onRefresh: () => ref.refresh(
                        _txProvider(_ProviderKey(accountId, filter)).future),
                    child: Column(children: [
                      _MonthlySummary(transactions: page.data),
                      Expanded(
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: page.data.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _TxTile(tx: page.data[i]),
                        ),
                      ),
                    ]),
                  ),
            loading: () => const Center(
                child: CircularProgressIndicator(color: FinaColors.copper)),
            error: (e, _) => FinaErrorWidget(
              message: e.toString(),
              onRetry: () => ref
                  .refresh(_txProvider(_ProviderKey(accountId, filter))),
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/transactions/add?account_id=$accountId'),
        backgroundColor: FinaColors.copper,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card Rekening — pakai color hex dari API
// ─────────────────────────────────────────────────────────────────────────────
class _AccountInfoCard extends StatelessWidget {
  final AccountModel account;
  const _AccountInfoCard({required this.account});

  Color get _color {
    if (account.color == null) return FinaColors.copper;
    try {
      final hex = account.color!.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return FinaColors.copper;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withAlpha(60)),
      ),
      child: Row(children: [
        // Icon dari bootstrap icon mapper
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: IconCircle(
            icon: account.icon,
            bgColor: _color.withAlpha(40),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(account.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _color.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(account.type,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _color)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(formatCurrency(account.balance),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _color)),
          ]),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: account.isActive ? FinaColors.green : FinaColors.red,
            shape: BoxShape.circle,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ringkasan Bulanan
// ─────────────────────────────────────────────────────────────────────────────
class _MonthlySummary extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _MonthlySummary({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: FinaCard(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _SummaryItem(
              label: 'Masuk',
              value: income,
              color: FinaColors.green,
              icon: Icons.arrow_downward_rounded),
          Container(width: 1, height: 28, color: FinaColors.border),
          _SummaryItem(
              label: 'Keluar',
              value: expense,
              color: FinaColors.red,
              icon: Icons.arrow_upward_rounded),
          Container(width: 1, height: 28, color: FinaColors.border),
          _SummaryItem(
              label: net >= 0 ? 'Surplus' : 'Defisit',
              value: net.abs(),
              color: net >= 0 ? FinaColors.green : FinaColors.red,
              icon: net >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded),
        ]),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _SummaryItem(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 9, color: FinaColors.text2)),
          Text(formatCurrency(value),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Type Tabs
// ─────────────────────────────────────────────────────────────────────────────
class _TypeTabs extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _TypeTabs({required this.current, required this.onChanged});

  static const _tabs = [
    (label: 'Semua',       value: null),
    (label: 'Masuk',       value: 'income'),
    (label: 'Keluar',      value: 'expense'),
    (label: 'Transfer',    value: 'transfer'),
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
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: active ? FinaColors.copper : FinaColors.surface,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: active ? FinaColors.copper : FinaColors.border),
              ),
              alignment: Alignment.center,
              child: Text(t.label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : FinaColors.text2)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bulan
// ─────────────────────────────────────────────────────────────────────────────
class _MonthFilterButton extends StatelessWidget {
  final _TxFilter filter;
  final ValueChanged<_TxFilter> onChanged;
  const _MonthFilterButton(
      {required this.filter, required this.onChanged});

  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FinaColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FinaColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_month_outlined,
              size: 13, color: FinaColors.copper),
          const SizedBox(width: 5),
          Text(
            '${_months[filter.month - 1]} ${filter.year}',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600),
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
            colorScheme:
                const ColorScheme.dark(primary: FinaColors.copper)),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(_TxFilter(
          month: picked.month, year: picked.year, type: filter.type));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Chip — tap → lihat transaksi rekening ini
// ─────────────────────────────────────────────────────────────────────────────
class _AccountChip extends StatelessWidget {
  final AccountModel account;
  const _AccountChip({required this.account});

  Color get _accountColor {
    if (account.color == null) return FinaColors.copper;
    try {
      final hex = account.color!.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return FinaColors.copper;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap chip → lihat transaksi rekening ini 
      onTap: () => context.push('/accounts/${account.id}/transactions'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FinaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FinaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              IconCircle(
                icon: account.icon,
                bgColor: FinaColors.icCopper,
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: account.isActive ? FinaColors.green : FinaColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                account.name,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                formatCurrency(account.balance),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FinaColors.copper2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Hint kecil
              Row(children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 9, color: FinaColors.muted),
                const SizedBox(width: 3),
                const Text('Lihat transaksi',
                    style: TextStyle(fontSize: 9, color: FinaColors.muted)),
              ]),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Tile — konsisten dengan dashboard (pakai IconCircle bi-xxx)
// ─────────────────────────────────────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: FinaCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          IconCircle(
            icon: tx.category?.icon ??
                (tx.isIncome
                    ? 'bi-cash'
                    : tx.isTransfer
                        ? 'bi-arrow-left-right'
                        : 'bi-arrow-up'),
            bgColor: tx.isIncome
                ? FinaColors.icGreen
                : tx.isTransfer
                    ? FinaColors.icBlue
                    : FinaColors.icRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.category?.name ?? _typeLabel(tx.type),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    tx.note?.isNotEmpty == true
                        ? tx.note!
                        : formatDate(tx.date),
                    style: const TextStyle(
                        fontSize: 11, color: FinaColors.text2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AmountText(amount: tx.amount, type: tx.type, fontSize: 13),
            const SizedBox(height: 2),
            Text(formatDate(tx.date, pattern: 'd MMM'),
                style: const TextStyle(
                    fontSize: 10, color: FinaColors.muted)),
          ]),
        ]),
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'income'   => 'Pemasukan',
        'expense'  => 'Pengeluaran',
        'transfer' => 'Transfer',
        _          => type,
      };
}
