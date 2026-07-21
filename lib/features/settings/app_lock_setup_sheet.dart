import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/app_colors.dart';
import '../app_lock/app_lock_service.dart';

enum _Tab { pin, pattern, biometric }

/// Direct port of the AppLockBlock (+ Pin/Pattern/Biometric setup) in settings.tsx.
class AppLockSetupSheet extends ConsumerStatefulWidget {
  const AppLockSetupSheet({super.key});
  @override
  ConsumerState<AppLockSetupSheet> createState() => _AppLockSetupSheetState();
}

class _AppLockSetupSheetState extends ConsumerState<AppLockSetupSheet> {
  _Tab _tab = _Tab.pin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Lock', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text('Set PIN, Pattern or Biometric — all three work independently.', style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: _TabBtn(label: 'Pin', active: _tab == _Tab.pin, onTap: () => setState(() => _tab = _Tab.pin))),
              Expanded(child: _TabBtn(label: 'Pattern', active: _tab == _Tab.pattern, onTap: () => setState(() => _tab = _Tab.pattern))),
              Expanded(child: _TabBtn(label: 'Biometric', active: _tab == _Tab.biometric, onTap: () => setState(() => _tab = _Tab.biometric))),
            ]),
          ),
          const SizedBox(height: 16),
          switch (_tab) {
            _Tab.pin => const _PinSetup(),
            _Tab.pattern => const _PatternSetup(),
            _Tab.biometric => const _BiometricSetup(),
          },
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: active ? colors.card : null, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? null : colors.mutedForeground)),
      ),
    );
  }
}

class _PinSetup extends ConsumerStatefulWidget {
  const _PinSetup();
  @override
  ConsumerState<_PinSetup> createState() => _PinSetupState();
}

class _PinSetupState extends ConsumerState<_PinSetup> {
  final _pin = TextEditingController();
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final pin = await ref.read(appLockServiceProvider).getPin();
    if (mounted) setState(() => _enabled = pin != null);
  }

  void _bumpRefresh() => ref.read(appLockRefreshProvider.notifier).state++;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.key_outlined, size: 16),
          const SizedBox(width: 8),
          const Text('4-digit PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          if (_enabled) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: context.colors.primaryTint, borderRadius: BorderRadius.circular(999)),
              child: Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 10),
          decoration: const InputDecoration(counterText: '', hintText: '••••'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: !_enabled
                  ? null
                  : () async {
                      await ref.read(appLockServiceProvider).removePin();
                      _bumpRefresh();
                      await _refresh();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN removed')));
                    },
              child: const Text('Remove'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: _pin.text.length != 4
                  ? null
                  : () async {
                      await ref.read(appLockServiceProvider).setPin(_pin.text);
                      _bumpRefresh();
                      _pin.clear();
                      await _refresh();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN saved')));
                    },
              child: const Text('Save PIN'),
            ),
          ),
        ]),
      ],
    );
  }
}

class _PatternSetup extends ConsumerStatefulWidget {
  const _PatternSetup();
  @override
  ConsumerState<_PatternSetup> createState() => _PatternSetupState();
}

class _PatternSetupState extends ConsumerState<_PatternSetup> {
  final List<int> _pattern = [];
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final p = await ref.read(appLockServiceProvider).getPattern();
    if (mounted) setState(() => _enabled = p != null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.grid_view_outlined, size: 16),
          const SizedBox(width: 8),
          const Expanded(child: Text('Tap dots in sequence (min 4)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          if (_enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: colors.primaryTint, borderRadius: BorderRadius.circular(999)),
              child: Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
            ),
        ]),
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(9, (i) {
                final n = i + 1;
                final order = _pattern.indexOf(n);
                final active = order >= 0;
                return GestureDetector(
                  onTap: () => setState(() => active ? _pattern.remove(n) : _pattern.add(n)),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Theme.of(context).colorScheme.primary : colors.card,
                      border: Border.all(color: active ? Theme.of(context).colorScheme.primary : colors.border, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(active ? '${order + 1}' : '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: active ? Colors.white : null)),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                setState(() => _pattern.clear());
                await ref.read(appLockServiceProvider).removePattern();
                ref.read(appLockRefreshProvider.notifier).state++;
                await _refresh();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pattern removed')));
              },
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: _pattern.length < 4
                  ? null
                  : () async {
                      await ref.read(appLockServiceProvider).setPattern(_pattern);
                      ref.read(appLockRefreshProvider.notifier).state++;
                      await _refresh();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pattern saved')));
                    },
              child: const Text('Save Pattern'),
            ),
          ),
        ]),
      ],
    );
  }
}

class _BiometricSetup extends ConsumerStatefulWidget {
  const _BiometricSetup();
  @override
  ConsumerState<_BiometricSetup> createState() => _BiometricSetupState();
}

class _BiometricSetupState extends ConsumerState<_BiometricSetup> {
  bool _busy = false;
  bool _enabled = false;
  bool? _available;

  @override
  void initState() {
    super.initState();
    _refresh();
    LocalAuthentication().isDeviceSupported().then((v) {
      if (mounted) setState(() => _available = v);
    });
  }

  Future<void> _refresh() async {
    final e = await ref.read(appLockServiceProvider).getBiometricEnabled();
    if (mounted) setState(() => _enabled = e);
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      if (!supported) throw Exception("This device doesn't support biometric authentication.");
      final ok = await auth.authenticate(
        localizedReason: 'Enable biometric unlock for MoneyPilot',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok) throw Exception('Biometric prompt was cancelled or timed out.');
      await ref.read(appLockServiceProvider).setBiometricEnabled(true);
      ref.read(appLockRefreshProvider.notifier).state++;
      await _refresh();
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric unlock enabled')));
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canEnable = _available != false;
    final statusText = _available == false ? "This device doesn't support biometric login." : "Uses your device's secure enclave (fingerprint / Face ID).";

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: colors.primaryTint, shape: BoxShape.circle),
          child: Icon(Icons.fingerprint, size: 36, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 10),
        const Text('Use fingerprint or Face ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 4),
        Text(statusText, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _enabled
              ? OutlinedButton(
                  onPressed: () async {
                    await ref.read(appLockServiceProvider).setBiometricEnabled(false);
                    ref.read(appLockRefreshProvider.notifier).state++;
                    await _refresh();
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric disabled')));
                  },
                  child: const Text('Disable Biometric'),
                )
              : FilledButton(
                  onPressed: (!canEnable || _busy) ? null : _enable,
                  child: Text(_busy ? 'Setting up…' : 'Enable Biometric'),
                ),
        ),
      ],
    );
  }
}
