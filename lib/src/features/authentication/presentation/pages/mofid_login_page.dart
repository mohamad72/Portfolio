import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/authentication_cubit.dart';
import '../manager/authentication_state.dart';

class MofidLoginPage extends StatefulWidget {
  const MofidLoginPage({super.key});

  @override
  State<MofidLoginPage> createState() => _MofidLoginPageState();
}

class _MofidLoginPageState extends State<MofidLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود به مفید')),
      body: SafeArea(
        child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationSignedIn && Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }
            if (state is AuthenticationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final loading = state is AuthenticationLoggingIn;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const Icon(Icons.account_balance, size: 56),
                const SizedBox(height: 20),
                const Text(
                  'ورود مستقیم به مفید',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'نام کاربری و رمز از همین صفحه به مسیر ورود مفید ارسال می‌شوند. پس از ورود موفق، اطلاعات ورود در Secure Storage گوشی ذخیره می‌شود تا دفعات بعد با اثر انگشت وارد شوید.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  enabled: !loading,
                  autofillHints: const <String>[AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری مفید',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  enabled: !loading,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.password],
                  onSubmitted: loading ? null : (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'رمز عبور',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'نمایش رمز' : 'پنهان کردن رمز',
                      onPressed: loading
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(loading ? 'در حال ورود...' : 'ورود'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'اگر مفید در یک ورود خاص کپچا، رمز یک‌بارمصرف یا مرحلهٔ اضافه بخواهد، اپ به‌جای باز کردن مرورگر خطای همان مرحله را اعلام می‌کند تا قرارداد API آن جداگانه اضافه شود.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام کاربری و رمز مفید را وارد کنید.')),
      );
      return;
    }
    context.read<AuthenticationCubit>().login(
          username: username,
          password: password,
        );
  }
}
