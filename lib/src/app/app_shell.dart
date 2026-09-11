import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/accounts/presentation/manager/broker_accounts_cubit.dart';
import '../features/authentication/presentation/manager/authentication_cubit.dart';
import '../features/authentication/presentation/manager/authentication_state.dart';
import '../features/authentication/presentation/pages/mofid_login_page.dart';
import '../features/market/presentation/manager/market_cubit.dart';
import '../features/market/presentation/pages/market_overview_page.dart';
import '../features/portfolio/presentation/manager/portfolio_cubit.dart';
import '../features/portfolio/presentation/pages/portfolio_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/watchlist/presentation/manager/watchlist_cubit.dart';
import '../features/watchlist/presentation/pages/watchlist_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;
  var _biometricAutoPrompted = false;

  static const List<String> _titles = <String>[
    'پرتفوی',
    'بازار',
    'دیده‌بان',
    'تنظیمات',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationBiometricRequired &&
            !_biometricAutoPrompted) {
          _biometricAutoPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<AuthenticationCubit>().unlockWithBiometrics();
            }
          });
        }
        if (state is AuthenticationSignedIn) {
          context.read<BrokerAccountsCubit>().load();
          context.read<PortfolioCubit>().load();
          context.read<WatchlistCubit>().load();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: <Widget>[
            if (_index == 0)
              IconButton(
                tooltip: 'همگام‌سازی پرتفوی',
                onPressed: () => context.read<PortfolioCubit>().load(),
                icon: const Icon(Icons.sync),
              ),
            if (_index == 1)
              IconButton(
                tooltip: 'به‌روزرسانی بازار',
                onPressed: () => context.read<MarketCubit>().load(),
                icon: const Icon(Icons.refresh),
              ),
            if (_index == 2)
              IconButton(
                tooltip: 'به‌روزرسانی دیده‌بان',
                onPressed: () => context.read<WatchlistCubit>().load(),
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            _AuthenticatedFeature(
              child: const PortfolioPage(),
              onLogin: () => _openLogin(context),
            ),
            const MarketOverviewPage(),
            _AuthenticatedFeature(
              child: const WatchlistPage(),
              onLogin: () => _openLogin(context),
            ),
            SettingsPage(onLogin: () => _openLogin(context)),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'پرتفوی',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              label: 'بازار',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: 'دیده‌بان',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    final authenticationCubit = context.read<AuthenticationCubit>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider<AuthenticationCubit>.value(
          value: authenticationCubit,
          child: const MofidLoginPage(),
        ),
      ),
    );
  }
}

class _AuthenticatedFeature extends StatelessWidget {
  const _AuthenticatedFeature({
    required this.child,
    required this.onLogin,
  });

  final Widget child;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
      builder: (context, state) {
        if (state is AuthenticationSignedIn) {
          return child;
        }
        if (state is AuthenticationUnknown ||
            state is AuthenticationLoggingIn ||
            state is AuthenticationBiometricAuthenticating) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AuthenticationBiometricRequired) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.fingerprint, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    state.message ??
                        'اطلاعات ورود مفید روی این گوشی ذخیره شده است. برای باز کردن پرتفوی اثر انگشت را تأیید کنید.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<AuthenticationCubit>()
                        .unlockWithBiometrics(),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('ورود با اثر انگشت'),
                  ),
                  TextButton(
                    onPressed: onLogin,
                    child: const Text('ورود دستی'),
                  ),
                ],
              ),
            ),
          );
        }

        final message = state is AuthenticationError
            ? state.message
            : 'برای مشاهدهٔ اطلاعات حساب و نمادهای مفید، ابتدا وارد حساب مفید شوید.';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('ورود به مفید'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
