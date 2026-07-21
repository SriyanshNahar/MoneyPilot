import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/app_colors.dart';
import 'app_lock_service.dart';

enum _LockMode { pin, pattern, biometric }

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _pin;
  String? _pattern;
  bool _bio = false;
  bool _loaded = false;
  _LockMode _mode = _LockMode.pin;

  final _pinController = TextEditingController();
  final List<int> _patternTaps = [];
  String? _error;
  bool _bioBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(appLockServiceProvider);
    final pin = await service.getPin();
    final pattern = await service.getPattern();
    final bio = await service.getBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _pin = pin;
      _pattern = pattern;
      _bio = bio;
      _mode = pin != null
          ? _LockMode.pin
          : pattern != null
              ? _LockMode.pattern
              : _LockMode.biometric;
      _loaded = true;
    });
    if (_mode == _LockMode.biometric) _tryBiometric();
  }

  List<_LockMode> get _available => [
        if (_pin != null) _LockMode.pin,
        if (_pattern != null) _LockMode.pattern,
        if (_bio) _LockMode.biometric,
      ];

  Future<void> _tryBiometric() async {
    setState(() => _bioBusy = true);
    try {
      final auth = LocalAuthentication();
      final ok = await auth.authenticate(
        localizedReason: "Verify it's you to continue",
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) {
        widget.onUnlock();
      } else {
        setState(() => _error = 'Biometric verification failed');
      }
    } catch (e) {
      setState(() => _error = 'Biometric verification failed');
    } finally {
      if (mounted) setState(() => _bioBusy = false);
    }
  }

  void _submitPin(String v) {
    if (v == _pin) {
      widget.onUnlock();
    } else {
      setState(() => _error = 'Incorrect PIN');
      _pinController.clear();
    }
  }

  void _submitPattern() {
    if (_patternTaps.join(',') == _pattern) {
      widget.onUnlock();
    } else {
      setState(() {
        _error = 'Incorrect pattern';
        _patternTaps.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: colors.primaryTint, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 32),
                ),
                const SizedBox(height: 16),
                Text('App locked', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text("Verify it's you to continue",
                    style: TextStyle(color: colors.mutedForeground, fontSize: 14)),
                if (_available.length > 1) ...[
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _available.map((m) {
                        final active = m == _mode;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: TextButton(
                            onPressed: () => setState(() {
                              _mode = m;
                              _error = null;
                              _pinController.clear();
                              _patternTaps.clear();
                              if (m == _LockMode.biometric) _tryBiometric();
                            }),
                            style: TextButton.styleFrom(
                              backgroundColor: active ? colors.card : null,
                              foregroundColor: active ? Theme.of(context).colorScheme.onSurface : colors.mutedForeground,
                            ),
                            child: Text(_modeLabel(m), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  child: switch (_mode) {
                    _LockMode.pin => _buildPin(context),
                    _LockMode.pattern => _buildPattern(context),
                    _LockMode.biometric => _buildBiometric(context),
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _modeLabel(_LockMode m) => switch (m) {
        _LockMode.pin => 'Pin',
        _LockMode.pattern => 'Pattern',
        _LockMode.biometric => 'Biometric',
      };

  Widget _buildPin(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          const Icon(Icons.key_outlined, size: 18),
          const SizedBox(width: 8),
          const Text('Enter your 4-digit PIN', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _pinController,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          decoration: const InputDecoration(counterText: '', hintText: '••••'),
          onChanged: (v) {
            setState(() => _error = null);
            if (v.length == 4) _submitPin(v);
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _pinController.text.length == 4 ? () => _submitPin(_pinController.text) : null,
            child: const Text('Unlock'),
          ),
        ),
      ],
    );
  }

  Widget _buildPattern(BuildContext context) {
    return Column(
      children: [
        Row(children: const [
          Icon(Icons.grid_view_outlined, size: 18),
          SizedBox(width: 8),
          Text('Tap your pattern', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(9, (i) {
              final n = i + 1;
              final order = _patternTaps.indexOf(n);
              final active = order >= 0;
              return GestureDetector(
                onTap: () => setState(() {
                  _error = null;
                  if (active) {
                    _patternTaps.remove(n);
                  } else {
                    _patternTaps.add(n);
                  }
                }),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? Theme.of(context).colorScheme.primary : context.colors.card,
                    border: Border.all(
                      color: active ? Theme.of(context).colorScheme.primary : context.colors.border,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    active ? '${order + 1}' : '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: active ? Theme.of(context).colorScheme.onPrimary : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _patternTaps.length >= 4 ? _submitPattern : null,
            child: const Text('Unlock'),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometric(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: context.colors.primaryTint, shape: BoxShape.circle),
          child: Icon(Icons.fingerprint, size: 40, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text(_bioBusy ? 'Waiting for biometric…' : 'Tap to verify', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _bioBusy ? null : _tryBiometric, child: const Text('Try again')),
      ],
    );
  }
}
