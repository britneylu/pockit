import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../viewmodels/auth_viewmodel.dart';

// display sign in registration and password reset controls
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;
  String? _emailError(BuildContext context, String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : context.l10n.text('auth.emailError');
  // validate the form before requesting authentication
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // observe authentication progress and feedback
    final model = context.read<AuthViewModel>();
    if (_register) {
      await model.register(_email.text, _password.text);
    } else {
      await model.signIn(_email.text, _password.text);
    }
  }

  @override
  // release the email and password controllers
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AuthViewModel>();
    final state = model.state;
    final text = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(text.text('auth.title'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'pockit.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      text.text(
                        _register
                            ? 'auth.registerGreeting'
                            : 'auth.signInGreeting',
                      ),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(text.text('auth.tagline')),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('authEmail'),
                      controller: _email,
                      enabled: !state.busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: text.text('auth.email'),
                      ),
                      validator: (value) => _emailError(context, value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('authPassword'),
                      controller: _password,
                      enabled: !state.busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: text.text('auth.password'),
                        suffixIcon: IconButton(
                          tooltip: text.text(
                            _obscure
                                ? 'auth.showPassword'
                                : 'auth.hidePassword',
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? text.text('auth.passwordError')
                          : _register && value.length < 6
                          ? text.text('auth.passwordLength')
                          : null,
                      onFieldSubmitted: state.busy ? null : (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    if (state.error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          text.message(state.error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (state.message != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(text.message(state.message!)),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.busy ? null : _submit,
                      child: Text(
                        state.busy
                            ? text.text('auth.wait')
                            : _register
                            ? text.text('auth.create')
                            : text.text('auth.signIn'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(text.text('auth.or')),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // google authentication does not require the email form fields
                    OutlinedButton.icon(
                      key: const Key('googleSignIn'),
                      onPressed: state.busy
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              model.signInWithGoogle();
                            },
                      icon: Image.asset(
                        'assets/images/google_g.png',
                        width: 20,
                        height: 20,
                        excludeFromSemantics: true,
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                      ),
                      label: Text(text.text('auth.google')),
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () {
                              model.clearFeedback();
                              _password.clear();
                              _form.currentState!.reset();
                              setState(() => _register = !_register);
                            },
                      child: Text(
                        _register
                            ? text.text('auth.haveAccount')
                            : text.text('auth.newAccount'),
                      ),
                    ),
                    if (!_register)
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () {
                                if (_emailError(context, _email.text) != null) {
                                  _form.currentState!.validate();
                                  return;
                                }
                                model.resetPassword(_email.text);
                              },
                        child: Text(text.text('auth.forgot')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
