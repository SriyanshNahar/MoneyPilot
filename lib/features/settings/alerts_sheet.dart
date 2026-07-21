import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/alerts_repository.dart';
import '../auth/auth_controller.dart';

/// Direct port of the AlertsForm component in settings.tsx.
class AlertsSheet extends ConsumerStatefulWidget {
  const AlertsSheet({super.key, required this.defaultPhone, required this.defaultEmail});
  final String defaultPhone;
  final String defaultEmail;

  @override
  ConsumerState<AlertsSheet> createState() => _AlertsSheetState();
}

class _AlertsSheetState extends ConsumerState<AlertsSheet> {
  late final _phone = TextEditingController(text: widget.defaultPhone);
  late final _whatsapp = TextEditingController(text: widget.defaultPhone);
  late final _email = TextEditingController(text: widget.defaultEmail);
  final _message = TextEditingController(text: 'Test alert from MoneyPilot — your notifications are set up correctly.');
  final Map<String, bool> _channels = {'email': true, 'sms': true, 'whatsapp': true};
  bool _busy = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    final prefs = await const AlertsRepository().fetch(uid);
    if (prefs == null || !mounted) return;
    setState(() {
      _channels['email'] = prefs.emailEnabled;
      _channels['sms'] = prefs.smsEnabled;
      _channels['whatsapp'] = prefs.whatsappEnabled;
      if (prefs.email != null) _email.text = prefs.email!;
      if (prefs.phone != null) _phone.text = prefs.phone!.replaceFirst('+91', '');
      if (prefs.whatsapp != null) _whatsapp.text = prefs.whatsapp!.replaceFirst('+91', '');
    });
  }

  Future<void> _savePrefs() async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await const AlertsRepository().upsert(
        uid: uid,
        emailEnabled: _channels['email']!,
        smsEnabled: _channels['sms']!,
        whatsappEnabled: _channels['whatsapp']!,
        email: _email.text.isEmpty ? null : _email.text,
        phone: _phone.text.isEmpty ? null : '+91${_phone.text}',
        whatsapp: _whatsapp.text.isNotEmpty ? '+91${_whatsapp.text}' : (_phone.text.isNotEmpty ? '+91${_phone.text}' : null),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert preferences saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTest() async {
    final active = _channels.entries.where((e) => e.value).map((e) => e.key).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turn on at least one channel')));
      return;
    }
    if (_message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a message')));
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await const AlertsRepository().sendTestAlert(channels: active, phone: '+91${_phone.text}', email: _email.text, message: _message.text);
      final results = Map<String, dynamic>.from(res['results'] as Map);
      for (final entry in results.entries) {
        final r = Map<String, dynamic>.from(entry.value as Map);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${entry.key.toUpperCase()}: ${r['info']}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alert channels', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text('Manage your alert channels.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          _channelToggle(Icons.chat_bubble_outline, 'WhatsApp', _phone.text.isNotEmpty ? '+91${_phone.text}' : 'Add number below', 'whatsapp'),
          const SizedBox(height: 8),
          _channelToggle(Icons.smartphone_outlined, 'SMS', _phone.text.isNotEmpty ? '+91${_phone.text}' : 'Add number below', 'sms'),
          const SizedBox(height: 8),
          _channelToggle(Icons.mail_outline, 'Email', _email.text.isNotEmpty ? _email.text : 'Add email below', 'email'),
          const SizedBox(height: 16),
          Text('PHONE (FOR WHATSAPP & SMS)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(prefixText: '+91  ', counterText: ''), onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Text('WHATSAPP NUMBER (OPTIONAL)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _whatsapp, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(prefixText: '+91  ', counterText: ''), onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Text('EMAIL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Text('TEST MESSAGE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _message, maxLines: 3, maxLength: 500),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _savePrefs,
                icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, size: 18),
                label: const Text('Save prefs'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _sendTest,
                icon: _busy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
                label: const Text('Send test'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.primaryTint.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary),
                children: const [
                  TextSpan(text: 'Daily reminders run at 9:00 AM IST. If you set '),
                  TextSpan(text: 'Remind before 5 days', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' on a bill or event, we start pinging your selected channels 5 days before the due date.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelToggle(IconData icon, String label, String sub, String key) {
    final colors = context.colors;
    final on = _channels[key]!;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _channels[key] = !on),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: colors.primaryTint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(sub, style: TextStyle(fontSize: 13, color: colors.mutedForeground), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(value: on, onChanged: (v) => setState(() => _channels[key] = v)),
        ]),
      ),
    );
  }
}
