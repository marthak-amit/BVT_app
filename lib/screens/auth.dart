import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

Future<bool> requireLogin(BuildContext c, String reason) async {
  if (app.loggedIn) return true;
  await push(c, LoginScreen(reason: reason));
  return app.loggedIn;
}

Future<bool> biometricPrompt(BuildContext context, {String reason = 'Confirm your identity'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.fingerprint, size: 56, color: BvtColors.saffron),
      title: Text(reason),
      content: const Text('Touch the sensor or look at your device.\n(Prototype: Fingerprint / Face ID / Touch ID simulation)', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simulate success')),
      ],
    ),
  );
  return ok ?? false;
}

class LoginScreen extends StatefulWidget {
  final String? reason;
  const LoginScreen({super.key, this.reason});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Mode { signIn, register, otp }

class _LoginScreenState extends State<LoginScreen> {
  _Mode mode = _Mode.signIn;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController(text: 'radhika@example.com');
  final _phone = TextEditingController(text: '9825012345');
  final _pass = TextEditingController(text: 'password123');
  final _otp = TextEditingController();
  bool otpSent = false, wa = true, gdpr = true, hide = true, busy = false;

  void _done() {
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, 'Signed in as ${app.name}', icon: Icons.check_circle);
  }

  Future<void> _go(Future<void> Function() f) async {
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 700));
    await f();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mode == _Mode.register ? 'Create account' : app.t('sign_in'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (widget.reason != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.info_outline, color: BvtColors.deepSaffron), const SizedBox(width: 10), Expanded(child: Text(widget.reason!))]),
          ),
        SegmentedButton<_Mode>(
          segments: const [
            ButtonSegment(value: _Mode.signIn, label: Text('Email')),
            ButtonSegment(value: _Mode.otp, label: Text('WhatsApp OTP')),
            ButtonSegment(value: _Mode.register, label: Text('Register')),
          ],
          selected: {mode},
          onSelectionChanged: (s) => setState(() => mode = s.first),
        ),
        const SizedBox(height: 20),
        Form(
          key: _form,
          child: switch (mode) {
            _Mode.signIn => Column(children: [
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)), validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email'),
                const SizedBox(height: 12),
                TextFormField(controller: _pass, obscureText: hide, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => hide = !hide))), validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: const Text('Forgot password?'))),
                const SizedBox(height: 4),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : () { if (_form.currentState!.validate()) _go(() async { app.login(e: _email.text); _done(); }); }, child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(app.t('sign_in')))),
                if (app.biometric) ...[
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () async { if (await biometricPrompt(context, reason: 'Sign in with biometrics')) { app.login(); _done(); } }, icon: const Icon(Icons.fingerprint), label: const Text('Use fingerprint / Face ID'))),
                ],
              ]),
            _Mode.otp => Column(children: [
                TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp number', prefixText: '+91  ', prefixIcon: Icon(Icons.chat, color: BvtColors.whatsapp))),
                const SizedBox(height: 12),
                if (otpSent) ...[
                  TextFormField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Enter 6-digit code', helperText: 'Demo code: 123456')),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (_otp.text == '123456') { app.login(p: '+91 ${_phone.text}'); _done(); } else { toast(context, 'Incorrect code — use 123456', icon: Icons.error_outline); } }, child: const Text('Verify & sign in'))),
                ] else
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : () => _go(() async { setState(() => otpSent = true); toast(context, 'OTP sent on WhatsApp (demo code 123456)', icon: Icons.chat); }), icon: const Icon(Icons.send), label: const Text('Send OTP on WhatsApp'))),
              ]),
            _Mode.register => Column(children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)), validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email'),
                const SizedBox(height: 12),
                TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91  ', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => (v ?? '').length < 10 ? 'Enter 10 digits' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null),
                CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: wa, onChanged: (v) => setState(() => wa = v!), title: const Text('Send order updates and offers on WhatsApp', style: TextStyle(fontSize: 13.5)), subtitle: const Text('Explicit opt-in. You can opt out any time.', style: TextStyle(fontSize: 12))),
                CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: gdpr, onChanged: (v) => setState(() => gdpr = v!), title: const Text('I agree to the Terms and Privacy Policy', style: TextStyle(fontSize: 13.5))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: busy || !gdpr ? null : () { if (_form.currentState!.validate()) _go(() async { app.register(_name.text, _email.text, '+91 ${_phone.text}', wa: wa); if (!mounted) return; Navigator.pop(context); toast(context, 'Account created — check your email to verify', icon: Icons.mark_email_read); }); }, child: const Text('Create account'))),
              ]),
          },
        ),
        const SizedBox(height: 22),
        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or continue with', style: TextStyle(color: BvtColors.muted))), Expanded(child: Divider())]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _go(() async { app.login(n: 'Radhika Sharma', e: 'radhika@gmail.com'); _done(); }), icon: const Icon(Icons.g_mobiledata, size: 30), label: const Text('Google'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () => _go(() async { app.login(n: 'Radhika Sharma', e: 'radhika@privaterelay.appleid.com'); _done(); }), icon: const Icon(Icons.apple), label: const Text('Apple'))),
        ]),
        const SizedBox(height: 14),
        TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Continue as guest')),
      ]),
    );
  }

  void _forgot() {
    final c = TextEditingController(text: _email.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('We will email you a secure reset link.'),
          const SizedBox(height: 12),
          TextField(controller: c, decoration: const InputDecoration(labelText: 'Email')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(ctx); toast(context, 'Reset link sent to ${c.text}', icon: Icons.mark_email_read); }, child: const Text('Send link')),
        ],
      ),
    );
  }
}
