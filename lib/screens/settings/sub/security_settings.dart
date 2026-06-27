import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/auth_service.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/pin_pad.dart';
import '../../../app.dart';
import '../widgets/settings_widgets.dart';

class SecuritySettings extends ConsumerStatefulWidget {
  const SecuritySettings({super.key});
  @override
  ConsumerState<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends ConsumerState<SecuritySettings> {
  final _auth = AuthService();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _auth.isBiometricAvailable().then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
  }

  Future<void> _changePin(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _ChangePinSheet(
        onDone: (pin) async {
          await _auth.savePin(pin);
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN updated successfully')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, [dynamic _]) {
    final s = ref.watch(settingsProvider);
    final notify = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          SettingsGroupCard(
            label: 'PIN',
            children: [
              ActionSettingTile(
                icon: Icons.pin_outlined,
                title: 'Change PIN',
                subtitle: 'Update your 6-digit unlock code',
                onTap: () => _changePin(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'BIOMETRIC',
            children: [
              SwitchSettingTile(
                icon: Icons.fingerprint_rounded,
                title: 'Use biometric unlock',
                subtitle: _biometricAvailable
                    ? 'Fingerprint or face unlock'
                    : 'Not available on this device',
                value: s.biometricEnabled && _biometricAvailable,
                onChanged: _biometricAvailable
                    ? (v) => notify.update(s.copyWith(biometricEnabled: v))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'AUTO-LOCK',
            children: [
              ...AutoLockDelay.values.map((delay) => RadioSettingTile(
                    icon: Icons.lock_clock_outlined,
                    title: _autoLockLabel(delay),
                    value: delay,
                    groupValue: s.autoLockDelay,
                    onChanged: (v) =>
                        notify.update(s.copyWith(autoLockDelay: v)),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'PRIVACY',
            children: [
              SwitchSettingTile(
                icon: Icons.no_photography_outlined,
                title: 'Block screenshots',
                subtitle:
                    'Prevent screen capture and recent-apps preview (Android)',
                value: s.screenshotProtection,
                onChanged: (v) =>
                    notify.update(s.copyWith(screenshotProtection: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'DANGER ZONE',
            children: [
              ActionSettingTile(
                icon: Icons.delete_forever_outlined,
                iconColor: scheme.error,
                title: 'Clear all security data',
                subtitle: 'Removes PIN and biometric settings',
                textColor: scheme.error,
                onTap: () => _confirmClearSecurity(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _autoLockLabel(AutoLockDelay d) => switch (d) {
        AutoLockDelay.immediately => 'Immediately on background',
        AutoLockDelay.after30s => 'After 30 seconds',
        AutoLockDelay.after1m => 'After 1 minute',
        AutoLockDelay.after5m => 'After 5 minutes',
        AutoLockDelay.never => 'Never (not recommended)',
      };

  Future<void> _confirmClearSecurity(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: const Text('Clear security data?'),
        content: const Text(
            'Your PIN will be deleted and the app will ask you to set a new one on next launch.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _auth.clearAll();
      if (mounted) {
        ref.read(isFirstLaunchProvider.notifier).state = true;
        ref.read(isAuthenticatedProvider.notifier).state = false;
      }
    }
  }
}

class _ChangePinSheet extends StatefulWidget {
  final Future<void> Function(String pin) onDone;
  const _ChangePinSheet({required this.onDone});
  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  String? _first;
  String? _error;

  void _onPin(String pin) {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
    } else {
      if (pin == _first) {
        widget.onDone(pin);
      } else {
        setState(() {
          _first = null;
          _error = 'PINs did not match';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _first == null ? 'Enter new PIN' : 'Confirm new PIN',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            PinPad(
              onComplete: _onPin,
              errorText: _error,
            ),
          ],
        ),
      ),
    );
  }
}
