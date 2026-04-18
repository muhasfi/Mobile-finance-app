import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/shared_widgets.dart';

// ── Safe numeric parser ──────────────────────────────────────────────────────
double _safeDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

// ── Date helpers ─────────────────────────────────────────────────────────────
String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _displayDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Color _hexColor(String hex) {
  try {
    final c = hex.replaceAll('#', '');
    if (c.length == 6) return Color(int.parse('FF$c', radix: 16));
  } catch (_) {}
  return FinaColors.copper;
}

// ── Filter state ─────────────────────────────────────────────────────────────
class _FilterState {
  final DateTime from;
  final DateTime to;
  final String? type;
  final String? accountId;
  final String? categoryId;

  const _FilterState({
    required this.from,
    required this.to,
    this.type,
    this.accountId,
    this.categoryId,
  });

  _FilterState copyWith({
    DateTime? from,
    DateTime? to,
    Object? type = _s,
    Object? accountId = _s,
    Object? categoryId = _s,
  }) =>
      _FilterState(
        from: from ?? this.from,
        to: to ?? this.to,
        type: type == _s ? this.type : type as String?,
        accountId: accountId == _s ? this.accountId : accountId as String?,
        categoryId: categoryId == _s ? this.categoryId : categoryId as String?,
      );

  Map<String, String> toParams() => {
        'from': _fmtDate(from),
        'to': _fmtDate(to),
        if (type != null && type!.isNotEmpty) 'type': type!,
        if (accountId != null && accountId!.isNotEmpty)
          'account_id': accountId!,
        if (categoryId != null && categoryId!.isNotEmpty)
          'category_id': categoryId!,
      };

  static const _s = Object();
}

// ── Providers ────────────────────────────────────────────────────────────────
final _filterProvider = StateProvider<_FilterState>((_) {
  final now = DateTime.now();
  return _FilterState(
    from: DateTime(now.year, now.month, 1),
    to: now,
  );
});

// Dropdown meta: accounts & categories dari API
// Endpoint: GET /api/reports/filter-meta
// Response: { data: { accounts: [{id,name}], categories: [{id,name}] } }
final _filterMetaProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((_) async {
  final res = await ApiService().get(ApiConstants.reportFilterMeta);
  final data = res['data'] ?? res;
  return Map<String, dynamic>.from(data as Map);
});

// Laporan range: sesuai ReportController@range
// GET /api/reports/range?from=&to=&type=&account_id=&category_id=
final _rangeReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, _FilterState>((ref, filter) async {
  final res = await ApiService().get(
    ApiConstants.reportRange,
    params: filter.toParams(),
  );
  final data = res['data'];
  if (data is Map<String, dynamic>) return data;
  return Map<String, dynamic>.from(res as Map);
});

// Tren 6 bulan: sesuai ReportController@trend
final _trendProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((_) async {
  try {
    final res = await ApiService().get(ApiConstants.reportTrend);
    final data = res['data'];
    if (data is List && data.isNotEmpty) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  } catch (_) {}
  return [];
});

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Laporan & Export',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 22)),
              const SizedBox(height: 2),
              const Text('Export transaksi ke CSV atau PDF',
                  style: TextStyle(fontSize: 12, color: FinaColors.text2)),
            ]),
          ),

          // ── Tabs ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: FinaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FinaColors.border),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: FinaColors.text2,
                indicator: BoxDecoration(
                  color: FinaColors.copper,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Filter & Export'),
                  Tab(text: 'Tren 6 Bulan'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _FilterExportTab(),
                _TrendTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Filter & Export  (padanan index.blade.php)
// ─────────────────────────────────────────────────────────────────────────────
class _FilterExportTab extends ConsumerStatefulWidget {
  const _FilterExportTab();

  @override
  ConsumerState<_FilterExportTab> createState() => _FilterExportTabState();
}

class _FilterExportTabState extends ConsumerState<_FilterExportTab> {
  bool _exporting = false;

  // ── Shortcut periode — identik dengan setRange() di blade ─────────────────
  void _setRange(String range) {
    final now = DateTime.now();
    late DateTime from, to;
    switch (range) {
      case 'this_month':
        from = DateTime(now.year, now.month, 1);
        to = now;
        break;
      case 'last_month':
        from = DateTime(now.year, now.month - 1, 1);
        to = DateTime(now.year, now.month, 0);
        break;
      case 'this_year':
        from = DateTime(now.year, 1, 1);
        to = now;
        break;
      case 'last_3_months':
        from = DateTime(now.year, now.month - 3, 1);
        to = now;
        break;
    }
    ref
        .read(_filterProvider.notifier)
        .update((s) => s.copyWith(from: from, to: to));
  }

  // ── Export — download file langsung via Dio dengan Bearer token ─────────────
  Future<void> _export(String fmt) async {
    final filter = ref.read(_filterProvider);

    // Ambil token dari ApiService (sama seperti request lainnya)
    final token = await ApiService().getToken();
    if (token == null) {
      _snack('Sesi habis, silakan login ulang.', error: true);
      return;
    }

    final endpoint = fmt == 'pdf'
        ? ApiConstants.reportExportPdf
        : ApiConstants.reportExportCsv;
    final url = '${ApiConstants.baseUrl}$endpoint';
    final params = filter.toParams();
    final ext = fmt == 'pdf' ? 'pdf' : 'csv';
    final filename = 'laporan_${params['from']}_sd_${params['to']}.$ext';

    setState(() => _exporting = true);
    try {
      // Tentukan direktori simpan
      Directory dir;
      if (Platform.isAndroid) {
        // Simpan ke Downloads agar mudah ditemukan user
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir.path}/$filename';

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        queryParameters: params,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: (received, total) {
          // Progress bisa di-extend ke UI jika perlu
        },
      );

      if (!mounted) return;

      // Buka file setelah download selesai
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        _snack('File tersimpan di: $savePath');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 401
          ? 'Sesi habis, silakan login ulang.'
          : e.response?.statusCode == 422
              ? 'Filter tidak valid, periksa tanggal.'
              : 'Gagal mengunduh file: ${e.message}';
      _snack(msg, error: true);
    } catch (e) {
      if (mounted) _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : FinaColors.surface,
        duration: const Duration(seconds: 3),
      ));

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_filterProvider);
    final metaAsync = ref.watch(_filterMetaProvider);
    final reportAsync = ref.watch(_rangeReportProvider(filter));

    return RefreshIndicator(
      color: FinaColors.copper,
      backgroundColor: FinaColors.surface,
      onRefresh: () => ref.refresh(_rangeReportProvider(filter).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── CARD Filter Laporan (kiri di blade, full-width di mobile) ─────
          FinaCard(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.tune_rounded,
                    size: 15, color: FinaColors.copper),
                const SizedBox(width: 6),
                Text('Filter Laporan',
                    style: Theme.of(context).textTheme.titleSmall),
              ]),
              const SizedBox(height: 14),

              // Dari Tanggal & Sampai Tanggal — row sejajar seperti blade col-md-6
              Row(children: [
                Expanded(
                  child: _DateField(
                    label: 'Dari Tanggal *',
                    value: filter.from,
                    lastDate: filter.to,
                    onPicked: (d) => ref
                        .read(_filterProvider.notifier)
                        .update((s) => s.copyWith(from: d)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'Sampai Tanggal *',
                    value: filter.to,
                    firstDate: filter.from,
                    onPicked: (d) => ref
                        .read(_filterProvider.notifier)
                        .update((s) => s.copyWith(to: d)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // Tipe Transaksi & Rekening — row sejajar seperti blade col-md-6
              Row(children: [
                Expanded(
                  child: _DropdownField<String?>(
                    label: 'Tipe Transaksi',
                    value: filter.type,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua tipe')),
                      DropdownMenuItem(
                          value: 'income', child: Text('Pemasukan')),
                      DropdownMenuItem(
                          value: 'expense', child: Text('Pengeluaran')),
                      DropdownMenuItem(
                          value: 'transfer', child: Text('Transfer')),
                    ],
                    onChanged: (v) => ref
                        .read(_filterProvider.notifier)
                        .update((s) => s.copyWith(type: v)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: metaAsync.when(
                    data: (meta) {
                      final accounts = (meta['accounts'] as List? ?? [])
                          .whereType<Map>()
                          .toList();
                      return _DropdownField<String?>(
                        label: 'Rekening',
                        value: filter.accountId,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Semua rekening')),
                          ...accounts.map((a) => DropdownMenuItem(
                              value: a['id']?.toString(),
                              child: Text(
                                a['name']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ))),
                        ],
                        onChanged: (v) => ref
                            .read(_filterProvider.notifier)
                            .update((s) => s.copyWith(accountId: v)),
                      );
                    },
                    loading: () => const _DropdownSkeleton(label: 'Rekening'),
                    error: (_, __) =>
                        const _DropdownSkeleton(label: 'Rekening'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // Kategori — full width seperti blade col-md-12
              metaAsync.when(
                data: (meta) {
                  final cats = (meta['categories'] as List? ?? [])
                      .whereType<Map>()
                      .toList();
                  return _DropdownField<String?>(
                    label: 'Kategori',
                    value: filter.categoryId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Semua kategori')),
                      ...cats.map((c) => DropdownMenuItem(
                          value: c['id']?.toString(),
                          child: Text(c['name']?.toString() ?? ''))),
                    ],
                    onChanged: (v) => ref
                        .read(_filterProvider.notifier)
                        .update((s) => s.copyWith(categoryId: v)),
                  );
                },
                loading: () => const _DropdownSkeleton(label: 'Kategori'),
                error: (_, __) => const _DropdownSkeleton(label: 'Kategori'),
              ),
              const SizedBox(height: 16),

              // Tombol Download CSV & PDF — seperti blade d-flex gap-2
              Row(children: [
                Expanded(
                  child: _ExportButton(
                    icon: Icons.table_chart_rounded,
                    label: 'Download CSV',
                    color: const Color(0xFF16a34a),
                    loading: _exporting,
                    onTap: () => _export('csv'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ExportButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Download PDF',
                    color: FinaColors.red,
                    loading: _exporting,
                    onTap: () => _export('pdf'),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // ── CARD Shortcut Periode (kanan di blade) ────────────────────────
          FinaCard(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Shortcut Periode',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              _ShortcutBtn(
                icon: Icons.calendar_month_rounded,
                label: 'Bulan ini',
                onTap: () => _setRange('this_month'),
              ),
              const SizedBox(height: 8),
              _ShortcutBtn(
                icon: Icons.calendar_today_rounded,
                label: 'Bulan lalu',
                onTap: () => _setRange('last_month'),
              ),
              const SizedBox(height: 8),
              _ShortcutBtn(
                icon: Icons.date_range_rounded,
                label: 'Tahun ini (${DateTime.now().year})',
                onTap: () => _setRange('this_year'),
              ),
              const SizedBox(height: 8),
              _ShortcutBtn(
                icon: Icons.calendar_view_month_rounded,
                label: '3 bulan terakhir',
                onTap: () => _setRange('last_3_months'),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Periode aktif ─────────────────────────────────────────────────
          Center(
            child: Text(
              '${_displayDate(filter.from)} – ${_displayDate(filter.to)}',
              style: const TextStyle(fontSize: 11, color: FinaColors.text2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Hasil ringkasan dari API /reports/range ────────────────────────
          reportAsync.when(
            data: (data) => _RangeSummary(data: data),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: FinaColors.copper),
              ),
            ),
            error: (e, _) => FinaErrorWidget(
              message: e.toString(),
              onRetry: () => ref.refresh(_rangeReportProvider(filter)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ringkasan periode + breakdown kategori ────────────────────────────────────
class _RangeSummary extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RangeSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final income = _safeDouble(data['income']);
    final expense = _safeDouble(data['expense']);
    final balance = _safeDouble(data['balance'] ?? (income - expense));
    final count = data['count'] ?? 0;
    final byCategory = (data['by_category'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ringkasan Periode', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 10),

      // Summary card
      FinaCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          _SummaryRow(
              icon: Icons.arrow_downward_rounded,
              label: 'Total Pemasukan',
              value: income,
              color: FinaColors.green),
          const FinaDivider(),
          _SummaryRow(
              icon: Icons.arrow_upward_rounded,
              label: 'Total Pengeluaran',
              value: expense,
              color: FinaColors.red),
          const FinaDivider(),
          _SummaryRow(
              icon: Icons.account_balance_wallet_rounded,
              label: balance >= 0 ? 'Selisih (Surplus)' : 'Selisih (Defisit)',
              value: balance.abs(),
              color: balance >= 0 ? FinaColors.green : FinaColors.red),
          const FinaDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 14, color: FinaColors.text2),
              const SizedBox(width: 8),
              const Text('Jumlah Transaksi',
                  style: TextStyle(fontSize: 12, color: FinaColors.text2)),
              const Spacer(),
              Text('$count transaksi',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),

      // By category
      if (byCategory.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Pengeluaran per Kategori',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        ...byCategory.map((cat) {
          final name = cat['name'] as String? ?? 'Tanpa Kategori';
          final total = _safeDouble(cat['total']);
          final pct = _safeDouble(cat['percentage']) / 100;
          final color = _hexColor(cat['color'] as String? ?? '#6b7280');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinaCard(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  _ColorDot(color: color),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(formatCurrency(total),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FinaColors.red)),
                  const SizedBox(width: 8),
                  Text('${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 11, color: FinaColors.text2)),
                ]),
                const SizedBox(height: 8),
                FinaProgressBar(
                    progress: pct.clamp(0.0, 1.0), danger: pct > 0.5),
              ]),
            ),
          );
        }),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Tren 6 Bulan (tidak berubah)
// ─────────────────────────────────────────────────────────────────────────────
class _TrendTab extends ConsumerWidget {
  const _TrendTab();

  static const _ml = [
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

  String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_trendProvider).when(
          data: (months) {
            if (months.isEmpty) {
              return const FinaEmptyState(
                emoji: '📊',
                title: 'Belum ada data tren',
                subtitle:
                    'Tambah lebih banyak transaksi untuk melihat tren keuangan',
              );
            }

            final incomes =
                months.map((m) => _safeDouble(m['income'])).toList();
            final expenses =
                months.map((m) => _safeDouble(m['expense'])).toList();
            final maxY =
                [...incomes, ...expenses].fold(0.0, (a, b) => a > b ? a : b) *
                    1.25;

            final now = DateTime.now();
            final labels = List.generate(months.length, (i) {
              final m = months[i]['month'];
              if (m != null) {
                final idx =
                    (m is int ? m : int.tryParse(m.toString()) ?? 1) - 1;
                return _ml[idx.clamp(0, 11)];
              }
              final d = DateTime(now.year, now.month - (months.length - 1 - i));
              return _ml[d.month - 1];
            });

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // Bar chart
                FinaCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arus Kas 6 Bulan',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        const Row(children: [
                          _LegendDot(
                              color: FinaColors.green, label: 'Pemasukan'),
                          SizedBox(width: 16),
                          _LegendDot(
                              color: FinaColors.red, label: 'Pengeluaran'),
                        ]),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(BarChartData(
                            maxY: maxY > 0 ? maxY : 1000000,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => const FlLine(
                                  color: FinaColors.border, strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    return Text(
                                        i < labels.length ? labels[i] : '',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: FinaColors.text2));
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(
                                months.length,
                                (i) => BarChartGroupData(
                                      x: i,
                                      barsSpace: 4,
                                      barRods: [
                                        BarChartRodData(
                                            toY: incomes[i],
                                            color: FinaColors.green,
                                            width: 8,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        BarChartRodData(
                                            toY: expenses[i],
                                            color: FinaColors.red,
                                            width: 8,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                      ],
                                    )),
                          )),
                        ),
                      ]),
                ),
                const SizedBox(height: 16),

                // Line chart tabungan bersih
                FinaCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tabungan Bersih per Bulan',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 140,
                          child: LineChart(LineChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    return Text(
                                        i < labels.length ? labels[i] : '',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: FinaColors.text2));
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                    months.length,
                                    (i) => FlSpot(
                                          i.toDouble(),
                                          (incomes[i] - expenses[i])
                                              .clamp(0, double.infinity),
                                        )),
                                isCurved: true,
                                color: FinaColors.copper,
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                    show: true, color: const Color(0x1AC8783A)),
                              ),
                            ],
                          )),
                        ),
                      ]),
                ),
                const SizedBox(height: 16),

                // Tabel ringkasan
                FinaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Row(children: [
                      Expanded(
                          flex: 2,
                          child: Text('Bulan',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: FinaColors.text2))),
                      Expanded(
                          flex: 3,
                          child: Text('Masuk',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: FinaColors.green),
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 3,
                          child: Text('Keluar',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: FinaColors.red),
                              textAlign: TextAlign.right)),
                    ]),
                    const SizedBox(height: 8),
                    const FinaDivider(),
                    ...List.generate(
                        months.length,
                        (i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(labels[i],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    flex: 3,
                                    child: Text(_compact(incomes[i]),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: FinaColors.green),
                                        textAlign: TextAlign.right)),
                                Expanded(
                                    flex: 3,
                                    child: Text(_compact(expenses[i]),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: FinaColors.red),
                                        textAlign: TextAlign.right)),
                              ]),
                            )),
                  ]),
                ),
              ],
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: FinaColors.copper)),
          error: (e, _) => FinaErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(_trendProvider),
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: FinaColors.text2)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: FinaColors.copper,
                      surface: FinaColors.surface,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (d != null) onPicked(d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: FinaColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FinaColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: FinaColors.text2),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(_displayDate(value),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          ),
        ],
      );
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: FinaColors.text2)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: FinaColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FinaColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: FinaColors.surface,
                style: const TextStyle(fontSize: 12, color: FinaColors.text),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );
}

class _DropdownSkeleton extends StatelessWidget {
  final String label;
  const _DropdownSkeleton({required this.label});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: FinaColors.text2)),
          const SizedBox(height: 4),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: FinaColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FinaColors.border),
            ),
          ),
        ],
      );
}

class _ShortcutBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: FinaColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FinaColors.border),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: FinaColors.copper),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: FinaColors.text2),
          ]),
        ),
      );
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(loading ? 10 : 20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: color),
                  ),
                )
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ]),
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: FinaColors.text2))),
          Text(formatCurrency(value),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80)),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: FinaColors.text2)),
      ]);
}
