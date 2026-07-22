import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

/// Clean, grouped Material dropdown: uppercase/semibold non-selectable group
/// headers, regular/indented selectable child rows. Used for calculator,
/// expense-category and personal-event-category pickers so all three share
/// one visual language instead of each rolling its own list/expander.
class GroupedDropdownField extends StatelessWidget {
  const GroupedDropdownField({super.key, required this.groups, required this.value, required this.onChanged});

  final List<DropdownGroupData> groups;
  final String value;
  final ValueChanged<String> onChanged;

  String _labelFor(String key) {
    for (final g in groups) {
      for (final it in g.items) {
        if (it.key == key) return it.label;
      }
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    final menuItems = <DropdownMenuItem<String>>[];
    final selectedBuilders = <Widget>[];
    var headerIndex = 0;

    for (final g in groups) {
      final headerValue = '__header_${headerIndex++}';
      menuItems.add(DropdownMenuItem<String>(
        value: headerValue,
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            g.title.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: colors.mutedForeground),
          ),
        ),
      ));
      selectedBuilders.add(const SizedBox.shrink());

      for (final it in g.items) {
        menuItems.add(DropdownMenuItem<String>(
          value: it.key,
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              it.label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: it.key == value ? scheme.primary : null),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ));
        selectedBuilders.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_labelFor(value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
          ),
        );
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      menuMaxHeight: 360,
      items: menuItems,
      selectedItemBuilder: (context) => selectedBuilders,
      onChanged: (v) {
        if (v != null && !v.startsWith('__header_')) onChanged(v);
      },
    );
  }
}
