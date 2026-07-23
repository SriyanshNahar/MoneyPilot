import 'package:flutter/material.dart';

/// Shared "premium" dropdown look used app-wide: white surface, black text,
/// rounded corners and a soft shadow — independent of light/dark theme,
/// matching the Home day-filter popup's established Apple-style look.
/// Centralized here so every dropdown in the app (category filters, add
/// expense/event forms, calculator picker, investment/loan/subscription
/// type pickers, ...) shares one visual language instead of each using the
/// stock Flutter dropdown chrome.
class PremiumDropdownStyle {
  static const radius = 16.0;
  static const fieldBorderColor = Color(0x14000000); // black @ 8%
  static const textColor = Colors.black;
  static const mutedTextColor = Colors.black54;

  static BoxDecoration fieldShadowDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      );

  static InputDecoration decoration({String? labelText}) => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: labelText,
        labelStyle: const TextStyle(color: mutedTextColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: fieldBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: fieldBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.35), width: 1.5)),
      );

  static const itemTextStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textColor);
  static const selectedTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor);
}

/// A flat (ungrouped) premium dropdown — for simple option lists like
/// sub-category, payment method, or a loan/investment "type" field.
class PremiumDropdownField<T> extends StatelessWidget {
  const PremiumDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelOf,
    this.hint,
    this.labelText,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? labelOf;
  final String? hint;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PremiumDropdownStyle.fieldShadowDecoration(),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        hint: hint != null ? Text(hint!, style: const TextStyle(color: PremiumDropdownStyle.mutedTextColor)) : null,
        icon: const Icon(Icons.expand_more_rounded, color: PremiumDropdownStyle.mutedTextColor),
        dropdownColor: Colors.white,
        elevation: 6,
        borderRadius: BorderRadius.circular(PremiumDropdownStyle.radius),
        menuMaxHeight: 360,
        style: PremiumDropdownStyle.selectedTextStyle,
        decoration: PremiumDropdownStyle.decoration(labelText: labelText),
        items: [for (final item in items) DropdownMenuItem<T>(value: item, child: Text(labelOf != null ? labelOf!(item) : item.toString()))],
        onChanged: onChanged,
      ),
    );
  }
}
