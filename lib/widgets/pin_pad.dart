import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final void Function(String pin) onComplete;
  final String? errorText;

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

  void _onDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() => _pin += digit);
    if (_pin.length == 6) {
      widget.onComplete(_pin);
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? scheme.primary : Colors.grey.shade300,
              ),
            );
          }),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 12),
          Text(widget.errorText!,
              style: TextStyle(color: scheme.error, fontSize: 13),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 28),
        _buildNumpad(),
      ],
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
            if (key.isEmpty) return const SizedBox(width: 80, height: 64);
            return GestureDetector(
              onTap: key == '⌫' ? _onBackspace : () => _onDigit(key),
              child: Container(
                width: 80,
                height: 64,
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
