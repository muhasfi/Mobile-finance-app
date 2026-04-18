import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/theme.dart';
import 'core/utils/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0E13),
  ));
  runApp(const ProviderScope(child: FinaApp()));
}

class FinaApp extends ConsumerWidget {
  const FinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authInit = ref.watch(authInitProvider);

    return authInit.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FinaTheme.dark,
        home: const _SplashScreen(),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'Fina',
          debugShowCheckedModeBanner: false,
          theme: FinaTheme.dark,
          routerConfig: router,
        );
      },
      error: (_, __) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'Fina',
          debugShowCheckedModeBanner: false,
          theme: FinaTheme.dark,
          routerConfig: router,
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0C0E13),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fina',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC8783A),
                  letterSpacing: -1,
                )),
            SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFC8783A)),
            ),
          ],
        ),
      ),
    );
  }
}
