import 'dart:math' as math;
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

final dashboardBudgetProvider =
    FutureProvider.autoDispose<List<BudgetModel>>((ref) async {
  final now = DateTime.now();
  return BudgetRepository().getAll(month: now.month, year: now.year);
});

// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  // AI label animation — muncul sekali lalu terseret ke icon
  late AnimationController _labelController;
  late Animation<double> _labelOpacity;
  late Animation<Offset> _labelSlide;
  bool _labelDone = false;

  // Menu FAB expand/collapse — staggered per item
  late AnimationController _menuController;
  // item 0 = Transaksi Berulang, item 1 = Kelola Kategori
  late Animation<double> _item0Fade;
  late Animation<Offset> _item0Slide;
  late Animation<double> _item0Scale;
  late Animation<double> _item1Fade;
  late Animation<Offset> _item1Slide;
  late Animation<double> _item1Scale;
  // Backdrop blur overlay
  late Animation<double> _backdropAnim;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();

    // Label AI
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _labelOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _labelController, curve: Curves.easeIn),
    );
    _labelSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0.0),
    ).animate(
      CurvedAnimation(parent: _labelController, curve: Curves.easeInBack),
    );
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _labelController.forward().then((_) {
        if (mounted) setState(() => _labelDone = true);
      });
    });

    // Menu FAB — durasi total 340ms, stagger 60ms antar item
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    // Item 0 (Transaksi Berulang) — mulai langsung, selesai di 70%
    final item0Curve = CurvedAnimation(
      parent: _menuController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.28, 1.0, curve: Curves.easeInCubic),
    );
    _item0Fade = Tween<double>(begin: 0.0, end: 1.0).animate(item0Curve);
    _item0Scale = Tween<double>(begin: 0.7, end: 1.0).animate(item0Curve);
    _item0Slide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(item0Curve);

    // Item 1 (Kelola Kategori) — stagger 60ms, mulai di 18%
    final item1Curve = CurvedAnimation(
      parent: _menuController,
      curve: const Interval(0.18, 0.9, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.1, 0.82, curve: Curves.easeInCubic),
    );
    _item1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(item1Curve);
    _item1Scale = Tween<double>(begin: 0.7, end: 1.0).animate(item1Curve);
    _item1Slide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(item1Curve);

    // Backdrop overlay — fade cepat
    _backdropAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _menuController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    if (_menuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _closeMenu() {
    if (_menuOpen) {
      setState(() => _menuOpen = false);
      _menuController.reverse();
    }
  }

  void _closeFab() => _closeMenu();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      body: GestureDetector(
        onTap: _closeFab,
        child: SafeArea(
          child: RefreshIndicator(
            color: FinaColors.copper,
            backgroundColor: FinaColors.surface,
            onRefresh: () => ref.refresh(dashboardProvider.future),
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selamat datang 👋',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(_greeting(),
                                style: Theme.of(context).textTheme.titleLarge),
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

                // ── Total Balance Card ────────────────────────────────────────
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

                // ── AI Highlight Banner ───────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _AiBanner(),
                  ),
                ),

                // ── Rekening ─────────────────────────────────────────────────
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

                // ── Budget Bulan Ini ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: ref.watch(dashboardBudgetProvider).when(
                          data: (budgets) => budgets.isEmpty
                              ? const SizedBox()
                              : _BudgetSection(budgets: budgets),
                          loading: () =>
                              const FinaSkeletonBox(height: 100, radius: 16),
                          error: (_, __) => const SizedBox(),
                        ),
                  ),
                ),

                // ── Transaksi terakhir ────────────────────────────────────────
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
                            subtitle:
                                'Mulai catat pemasukan atau pengeluaranmu',
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
                                  child:
                                      FinaSkeletonBox(height: 64, radius: 16),
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
      ),

      // ── Triple FAB: Menu (atas) + AI Chat + Tambah (bawah) ──────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Menu items — staggered slide-up + fade + scale ───────────────
          // Item 0: Transaksi Berulang
          AnimatedBuilder(
            animation: _menuController,
            builder: (context, child) => IgnorePointer(
              ignoring: !_menuOpen,
              child: FadeTransition(
                opacity: _item0Fade,
                child: SlideTransition(
                  position: _item0Slide,
                  child: ScaleTransition(
                    scale: _item0Scale,
                    alignment: Alignment.centerRight,
                    child: child,
                  ),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MenuFabItem(
                icon: Icons.repeat_rounded,
                label: 'Transaksi Berulang',
                subtitle: 'Atur pembayaran rutin',
                color: FinaColors.purple,
                bgColor: FinaColors.icPurple,
                borderColor: const Color(0x40A078DC),
                onTap: () {
                  _closeMenu();
                  context.push('/recurring');
                },
              ),
            ),
          ),

          // Item 1: Kelola Kategori
          AnimatedBuilder(
            animation: _menuController,
            builder: (context, child) => IgnorePointer(
              ignoring: !_menuOpen,
              child: FadeTransition(
                opacity: _item1Fade,
                child: SlideTransition(
                  position: _item1Slide,
                  child: ScaleTransition(
                    scale: _item1Scale,
                    alignment: Alignment.centerRight,
                    child: child,
                  ),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MenuFabItem(
                icon: Icons.category_rounded,
                label: 'Kelola Kategori',
                subtitle: 'Tambah & edit kategori',
                color: FinaColors.copper2,
                bgColor: FinaColors.icCopper,
                borderColor: const Color(0x40C8783A),
                onTap: () {
                  _closeMenu();
                  context.push('/categories');
                },
              ),
            ),
          ),

          // ── Menu FAB ────────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _menuOpen ? FinaColors.surface2 : FinaColors.surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      _menuOpen ? const Color(0x30C8783A) : FinaColors.border,
                  width: _menuOpen ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _menuOpen
                        ? const Color(0x30C8783A)
                        : const Color(0x40000000),
                    blurRadius: _menuOpen ? 18 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedRotation(
                turns: _menuOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.grid_view_rounded,
                  color: _menuOpen ? FinaColors.copper : FinaColors.text,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── AI FAB ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              _closeMenu();
              context.push('/ai/chat');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_labelDone)
                  SlideTransition(
                    position: _labelSlide,
                    child: FadeTransition(
                      opacity: _labelOpacity,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1830),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x55A078DC)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Fina AI Chat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FinaColors.purple,
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B3FA0), Color(0xFF3D1F6E)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x55A078DC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40A078DC),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const _AiSparkIcon(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Spark Icon — ikon bintang AI modern
// ─────────────────────────────────────────────────────────────────────────────
class _AiSparkIcon extends StatelessWidget {
  const _AiSparkIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _SparkPainter()),
    );
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Bintang 4 sudut (sparkle / AI star shape)
    void drawStar(double x, double y, double r1, double r2) {
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) - math.pi / 8;
        final r = i.isEven ? r1 : r2;
        final px = x + r * math.cos(angle);
        final py = y + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Bintang utama
    paint.color = Colors.white;
    drawStar(cx, cy, size.width * 0.42, size.width * 0.16);

    // Bintang kecil kanan atas
    paint.color = Colors.white.withOpacity(0.75);
    drawStar(
      cx + size.width * 0.32,
      cy - size.height * 0.28,
      size.width * 0.12,
      size.width * 0.05,
    );

    // Titik kecil kiri bawah
    paint.color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(
      Offset(cx - size.width * 0.28, cy + size.height * 0.3),
      size.width * 0.055,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu FAB Item — solid card dengan ikon + label + subtitle
// ─────────────────────────────────────────────────────────────────────────────
class _MenuFabItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _MenuFabItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_MenuFabItem> createState() => _MenuFabItemState();
}

class _MenuFabItemState extends State<_MenuFabItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Label card ─────────────────────────────────────────────────
            Container(
              constraints: const BoxConstraints(minWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: FinaColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: Color(0x50000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FinaColors.text2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── Icon button ────────────────────────────────────────────────
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.30),
                    widget.color.withOpacity(0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: widget.color.withOpacity(0.55), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: Color(0x50000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Banner — highlight di tengah dashboard (hanya Insight)
// ─────────────────────────────────────────────────────────────────────────────
class _AiBanner extends StatelessWidget {
  const _AiBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1830), Color(0xFF13161C)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33A078DC)),
      ),
      child: Row(
        children: [
          // Ikon AI modern dengan gradient
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6B3FA0), Color(0xFF3D1F6E)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x50A078DC),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _SparkPainter()),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fina AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FinaColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lihat analisa keuangan bulananmu',
                  style: TextStyle(fontSize: 11, color: FinaColors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Hanya tombol Insight
          GestureDetector(
            onTap: () => context.push('/ai/insight'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B3FA0), Color(0xFF3D1F6E)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40A078DC),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Insight',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        // ── Pemasukan / Pengeluaran (kiri) + Net summary (kanan) ─────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Kiri: Pemasukan & Pengeluaran column ───────────────────
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x14000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FinaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pemasukan
                      Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: FinaColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Pemasukan',
                            style: TextStyle(
                                fontSize: 10, color: FinaColors.text2)),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        formatCurrency(summary.incomeThisMonth),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FinaColors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Divider tipis
                      Container(height: 1, color: FinaColors.border),
                      const SizedBox(height: 10),
                      // Pengeluaran
                      Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: FinaColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Pengeluaran',
                            style: TextStyle(
                                fontSize: 10, color: FinaColors.text2)),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        formatCurrency(summary.expenseThisMonth),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FinaColors.red,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── Kanan: Net bulan ini ────────────────────────────────────
              Builder(builder: (_) {
                final net = summary.netThisMonth;
                final isPositive = net >= 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x14000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FinaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bulan ini',
                        style: const TextStyle(
                            fontSize: 10, color: FinaColors.text2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isPositive ? '+' : ''}${formatCurrency(net)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPositive ? FinaColors.green : FinaColors.red,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? FinaColors.pillGreen
                              : FinaColors.pillRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPositive ? 'Surplus' : 'Defisit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                isPositive ? FinaColors.green : FinaColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature Shortcuts — Kelola Kategori & Transaksi Berulang
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureShortcuts extends StatelessWidget {
  const _FeatureShortcuts();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureTile(
            icon: Icons.category_outlined,
            emoji: '🗂️',
            label: 'Kelola Kategori',
            onTap: () => context.push('/categories'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeatureTile(
            icon: Icons.repeat_rounded,
            emoji: '🔁',
            label: 'Transaksi Berulang',
            onTap: () => context.push('/recurring'),
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FinaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FinaColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: FinaColors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FinaColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: FinaColors.muted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Row
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Budget Section
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetSection extends StatelessWidget {
  final List<BudgetModel> budgets;
  const _BudgetSection({required this.budgets});

  @override
  Widget build(BuildContext context) {
    // Tampilkan max 3 budget teratas
    final shown = budgets.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Budget Bulan Ini',
              style: Theme.of(context).textTheme.titleSmall),
          GestureDetector(
            onTap: () => context.push('/budget'),
            child: const Text('Lihat semua',
                style: TextStyle(color: FinaColors.copper, fontSize: 12)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      FinaCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: List.generate(shown.length, (i) {
            final b = shown[i];
            final pct = (b.progress * 100).round();
            final barColor = b.isOver
                ? FinaColors.red
                : b.isNearLimit
                    ? FinaColors.copper
                    : FinaColors.green;
            return Column(children: [
              if (i > 0) const FinaDivider(indent: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (b.category != null)
                        IconCircle(
                          icon: b.category!.icon,
                          bgColor: FinaColors.icCopper,
                        ),
                      if (b.category != null) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.category?.name ?? 'Total Budget',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FinaColors.text,
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatCurrency(b.remaining),
                        style: const TextStyle(
                            fontSize: 11, color: FinaColors.text2),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: b.progress,
                        minHeight: 5,
                        backgroundColor: FinaColors.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Chip
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
