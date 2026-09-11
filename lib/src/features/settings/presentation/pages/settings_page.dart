import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                          ? 'نشست روی این دستگاه ذخیره شده است.'
                          : 'وارد نشده‌اید.',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: signedIn
                          ? OutlinedButton.icon(
                              onPressed: () => context
                                  .read<AuthenticationCubit>()
                                  .logout(),
                              icon: const Icon(Icons.logout),
                              label: const Text('خروج و حذف نشست'),
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
                  '• موجودی و قیمت جاری: از APIهای خواندنی مفید؛ تطبیق ریال/تومان مفید باید روی دستگاه کنترل شود.',
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
              'امنیت مفید: رمز مفید در اپ ذخیره نمی‌شود. ورود داخل صفحهٔ خود مفید انجام می‌شود و فقط نشست دریافت‌شده در Secure Storage دستگاه نگهداری می‌شود. یوزر/پس اشتراک‌گذاری پرتفوی جدا از حساب مفید و عمداً داخل کد ثابت است.',
            ),
          ),
        ),
      ],
    );
  }
}
