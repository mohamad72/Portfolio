import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/authentication/presentation/manager/authentication_cubit.dart';
import '../features/market/presentation/manager/market_cubit.dart';
import '../features/portfolio/presentation/manager/portfolio_cubit.dart';
import '../features/sharing/presentation/manager/sharing_cubit.dart';
import '../features/watchlist/presentation/manager/watchlist_cubit.dart';
import '../shared/di/di_config.dart';
import 'app_shell.dart';

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticationCubit = getIt<AuthenticationCubit>()..checkSession();
    final portfolioCubit = getIt<PortfolioCubit>();
    final watchlistCubit = getIt<WatchlistCubit>();
    final sharingCubit = getIt<SharingCubit>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationCubit>.value(value: authenticationCubit),
        BlocProvider<PortfolioCubit>.value(value: portfolioCubit),
        BlocProvider<WatchlistCubit>.value(value: watchlistCubit),
        BlocProvider<SharingCubit>.value(value: sharingCubit),
        BlocProvider<MarketCubit>(
          create: (_) => getIt<MarketCubit>()..load(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'پرتفوی',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
          ),
        ),
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AppShell(),
      ),
    );
  }
}
