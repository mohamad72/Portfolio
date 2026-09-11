import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/share_credentials.dart';
import '../manager/sharing_cubit.dart';
import '../manager/sharing_state.dart';
import 'shared_portfolio_page.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({super.key});

  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController(
    text: ShareCredentials.username,
  );
  final _passwordController = TextEditingController(
    text: ShareCredentials.password,
  );

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اشتراک‌گذاری پرتفوی')),
      body: BlocBuilder<SharingCubit, SharingState>(
        builder: (context, state) {
          final busy = state is SharingBusy;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              _ownerCard(context, state, busy),
              const SizedBox(height: 12),
              _viewerCard(context, busy),
              if (state is SharingFailure) ...<Widget>[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(state.message),
                  ),
                ),
              ],
              if (state is SharingBusy) ...<Widget>[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                Center(child: Text(state.message)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _ownerCard(
    BuildContext context,
    SharingState state,
    bool busy,
  ) {
    if (state is SharingHosting) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'اشتراک روی گوشی مالک فعال است',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'گوشی بیننده باید به همان Wi‑Fi یا شبکهٔ محلی دسترسی داشته باشد.',
              ),
              const SizedBox(height: 12),
              for (final url in state.serverInfo.urls)
                _copyRow(context, 'آدرس', url),
              _copyRow(context, 'نام کاربری', state.serverInfo.username),
              _copyRow(context, 'رمز', state.serverInfo.password),
              const SizedBox(height: 8),
              Text(
                'آخرین انتشار: ${state.bundle.publishedAt.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => context
                              .read<SharingCubit>()
                              .refreshHosting(),
                      icon: const Icon(Icons.sync),
                      label: const Text('تازه‌سازی'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () =>
                              context.read<SharingCubit>().stopHosting(),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('توقف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'گوشی مالک',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'یک سرور HTTP کوچک داخل خود اپ اجرا می‌شود و snapshot پرتفوی را با یوزر/پس ثابت در اختیار گوشی دیگر می‌گذارد.',
            ),
            const SizedBox(height: 8),
            Text('نام کاربری داخل کد: ${ShareCredentials.username}'),
            Text('رمز داخل کد: ${ShareCredentials.password}'),
            Text('پورت: ${ShareCredentials.port}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  busy ? null : () => context.read<SharingCubit>().startHosting(),
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('شروع اشتراک'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewerCard(BuildContext context, bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'گوشی بیننده',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverController,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'آدرس گوشی مالک',
                hintText: '192.168.1.20:8787',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'نام کاربری',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رمز',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : () => _connect(context),
              icon: const Icon(Icons.link),
              label: const Text('اتصال و مشاهده'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _copyRow(BuildContext context, String label, String value) {
    return Row(
      children: <Widget>[
        SizedBox(width: 90, child: Text(label)),
        Expanded(
          child: SelectableText(
            value,
            textDirection: TextDirection.ltr,
          ),
        ),
        IconButton(
          tooltip: 'کپی',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label کپی شد.')),
              );
            }
          },
          icon: const Icon(Icons.copy),
        ),
      ],
    );
  }

  Future<void> _connect(BuildContext context) async {
    final bundle = await context.read<SharingCubit>().connect(
          serverAddress: _serverController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );
    if (bundle == null || !context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SharedPortfolioPage(bundle: bundle),
      ),
    );
  }
}
