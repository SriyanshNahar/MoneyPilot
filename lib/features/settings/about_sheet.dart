import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';

/// New in v2.1 — "About" section of the restructured Settings screen.
class AboutSheet extends StatefulWidget {
  const AboutSheet({super.key});

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset('assets/images/app_icon.png', width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),
          const Text('MoneyPilot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Smart money, simply managed.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 2),
          if (_version.isNotEmpty) Text('Version $_version', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
            child: Text.rich(
              TextSpan(
                text: 'A smart money app by ',
                style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                children: const [
                  TextSpan(text: 'Seven Sapience.', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MoneyPilot never sells your data. Expenses, EMIs, SIPs and reminders — all in one place, built for India.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.mutedForeground, height: 1.5),
          ),
        ],
      ),
    );
  }
}
