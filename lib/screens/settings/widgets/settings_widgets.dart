import 'package:flutter/material.dart';

class SettingsGroupCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const SettingsGroupCard({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: scheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: _divided(children, scheme),
          ),
        ),
      ],
    );
  }

  List<Widget> _divided(List<Widget> items, ColorScheme scheme) {
    if (items.length <= 1) return items;
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(Divider(
          height: 1,
          indent: 56,
          endIndent: 16,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ));
      }
    }
    return result;
  }
}

class SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchSettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;

    return SwitchListTile(
      secondary: Icon(icon,
          color: enabled ? scheme.onSurfaceVariant : scheme.outline),
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: enabled ? scheme.onSurface : scheme.outline)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
          : null,
      value: value,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class RadioSettingTile<T> extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  const RadioSettingTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == groupValue;

    return RadioListTile<T>(
      secondary: icon != null
          ? Icon(icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant)
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
          : null,
      value: value,
      groupValue: groupValue,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      activeColor: scheme.primary,
    );
  }
}

class ActionSettingTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ActionSettingTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.textColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = iconColor ?? scheme.onSurfaceVariant;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? scheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
          : null,
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
