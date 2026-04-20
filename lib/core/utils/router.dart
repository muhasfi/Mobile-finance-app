import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../features/transactions/add_transaction_screen.dart';
import '../../features/transactions/edit_transaction_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/transfer_screen.dart';
import '../../features/accounts/accounts_screen.dart';
import '../../features/accounts/account_transactions_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/budget/budget_screen.dart';
import '../../features/recurring/recurring_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/ai/ai_chat_screen.dart';
import '../../features/ai/ai_insight_screen.dart';
import '../../features/import/import_csv_screen.dart';
import '../constants/theme.dart';

// ── Auth state provider ───────────────────────────────────────────────────────
final authStateProvider = StateProvider<bool?>((ref) => null);

final authInitProvider = FutureProvider<bool>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final isAuth = token != null && token.isNotEmpty;
  ref.read(authStateProvider.notifier).state = isAuth;
  return isAuth;
});

// ── Navbar visibility provider ────────────────────────────────────────────────
// Set false saat bottom sheet terbuka, true saat ditutup
final navbarVisibleProvider = StateProvider<bool>((ref) => true);

// ── Router provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthNotifier(ref),
    redirect: (context, state) {
      if (authState == null) return null;

      final isAuth = authState;
      final isOnAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/otp-verify');

      if (!isAuth && !isOnAuth) return '/login';
      if (isAuth && isOnAuth) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/otp-verify',
        builder: (_, state) => OtpVerifyScreen(
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      // ── Shell — bottom nav ────────────────────────────────────────────────
      // Budget DIPINDAHKAN dari navbar ke dalam dashboard (akses via route)
      // Navbar sekarang: Beranda | Transaksi | [+] | Laporan | Profil
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/transactions',
              builder: (_, __) => const TransactionsScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Budget — diakses dari Dashboard, bukan navbar ─────────────────────
      GoRoute(path: '/budget', builder: (_, __) => const BudgetScreen()),

      // ── Transaksi ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/transactions/add',
        builder: (_, state) {
          final type = state.uri.queryParameters['type'] ?? 'expense';
          return AddTransactionScreen(initialType: type);
        },
      ),
      GoRoute(
        path: '/transactions/transfer',
        builder: (_, __) => const TransferScreen(),
      ),
      GoRoute(
        path: '/transactions/edit/:id',
        builder: (_, state) =>
            EditTransactionScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (_, state) =>
            TransactionDetailScreen(id: state.pathParameters['id']!),
      ),

      // ── Rekening & Kategori ───────────────────────────────────────────────
      GoRoute(path: '/accounts', builder: (_, __) => const AccountsScreen()),
      GoRoute(
          path: '/categories', builder: (_, __) => const CategoriesScreen()),
      GoRoute(
        path: '/accounts/:id/transactions',
        builder: (_, state) => AccountTransactionsScreen(
          accountId: state.pathParameters['id']!,
        ),
      ),

      // ── Recurring ────────────────────────────────────────────────────────
      GoRoute(path: '/recurring', builder: (_, __) => const RecurringScreen()),

      // ── Notifikasi ────────────────────────────────────────────────────────
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),

      // ── AI ────────────────────────────────────────────────────────────────
      GoRoute(path: '/ai/chat', builder: (_, __) => const AiChatScreen()),
      GoRoute(path: '/ai/insight', builder: (_, __) => const AiInsightScreen()),

      // ── Import CSV ────────────────────────────────────────────────────────
      GoRoute(path: '/import', builder: (_, __) => const ImportCsvScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: FinaColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Halaman tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FinaColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.error}',
              style: const TextStyle(fontSize: 12, color: FinaColors.text2),
            ),
          ],
        ),
      ),
    ),
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan navbarVisibleProvider
    ref.listen<bool>(navbarVisibleProvider, (prev, visible) {
      if (!visible) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });

    return Scaffold(
      body: widget.child,
      floatingActionButton: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, 2),
          ).animate(
              CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic)),
          child: _AddTransactionFAB(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1),
        ).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic)),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: const _FinaBottomNavBar(),
        ),
      ),
    );
  }
}

// ── FAB Add Transaction ───────────────────────────────────────────────────────
class _AddTransactionFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddOptions(context),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FinaColors.copper2,
              FinaColors.copper,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: FinaColors.copper.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddTransactionSheet(),
    );
  }
}

// ── Bottom Sheet Pilihan Tambah Transaksi ─────────────────────────────────────
class _AddTransactionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FinaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tambah Transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FinaColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SheetOption(
                  icon: Icons.remove_circle_outline_rounded,
                  label: 'Pengeluaran',
                  color: FinaColors.red,
                  bgColor: FinaColors.icRed,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transactions/add?type=expense');
                  },
                ),
                const SizedBox(width: 12),
                _SheetOption(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Pemasukan',
                  color: FinaColors.green,
                  bgColor: FinaColors.icGreen,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transactions/add?type=income');
                  },
                ),
                const SizedBox(width: 12),
                _SheetOption(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  color: FinaColors.blue,
                  bgColor: FinaColors.icBlue,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transactions/transfer');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav Bar ────────────────────────────────────────────────────────────
// Budget DIHAPUS dari navbar. Susunan: Beranda | Transaksi | [+FAB] | Laporan | Profil
class _FinaBottomNavBar extends StatelessWidget {
  const _FinaBottomNavBar();

  // 4 item nyata (slot tengah untuk FAB kosong)
  static const _leftItems = [
    (icon: Icons.home_rounded, label: 'Beranda', route: '/dashboard'),
    (
      icon: Icons.receipt_long_rounded,
      label: 'Transaksi',
      route: '/transactions'
    ),
  ];

  static const _rightItems = [
    (icon: Icons.bar_chart_rounded, label: 'Laporan', route: '/reports'),
    (icon: Icons.person_rounded, label: 'Profil', route: '/profile'),
  ];

  String _currentLoc(BuildContext context) =>
      GoRouterState.of(context).matchedLocation;

  bool _isActive(String loc, String route) => loc.startsWith(route);

  @override
  Widget build(BuildContext context) {
    final loc = _currentLoc(context);

    return BottomAppBar(
      color: const Color(0xEE0D0F14),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: FinaColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Kiri: Beranda & Transaksi
            ..._leftItems.map((item) {
              final active = _isActive(loc, item.route);
              return _NavItem(
                icon: item.icon,
                label: item.label,
                active: active,
                onTap: () => context.go(item.route),
              );
            }),

            // Slot kosong tengah untuk FAB
            const SizedBox(width: 56),

            // Kanan: Laporan & Profil
            ..._rightItems.map((item) {
              final active = _isActive(loc, item.route);
              return _NavItem(
                icon: item.icon,
                label: item.label,
                active: active,
                onTap: () => context.go(item.route),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? FinaColors.copper : FinaColors.text2,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: active ? FinaColors.copper : FinaColors.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
