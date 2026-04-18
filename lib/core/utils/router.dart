import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../features/transactions/add_transaction_screen.dart';
import '../../features/transactions/edit_transaction_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/transfer_screen.dart';
import '../../features/accounts/accounts_screen.dart';
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
// Dibaca sekali saat app start, di-update saat login/logout
final authStateProvider = StateProvider<bool?>((ref) => null); // null = loading

final authInitProvider = FutureProvider<bool>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final isAuth = token != null && token.isNotEmpty;
  ref.read(authStateProvider.notifier).state = isAuth;
  return isAuth;
});

// ── Router provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthNotifier(ref),
    redirect: (context, state) {
      // Masih loading
      if (authState == null) return null;

      final isAuth    = authState;
      final isOnAuth  = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/otp-verify');

      if (!isAuth && !isOnAuth) return '/login';
      if (isAuth && isOnAuth)   return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',        builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/otp-verify',
        builder: (_, state) => OtpVerifyScreen(
          email: state.uri.queryParameters['email'],
        ),
      ),

      // ── Shell — bottom nav ────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
          GoRoute(path: '/budget',       builder: (_, __) => const BudgetScreen()),
          GoRoute(path: '/reports',      builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Transaksi detail ──────────────────────────────────────────────────
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
      GoRoute(path: '/accounts',   builder: (_, __) => const AccountsScreen()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),

      // ── Recurring ────────────────────────────────────────────────────────
      GoRoute(path: '/recurring', builder: (_, __) => const RecurringScreen()),

      // ── Notifikasi ────────────────────────────────────────────────────────
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

      // ── AI ────────────────────────────────────────────────────────────────
      GoRoute(path: '/ai/chat',    builder: (_, __) => const AiChatScreen()),
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
                fontSize: 16, fontWeight: FontWeight.w600,
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

// ── Listenable agar GoRouter refresh saat auth berubah ────────────────────────
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: const _FinaBottomNavBar(),
  );
}

class _FinaBottomNavBar extends StatelessWidget {
  const _FinaBottomNavBar();

  static const _items = [
    (icon: Icons.home_rounded,         label: 'Beranda',   route: '/dashboard'),
    (icon: Icons.receipt_long_rounded, label: 'Transaksi', route: '/transactions'),
    (icon: Icons.pie_chart_rounded,    label: 'Budget',    route: '/budget'),
    (icon: Icons.bar_chart_rounded,    label: 'Laporan',   route: '/reports'),
    (icon: Icons.person_rounded,       label: 'Profil',    route: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i   = _items.indexWhere((item) => loc.startsWith(item.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xEE0D0F14),
        border: Border(top: BorderSide(color: FinaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item   = _items[i];
            final active = i == idx;
            return Expanded(
              child: InkWell(
                onTap: () => context.go(item.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active ? FinaColors.copper : FinaColors.text2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
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
          }),
        ),
      ),
    );
  }
}
