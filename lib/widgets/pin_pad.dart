import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinPad extends StatefulWidget {
  final void Function(String pin) onComplete;
  final String? errorText;
  // Key trick: parent passes a new key when it wants PinPad to reset
  const PinPad({
    super.key,
    required this.onComplete,
    this.errorText,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _submitted = false;

  @override
  void didUpdateWidget(covariant PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset dots when parent signals an error (errorText changed to non-null)
    if (widget.errorText != null &&
        oldWidget.errorText != widget.errorText) {
      setState(() {
        _pin = '';
        _submitted = false;
      });
    }
  }

  void _onDigit(String digit) {
    if (_pin.length >= 6 || _submitted) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == 6) {
      _submitted = true;
      // Small delay so user sees all 6 dots fill before callback
      Future.delayed(const Duration(milliseconds: 120), () {
        widget.onComplete(_pin);
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _submitted) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: filled ? 15 : 13,
              height: filled ? 15 : 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? scheme.primary : scheme.outlineVariant,
              ),
            );
          }),
        ),

        // Error text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.errorText != null
              ? Padding(
                  key: ValueKey(widget.errorText),
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox(height: 14 + 13 + 8, key: ValueKey('none')),
        ),

        const SizedBox(height: 20),

        // Numpad
        ...[ ['1','2','3'], ['4','5','6'], ['7','8','9'], ['','0','⌫'] ]
            .map((row) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((key) {
                    if (key.isEmpty) {
                      return const SizedBox(width: 80, height: 68);
                    }
                    return _DialKey(
                      label: key,
                      onTap: key == '⌫' ? _onBackspace : () => _onDigit(key),
                    );
                  }).toList(),
                )),
      ],
    );
  }
}

class _DialKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DialKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceContainerLow,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          onTap: onTap,
          child: SizedBox(
            width: 72,
            height: 68,
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined,
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurface)
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w400)),
            ),
          ),
        ),
      ),
    );
  }
}
