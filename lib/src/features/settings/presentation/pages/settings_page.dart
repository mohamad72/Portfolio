import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../accounts/presentation/manager/broker_accounts_cubit.dart';
import '../../../accounts/presentation/manager/broker_accounts_state.dart';
import '../../../accounts/presentation/pages/accounts_page.dart';
import '../../../portfolio/presentation/manager/portfolio_cubit.dart';
import '../../../authentication/presentation/manager/authentication_cubit.dart';
import '../../../authentication/presentation/manager/authentication_state.dart';
import '../../../sharing/presentation/manager/sharing_cubit.dart';
import '../../../sharing/presentation/manager/sharing_state.dart';
import '../../../sharing/presentation/pages/sharing_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        BlocBuilder<AuthenticationCubit, AuthenticationState>(
          builder: (context, state) {
            final signedIn = state is AuthenticationSignedIn;
            return Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      signedIn ? Icons.verified_user : Icons.person_outline,
                    ),
                    title: const Text('اتصال مفید'),
                    subtitle: Text(
                      signedIn
                          ? 'نشست و اطلاعات ورود امن روی این دستگاه آماده است؛ اجرای بعدی با اثر انگشت باز می‌شود.'
                          : 'وارد نشده‌اید.',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: signedIn
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                OutlinedButton.icon(
                                  onPressed: () => context
                                      .read<AuthenticationCubit>()
                                      .logout(),
                                  icon: const Icon(Icons.logout),
                                  label: const Text('خروج از نشست'),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => context
                                      .read<AuthenticationCubit>()
                                      .logout(forgetCredentials: true),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('خروج و حذف ورود ذخیره‌شده'),
                                ),
                              ],
                            )
                          : FilledButton.icon(
                              onPressed: onLogin,
                              icon: const Icon(Icons.login),
                              label: const Text('ورود به مفید'),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        BlocBuilder<AuthenticationCubit, AuthenticationState>(
          builder: (context, authState) {
            if (authState is! AuthenticationSignedIn) {
              return const SizedBox.shrink();
            }
            return BlocBuilder<BrokerAccountsCubit, BrokerAccountsState>(
              builder: (context, state) {
                final count = state is BrokerAccountsLoaded
                    ? state.accounts.length
                    : 0;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_card_outlined),
                    title: const Text('افزودن اکانت'),
                    subtitle: Text(
                      count == 0
                          ? 'اتصال حساب آی‌پاسارگاد به پرتفوی'
                          : '$count حساب اضافه متصل است؛ فعلاً فقط آی‌پاسارگاد',
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider<BrokerAccountsCubit>.value(
                              value: context.read<BrokerAccountsCubit>(),
                            ),
                            BlocProvider<PortfolioCubit>.value(
                              value: context.read<PortfolioCubit>(),
                            ),
                          ],
                          child: const AccountsPage(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        BlocBuilder<SharingCubit, SharingState>(
          builder: (context, state) {
            final hosting = state is SharingHosting;
            return Card(
              child: ListTile(
                leading: Icon(
                  hosting ? Icons.wifi_tethering : Icons.share_outlined,
                ),
                title: const Text('اشتراک‌گذاری پرتفوی'),
                subtitle: Text(
                  hosting
                      ? 'اشتراک روی شبکهٔ محلی فعال است.'
                      : 'اتصال مستقیم با آدرس گوشی مالک و یوزر/پس ثابت.',
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const SharingPage()),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'وضعیت داده‌ها',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  '• موجودی جاری: مفید + حساب‌های افزوده‌شدهٔ آی‌پاسارگاد؛ دارایی هم‌نام در هر حساب کارت جدا دارد.',
                ),
                Text(
                  '• دلار و طلای ۱۸ عیار: TGJU با تبدیل واحد تأییدشده به تومان.',
                ),
                Text(
                  '• ارزش جاری را می‌توان به واحد معادل عیار دید؛ بازده تاریخی نسبی تا کامل‌شدن تاریخچه ناموجود است.',
                ),
                Text(
                  '• سود تاریخی سبدهای محلی: تا دریافت اجرای مستقل معاملات، ناموجود.',
                ),
                Text(
                  '• اشتراک‌گذاری فعلی: مستقیم بین دو گوشی روی شبکهٔ محلی؛ بدون backend و فقط به‌صورت snapshot خواندنی.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'امنیت ورود: ورود مفید مستقیماً با HTTP/API انجام می‌شود. پس از ورود موفق، نام کاربری و رمز مفید در Secure Storage گوشی نگهداری می‌شوند و اجرای بعدی با local biometric باز می‌شود؛ اگر توکن منقضی شده باشد، پس از اثر انگشت ورود API با credential ذخیره‌شده تکرار می‌شود. یوزر/پس اشتراک‌گذاری پرتفوی جدا از حساب‌های سرمایه‌گذاری و عمداً داخل کد ثابت است.',
            ),
          ),
        ),
      ],
    );
  }
}
