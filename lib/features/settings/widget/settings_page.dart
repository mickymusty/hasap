import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:hasap/core/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('theme'.tr()),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('light_mode'.tr()),
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: Text('dark_mode'.tr()),
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: Text('system'.tr()),
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setThemeMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('language'.tr()),
          Card(
            child: Column(
              children: [
                _LangTile(locale: const Locale('en'), label: 'English', ref: ref),
                _LangTile(locale: const Locale('tk'), label: 'Türkmen', ref: ref),
                _LangTile(locale: const Locale('ru'), label: 'Русский', ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('pin_lock'.tr()),
          Card(
            child: SwitchListTile(
              title: Text('pin_lock'.tr()),
              subtitle: Text(settings.pinEnabled ? 'pin_enabled'.tr() : 'pin_disabled'.tr()),
              value: settings.pinEnabled,
              onChanged: (enabled) => _handlePinToggle(context, ref, enabled),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePinToggle(BuildContext context, WidgetRef ref, bool enable) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (enable) {
      String? newPin;
      await screenLockCreate(
        context: context,
        onConfirmed: (pin) {
          newPin = pin;
          Navigator.pop(context);
        },
      );
      if (newPin != null) await notifier.setPin(newPin!);
    } else {
      final currentPin = ref.read(settingsProvider).pin;
      if (currentPin == null) return;
      bool confirmed = false;
      await screenLock(
        context: context,
        correctString: currentPin,
        onUnlocked: () {
          confirmed = true;
          Navigator.pop(context);
        },
      );
      if (confirmed) await notifier.clearPin();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
  );
}

class _LangTile extends StatelessWidget {
  const _LangTile({required this.locale, required this.label, required this.ref});
  final Locale locale;
  final String label;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => RadioListTile<Locale>(
    title: Text(label),
    value: locale,
    groupValue: context.locale,
    onChanged: (v) => context.setLocale(v!),
  );
}
