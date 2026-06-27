import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/security/auth_service.dart';
import '../../app.dart';

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  final _authService = AuthService();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorText;

  void _onDigit(String digit) {
    setState(() {
      _errorText = null;
      if (!_isConfirming && _pin.length < 6) {
        _pin += digit;
        if (_pin.length == 6) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isConfirming = true);
          });
        }
      } else if (_isConfirming && _confirmPin.length < 6) {
        _confirmPin += digit;
        if (_confirmPin.length == 6) _verifyAndSave();
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorText = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }
    if (!mounted) return;
    await _authService.savePin(_pin);
    ref.read(isFirstLaunchProvider.notifier).state = false;
    ref.read(isAuthenticatedProvider.notifier).state = true;
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
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 40),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOut),

              const SizedBox(height: 32),
              Text(
                _isConfirming ? 'Confirm your PIN' : 'Create a 6-digit PIN',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Re-enter your PIN to confirm'
                    : 'This PIN secures access to your app',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = _isConfirming
                      ? i < _confirmPin.length
                      : i < _pin.length;
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
                    style: TextStyle(color: scheme.error, fontSize: 13)),
              ],

              const Spacer(),

              _buildNumpad(),
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
                child: Text(
                  key,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
