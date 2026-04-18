import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/shared_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class InsightData {
  final String summary;
  final List<String> achievements, warnings, recommendations;
  final bool cached;
  final int month, year;

  const InsightData({
    required this.summary,
    required this.achievements,
    required this.warnings,
    required this.recommendations,
    required this.cached,
    required this.month,
    required this.year,
  });

  factory InsightData.fromJson(Map<String, dynamic> j) {
    // Dukung 2 format response: { data: { insight: {...} } } dan { insight: {...} }
    final root    = (j['data'] ?? j) as Map<String, dynamic>;
    final insight = root['insight'] as Map<String, dynamic>? ?? root;
    return InsightData(
      summary:         insight['summary']         as String? ?? '',
      achievements:    List<String>.from(insight['achievements']    ?? []),
      warnings:        List<String>.from(insight['warnings']        ?? []),
      recommendations: List<String>.from(insight['recommendations'] ?? []),
      cached: root['cached'] as bool? ?? false,
      month:  root['month']  as int?  ?? DateTime.now().month,
      year:   root['year']   as int?  ?? DateTime.now().year,
    );
  }
}

// ── Period wrapper ─────────────────────────────────────────────────────────────
class _InsightPeriod {
  final int month, year;
  const _InsightPeriod(this.month, this.year);

  @override
  bool operator ==(Object o) =>
      o is _InsightPeriod && o.month == month && o.year == year;

  @override
  int get hashCode => Object.hash(month, year);
}

final _insightPeriodProvider = StateProvider(
    (_) => _InsightPeriod(DateTime.now().month, DateTime.now().year));

final insightProvider = FutureProvider.autoDispose
    .family<InsightData, _InsightPeriod>((ref, p) async {
  final res = await ApiService().get(ApiConstants.aiInsights,
    params: {'month': p.month, 'year': p.year});
  return InsightData.fromJson(res);
});

// ─────────────────────────────────────────────────────────────────────────────
class AiInsightScreen extends ConsumerWidget {
  const AiInsightScreen({super.key});

  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des',
  ];
  static const _monthsFull = [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_insightPeriodProvider);
    final async  = ref.watch(insightProvider(period));

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: Text('✨  Insight ${_monthsFull[period.month - 1]}'),
        actions: [
          Row(children: [
            IconButton(
              onPressed: () {
                final d = DateTime(period.year, period.month - 1);
                ref.read(_insightPeriodProvider.notifier).state =
                    _InsightPeriod(d.month, d.year);
              },
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
            ),
            Text('${_months[period.month - 1]} ${period.year}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            IconButton(
              onPressed: () {
                final now = DateTime.now();
                final d   = DateTime(period.year, period.month + 1);
                if (!d.isAfter(DateTime(now.year, now.month))) {
                  ref.read(_insightPeriodProvider.notifier).state =
                      _InsightPeriod(d.month, d.year);
                }
              },
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ]),
        ],
      ),
      body: async.when(
        data: (insight) => RefreshIndicator(
          color: FinaColors.copper,
          backgroundColor: FinaColors.surface,
          onRefresh: () => ref.refresh(insightProvider(period).future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0x12C8783A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x2EC8783A)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [FinaColors.copper, Color(0xFF8B4A1A)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🤖', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Ringkasan Fina', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Analisa ${_monthsFull[insight.month - 1]} ${insight.year}',
                        style: const TextStyle(fontSize: 10, color: FinaColors.text2)),
                    ]),
                    const Spacer(),
                    if (insight.cached)
                      const FinaPill('Cache', variant: PillVariant.blue),
                  ]),
                  const SizedBox(height: 14),
                  Text(
                    insight.summary.isNotEmpty
                        ? insight.summary
                        : 'Tidak ada data cukup untuk insight bulan ini.',
                    style: const TextStyle(
                      fontSize: 13, color: FinaColors.cream2, height: 1.6),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              if (insight.achievements.isNotEmpty) ...[
                _InsightCard(
                  icon: '🎯', title: 'Pencapaian',
                  items: insight.achievements,
                  itemIcon: '✓', itemColor: FinaColors.green,
                ),
                const SizedBox(height: 12),
              ],
              if (insight.warnings.isNotEmpty) ...[
                _InsightCard(
                  icon: '⚠️', title: 'Perhatian',
                  items: insight.warnings,
                  itemIcon: '!', itemColor: FinaColors.red,
                ),
                const SizedBox(height: 12),
              ],
              if (insight.recommendations.isNotEmpty) ...[
                _InsightCard(
                  icon: '💡', title: 'Rekomendasi Bulan Depan',
                  items: insight.recommendations,
                  itemIcon: '→', itemColor: FinaColors.copper2,
                ),
                const SizedBox(height: 12),
              ],
              if (insight.summary.isEmpty &&
                  insight.achievements.isEmpty &&
                  insight.warnings.isEmpty)
                const FinaEmptyState(
                  emoji: '🤖',
                  title: 'Belum ada insight',
                  subtitle: 'Tambah lebih banyak transaksi agar AI bisa menganalisa pola keuanganmu',
                ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _regenerate(context, ref, period),
                icon: const Icon(Icons.auto_awesome_outlined, size: 16,
                  color: FinaColors.copper),
                label: const Text('Generate Ulang Insight',
                  style: TextStyle(color: FinaColors.copper)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: FinaColors.copper),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🤖', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: FinaColors.copper),
              SizedBox(height: 16),
              Text('Fina sedang menganalisa keuanganmu...',
                style: TextStyle(color: FinaColors.text2, fontSize: 13)),
            ],
          ),
        ),
        error: (e, _) {
          final msg = e.toString();
          if (msg.contains('belum diaktifkan') || msg.contains('503')) {
            return const _AiDisabledState();
          }
          return FinaErrorWidget(
            message: msg,
            onRetry: () => ref.refresh(insightProvider(period)),
          );
        },
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref,
      _InsightPeriod period) async {
    try {
      await ApiService().post(ApiConstants.aiInsightsGen, data: {
        'month': period.month,
        'year':  period.year,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Insight sedang diproses... Cek kembali dalam beberapa detik ✨')));
      }
      await Future.delayed(const Duration(seconds: 3));
      ref.refresh(insightProvider(period));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)));
    }
  }
}

class _InsightCard extends StatelessWidget {
  final String icon, title, itemIcon;
  final List<String> items;
  final Color itemColor;
  const _InsightCard({
    required this.icon, required this.title,
    required this.items, required this.itemIcon, required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return FinaCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(itemIcon, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: itemColor)),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: const TextStyle(
                fontSize: 12, color: FinaColors.text, height: 1.5))),
            ],
          ),
        )),
      ]),
    );
  }
}

class _AiDisabledState extends StatelessWidget {
  const _AiDisabledState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: FinaColors.icCopper,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            const Text('Fitur AI Belum Aktif',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Administrator perlu mengatur GEMINI_API_KEY di server untuk mengaktifkan fitur AI.',
              style: TextStyle(fontSize: 13, color: FinaColors.text2, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
