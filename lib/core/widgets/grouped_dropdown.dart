import 'package:flutter/material.dart';

import 'premium_dropdown.dart';

/// A category/group inside a [GroupedDropdownField].
class DropdownGroupData {
  const DropdownGroupData(this.title, this.items);
  final String title;
  final List<DropdownItemData> items;
}

/// A single selectable row inside a [DropdownGroupData].
class DropdownItemData {
  const DropdownItemData(this.key, this.label);
  final String key;
  final String label;
}

/// Premium grouped dropdown: white surface, large bold black section
/// headings clearly separated from their rows, smaller regular-weight black
/// items underneath. Used for the calculator picker, expense/event category
/// pickers and the activity category filter so every grouped dropdown in
/// the app shares one visual language.
class GroupedDropdownField extends StatelessWidget {
  const GroupedDropdownField({
    super.key,
    required this.groups,
    required this.value,
    required this.onChanged,
    this.leadingItems = const [],
  });

  final List<DropdownGroupData> groups;
  final String value;
  final ValueChanged<String> onChanged;
  /// Selectable rows shown above any group heading (e.g. an "All
  /// categories" option) — no heading of their own.
  final List<DropdownItemData> leadingItems;

  String _labelFor(String key) {
    for (final it in leadingItems) {
      if (it.key == key) return it.label;
    }
    for (final g in groups) {
      for (final it in g.items) {
        if (it.key == key) return it.label;
      }
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = <DropdownMenuItem<String>>[];
    final selectedBuilders = <Widget>[];

    void addRow(DropdownItemData it) {
      final selected = it.key == value;
      menuItems.add(DropdownMenuItem<String>(
        value: it.key,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.black.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(it.label, style: PremiumDropdownStyle.itemTextStyle, overflow: TextOverflow.ellipsis),
        ),
      ));
      selectedBuilders.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_labelFor(value), style: PremiumDropdownStyle.selectedTextStyle, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    for (final it in leadingItems) {
      addRow(it);
    }

    var headerIndex = 0;
    for (final g in groups) {
      final headerValue = '__header_${headerIndex++}';
      menuItems.add(DropdownMenuItem<String>(
        value: headerValue,
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            g.title.toUpperCase(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: PremiumDropdownStyle.textColor, letterSpacing: 0.2),
          ),
        ),
      ));
      selectedBuilders.add(const SizedBox.shrink());

      for (final it in g.items) {
        addRow(it);
      }
    }

    return Container(
      decoration: PremiumDropdownStyle.fieldShadowDecoration(),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.expand_more_rounded, color: PremiumDropdownStyle.mutedTextColor),
        dropdownColor: Colors.white,
        elevation: 6,
        borderRadius: BorderRadius.circular(PremiumDropdownStyle.radius),
        menuMaxHeight: 400,
        decoration: PremiumDropdownStyle.decoration(),
        items: menuItems,
        selectedItemBuilder: (context) => selectedBuilders,
        onChanged: (v) {
          if (v != null && !v.startsWith('__header_')) onChanged(v);
        },
      ),
    );
  }
}
