import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../portfolio/presentation/manager/portfolio_cubit.dart';
import '../../domain/entities/broker_provider.dart';
import '../manager/broker_accounts_cubit.dart';
import '../manager/broker_accounts_state.dart';
import 'add_account_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حساب‌های سرمایه‌گذاری')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<BrokerAccountsCubit>.value(
                    value: context.read<BrokerAccountsCubit>(),
                  ),
                  BlocProvider<PortfolioCubit>.value(
                    value: context.read<PortfolioCubit>(),
                  ),
                ],
                child: const AddAccountPage(),
              ),
            ),
          );
          if (changed == true && context.mounted) {
            await context.read<BrokerAccountsCubit>().load();
            if (context.mounted) {
              await context.read<PortfolioCubit>().load();
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('افزودن اکانت'),
      ),
      body: BlocBuilder<BrokerAccountsCubit, BrokerAccountsState>(
        builder: (context, state) {
          if (state is BrokerAccountsInitial) {
            context.read<BrokerAccountsCubit>().load();
          }
          if (state is BrokerAccountsLoading || state is BrokerAccountsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerAccountsError) {
            return Center(child: Text(state.message));
          }
          final accounts = (state as BrokerAccountsLoaded).accounts;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: <Widget>[
              const Card(
                child: ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined),
                  title: Text('مفید'),
                  subtitle: Text('حساب اصلی اپ'),
                  trailing: Chip(label: Text('اصلی')),
                ),
              ),
              for (final account in accounts)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(account.label),
                    subtitle: Text(account.provider.label),
                    trailing: IconButton(
                      tooltip: 'حذف حساب',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await context.read<BrokerAccountsCubit>().remove(account.id);
                        if (context.mounted) {
                          await context.read<PortfolioCubit>().load();
                        }
                      },
                    ),
                  ),
                ),
              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'هنوز حساب اضافه‌ای متصل نشده است. از «افزودن اکانت» آی‌پاسارگاد را متصل کنید.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
