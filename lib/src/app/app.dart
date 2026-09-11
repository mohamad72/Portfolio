import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/market/presentation/manager/market_cubit.dart';
import '../features/market/presentation/pages/market_overview_page.dart';
import '../shared/di/di_config.dart';

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'پرتفوی',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: BlocProvider<MarketCubit>(
        create: (_) => getIt<MarketCubit>()..load(),
        child: const MarketOverviewPage(),
      ),
    );
  }
}
