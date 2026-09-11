import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../portfolio/presentation/manager/portfolio_cubit.dart';
import '../manager/broker_accounts_cubit.dart';
import 'ipasargad_login_page.dart';

class AddAccountPage extends StatelessWidget {
  const AddAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('افزودن اکانت')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: ListTile(
              leading: Icon(Icons.account_balance_outlined),
              title: Text('آی‌پاسارگاد'),
              subtitle: Text('در این مرحله تنها ارائه‌دهندهٔ قابل افزودن'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
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
                    child: const IPasargadLoginPage(),
                  ),
                ),
              );
              if (added == true && context.mounted) {
                await context.read<PortfolioCubit>().load();
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('افزودن حساب آی‌پاسارگاد'),
          ),
        ],
      ),
    );
  }
}
