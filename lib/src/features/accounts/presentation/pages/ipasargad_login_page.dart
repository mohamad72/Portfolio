import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/di/di_config.dart';
import '../manager/broker_accounts_cubit.dart';
import '../manager/ipasargad_login_cubit.dart';
import '../manager/ipasargad_login_state.dart';

class IPasargadLoginPage extends StatefulWidget {
  const IPasargadLoginPage({super.key});

  @override
  State<IPasargadLoginPage> createState() => _IPasargadLoginPageState();
}

class _IPasargadLoginPageState extends State<IPasargadLoginPage> {
  final _labelController = TextEditingController(text: 'آی‌پاسارگاد');
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IPasargadLoginCubit>(
      create: (_) => getIt<IPasargadLoginCubit>()..loadCaptcha(),
      child: Scaffold(
        appBar: AppBar(title: const Text('افزودن حساب آی‌پاسارگاد')),
        body: BlocConsumer<IPasargadLoginCubit, IPasargadLoginState>(
          listener: (context, state) async {
            if (state is IPasargadLoginError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is IPasargadLoginSuccess) {
              await context.read<BrokerAccountsCubit>().load();
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            }
          },
          builder: (context, state) {
            final captcha = switch (state) {
              IPasargadCaptchaReady(:final captcha) => captcha,
              IPasargadLoginError(:final captcha) => captcha,
              _ => null,
            };
            final submitting = state is IPasargadCaptchaReady && state.submitting;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                const Text(
                  'این اتصال از APIهای مشاهده‌شدهٔ وب آی‌پاسارگاد استفاده می‌کند. رمز فقط برای همان درخواست ورود استفاده می‌شود و توکن نشست در Secure Storage دستگاه نگهداری می‌شود.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'نام نمایشی حساب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری / کد ورود',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'رمز عبور',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (state is IPasargadCaptchaLoading)
                  const Center(child: CircularProgressIndicator())
                else if (captcha != null)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 72),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.memory(
                            base64Decode(captcha.imageBase64),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'کپچای جدید',
                        onPressed: submitting
                            ? null
                            : context.read<IPasargadLoginCubit>().loadCaptcha,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _captchaController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'کد کپچا',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: captcha == null || submitting
                      ? null
                      : () => context.read<IPasargadLoginCubit>().login(
                            loginName: _loginController.text,
                            password: _passwordController.text,
                            captchaValue: _captchaController.text,
                            accountLabel: _labelController.text,
                          ),
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('اتصال حساب'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
