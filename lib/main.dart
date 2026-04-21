import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:hasap/core/providers/settings_provider.dart';
import 'package:hasap/core/router/app_router.dart';
import 'package:hasap/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tk'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: HasapApp()),
    ),
  );
}

class HasapApp extends ConsumerWidget {
  const HasapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      data: (s) => MaterialApp.router(
        title: 'Hasap',
        theme: lightTheme(),
        darkTheme: darkTheme(),
        themeMode: s.themeMode,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: appRouter,
        builder: (context, child) {
          if (s.pinEnabled && s.pin != null) {
            return _PinGate(pin: s.pin!, child: child!);
          }
          return child!;
        },
      ),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text(e.toString()))),
      ),
    );
  }
}

class _PinGate extends StatefulWidget {
  const _PinGate({required this.pin, required this.child});
  final String pin;
  final Widget child;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return ScreenLock(
      correctString: widget.pin,
      onUnlocked: () => setState(() => _unlocked = true),
    );
  }
}
