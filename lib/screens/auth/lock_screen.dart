import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/security/auth_service.dart';
import '../../app.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _authService = AuthService();
  String _pin = '';
  String? _errorText;
  bool _biometricAvailable = false;
  Duration? _lockoutRemaining;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final biometricAvailable = await _authService.isBiometricAvailable();
    final lockout = await _authService.getLockoutRemaining();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = biometricAvailable;
      _lockoutRemaining = lockout;
    });
    if (biometricAvailable && lockout == null) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final success = await _authService.authenticateWithBiometric();
    if (success && mounted) {
      ref.read(isAuthenticatedProvider.notifier).state = true;
    }
  }

  void _onDigit(String digit) {
    if (_lockoutRemaining != null) return;
    setState(() {
      _errorText = null;
      if (_pin.length < 6) {
        _pin += digit;
        if (_pin.length == 6) _verifyPin();
      }
    });
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    if (!mounted) return;
    final lockout = await _authService.getLockoutRemaining();
    if (!mounted) return;
    if (lockout != null) {
      setState(() {
        _lockoutRemaining = lockout;
        _pin = '';
        _errorText =
            'Too many attempts. Try again in ${lockout.inMinutes}m ${lockout.inSeconds % 60}s';
      });
      return;
    }

    final success = await _authService.verifyPin(_pin);
    if (!mounted) return;
    if (success) {
      ref.read(isAuthenticatedProvider.notifier).state = true;
    } else {
      final attempts = await _authService.getFailedAttempts();
      if (!mounted) return;
      final remaining = AuthService.maxAttempts - attempts;
      setState(() {
        _pin = '';
        _errorText =
            'Incorrect PIN. $remaining attempt${remaining != 1 ? 's' : ''} remaining.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                child: Icon(Icons.lock_outline, color: scheme.primary, size: 40),
              ).animate().scale(duration: 400.ms),

              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _lockoutRemaining != null
                    ? 'App locked due to too many attempts'
                    : 'Enter your PIN to continue',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? scheme.primary : Colors.grey.shade300,
                    ),
                  );
                }),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(_errorText!,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                    textAlign: TextAlign.center),
              ],

              const Spacer(),

              if (_lockoutRemaining == null) _buildNumpad(),

              if (_biometricAvailable && _lockoutRemaining == null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 72);
            return GestureDetector(
              onTap: key == '⌫' ? _onBackspace : () => _onDigit(key),
              child: Container(
                width: 80,
                height: 72,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardTheme.color,
                ),
                alignment: Alignment.center,
                child: Text(key,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
