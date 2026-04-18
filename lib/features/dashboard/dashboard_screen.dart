import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/widgets/icon_circle.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart' hide IconCircle;

// ── Helpers ───────────────────────────────────────────────────────────────────
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat Pagi ☀️';
  if (h < 15) return 'Selamat Siang 🌤️';
  if (h < 18) return 'Selamat Sore 🌅';
  return 'Selamat Malam 🌙';
}

// ── Provider ──────────────────────────────────────────────────────────────────
final dashboardProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return DashboardRepository().getSummary();
});

// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: FinaColors.copper,
          backgroundColor: FinaColors.surface,
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang 👋',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _greeting(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: FinaColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: FinaColors.border),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: FinaColors.text, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Total Balance Card ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: async.when(
                    data: (d) => _BalanceCard(summary: d),
                    loading: () =>
                        const FinaSkeletonBox(height: 140, radius: 20),
                    error: (e, _) => FinaErrorWidget(
                      message: e.toString(),
                      onRetry: () => ref.refresh(dashboardProvider),
                    ),
                  ),
                ),
              ),

              // ── Quick Actions ───────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _QuickActions(),
                ),
              ),

              // ── Income / Expense summary ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: async.when(
                    data: (d) => _SummaryRow(summary: d),
                    loading: () =>
                        const FinaSkeletonBox(height: 72, radius: 16),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),

              // ── Rekening ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rekening',
                          style: Theme.of(context).textTheme.titleSmall),
                      GestureDetector(
                        onTap: () => context.push('/accounts'),
                        child: const Text('Lihat semua',
                            style: TextStyle(
                                color: FinaColors.copper, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: async.when(
                    data: (d) => d.accounts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: FinaEmptyState(
                              emoji: '🏦',
                              title: 'Belum ada rekening',
                            ),
                          )
                        : SizedBox(
                            height: 130,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: d.accounts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) =>
                                  _AccountChip(account: d.accounts[i]),
                            ),
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: FinaSkeletonBox(height: 120, radius: 16),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),

              // ── Transaksi terakhir ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaksi Terakhir',
                          style: Theme.of(context).textTheme.titleSmall),
                      GestureDetector(
                        onTap: () => context.go('/transactions'),
                        child: const Text('Lihat semua',
                            style: TextStyle(
                                color: FinaColors.copper, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),

              async.when(
                data: (d) => d.recentTransactions.isEmpty
                    ? const SliverToBoxAdapter(
                        child: FinaEmptyState(
                          emoji: '📭',
                          title: 'Belum ada transaksi',
                          subtitle: 'Mulai catat pemasukan atau pengeluaranmu',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) =>
                              _TransactionTile(tx: d.recentTransactions[i]),
                          childCount: d.recentTransactions.length,
                        ),
                      ),
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(
                          4,
                          (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: FinaSkeletonBox(height: 64, radius: 16),
                              )),
                    ),
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: FinaColors.copper,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Card
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final DashboardSummary summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1E27), Color(0xFF13161C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: FinaColors.copper2, size: 14),
            const SizedBox(width: 6),
            Text('TOTAL SALDO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FinaColors.copper2,
                      letterSpacing: 2,
                    )),
          ]),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => kCopperGradient.createShader(b),
            child: Text(
              formatCurrency(summary.totalBalance),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _MiniStat(
              icon: '📈',
              label: 'Pemasukan',
              value: formatCurrency(summary.incomeThisMonth),
              color: FinaColors.green,
            ),
            Container(
              width: 1,
              height: 32,
              color: FinaColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _MiniStat(
              icon: '📉',
              label: 'Pengeluaran',
              value: formatCurrency(summary.expenseThisMonth),
              color: FinaColors.red,
            ),
          ]),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: FinaColors.text2)),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    (icon: '📥', label: 'Pemasukan', route: '/transactions/add?type=income'),
    (icon: '📤', label: 'Pengeluaran', route: '/transactions/add?type=expense'),
    (icon: '🔄', label: 'Transfer', route: '/transactions/transfer'),
    (icon: '📊', label: 'Rekening', route: '/accounts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _actions
          .map((a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => context.push(a.route),
                    child: FinaCard(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Text(a.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(
                            a.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: FinaColors.text2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Row
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final DashboardSummary summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final net = summary.netThisMonth;
    return FinaCard(
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bulan ini',
                style: TextStyle(
                    fontSize: 10,
                    color: FinaColors.text2,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${net >= 0 ? '+' : ''}${formatCurrency(net)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: net >= 0 ? FinaColors.green : FinaColors.red,
              ),
            ),
          ]),
        ),
        FinaPill(
          net >= 0 ? 'Surplus' : 'Defisit',
          variant: net >= 0 ? PillVariant.green : PillVariant.red,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Chip
// ─────────────────────────────────────────────────────────────────────────────
class _AccountChip extends StatelessWidget {
  final AccountModel account;
  const _AccountChip({required this.account});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/accounts'),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FinaColors.copper2,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Tile
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onTap: () => context.push('/transactions/${tx.id}'),
        child: FinaCard(
          padding: const EdgeInsets.all(12),
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
                Text(tx.category?.name ?? tx.type,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  tx.note ?? tx.account?.name ?? '',
                  style: const TextStyle(fontSize: 11, color: FinaColors.text2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AmountText(amount: tx.amount, type: tx.type, fontSize: 13),
              Text(formatDate(tx.date, pattern: 'd MMM'),
                  style:
                      const TextStyle(fontSize: 10, color: FinaColors.text2)),
            ]),
          ]),
        ),
      ),
    );
  }
}
