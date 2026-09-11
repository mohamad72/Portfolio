// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/accounts/data/repository/ipasargad_authentication_repository_impl.dart'
    as _i305;
import '../../features/accounts/data/repository/preferences_broker_account_repository_impl.dart'
    as _i974;
import '../../features/accounts/data/security/ipasargad_session_store.dart'
    as _i491;
import '../../features/accounts/domain/repository/broker_account_repository.dart'
    as _i101;
import '../../features/accounts/domain/repository/ipasargad_authentication_repository.dart'
    as _i670;
import '../../features/accounts/presentation/manager/broker_accounts_cubit.dart'
    as _i968;
import '../../features/accounts/presentation/manager/ipasargad_login_cubit.dart'
    as _i903;
import '../../features/authentication/data/remote/mofid_login_remote_data_source.dart'
    as _i57;
import '../../features/authentication/data/repository/mofid_authentication_repository_impl.dart'
    as _i955;
import '../../features/authentication/data/security/mofid_credential_store.dart'
    as _i445;
import '../../features/authentication/domain/repository/authentication_repository.dart'
    as _i797;
import '../../features/authentication/presentation/manager/authentication_cubit.dart'
    as _i317;
import '../../features/benchmark/domain/relative_return_calculator.dart'
    as _i52;
import '../../features/export/data/markdown_file_writer.dart' as _i141;
import '../../features/export/domain/markdown_portfolio_exporter.dart' as _i575;
import '../../features/market/data/repository/tgju_market_repository_impl.dart'
    as _i672;
import '../../features/market/domain/repository/market_repository.dart'
    as _i895;
import '../../features/market/domain/use_case/get_market_prices.dart' as _i1057;
import '../../features/market/presentation/manager/market_cubit.dart' as _i980;
import '../../features/portfolio/data/repository/ipasargad_portfolio_repository_impl.dart'
    as _i981;
import '../../features/portfolio/data/repository/mofid_portfolio_repository_impl.dart'
    as _i413;
import '../../features/portfolio/data/repository/multi_account_portfolio_repository_impl.dart'
    as _i24;
import '../../features/portfolio/data/repository/preferences_local_portfolio_repository_impl.dart'
    as _i554;
import '../../features/portfolio/data/source/ipasargad_portfolio_source.dart'
    as _i416;
import '../../features/portfolio/data/source/mofid_portfolio_source.dart'
    as _i638;
import '../../features/portfolio/domain/repository/local_portfolio_repository.dart'
    as _i967;
import '../../features/portfolio/domain/repository/portfolio_repository.dart'
    as _i826;
import '../../features/portfolio/domain/use_case/get_account_snapshot.dart'
    as _i307;
import '../../features/portfolio/domain/use_case/get_local_portfolios.dart'
    as _i433;
import '../../features/portfolio/domain/use_case/save_symbol_allocations.dart'
    as _i741;
import '../../features/portfolio/presentation/manager/portfolio_cubit.dart'
    as _i350;
import '../../features/sharing/data/repository/lan_portfolio_sharing_repository_impl.dart'
    as _i904;
import '../../features/sharing/domain/repository/portfolio_sharing_repository.dart'
    as _i1008;
import '../../features/sharing/presentation/manager/sharing_cubit.dart'
    as _i910;
import '../../features/watchlist/data/repository/watchlist_repository_impl.dart'
    as _i883;
import '../../features/watchlist/domain/repository/watchlist_repository.dart'
    as _i132;
import '../../features/watchlist/presentation/manager/watchlist_cubit.dart'
    as _i417;
import '../network/dio_remote_data_source.dart' as _i392;
import '../network/remote_data_source.dart' as _i313;
import '../security/biometric_authenticator.dart' as _i374;
import '../security/secure_session_store.dart' as _i675;
import 'network_module.dart' as _i567;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => networkModule.preferences(),
      preResolve: true,
    );
    gh.lazySingleton<_i52.RelativeReturnCalculator>(
      () => const _i52.RelativeReturnCalculator(),
    );
    gh.lazySingleton<_i141.MarkdownFileWriter>(
      () => const _i141.MarkdownFileWriter(),
    );
    gh.lazySingleton<_i575.MarkdownPortfolioExporter>(
      () => const _i575.MarkdownPortfolioExporter(),
    );
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio());
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => networkModule.secureStorage(),
    );
    gh.lazySingleton<_i152.LocalAuthentication>(
      () => networkModule.localAuthentication(),
    );
    gh.lazySingleton<_i57.MofidLoginRemoteDataSource>(
      () => _i57.DioMofidLoginRemoteDataSource(),
    );
    gh.lazySingleton<_i675.SessionStore>(
      () => _i675.SecureSessionStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i445.MofidCredentialStore>(
      () => _i445.SecureMofidCredentialStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i491.IPasargadSessionStore>(
      () => _i491.SecureIPasargadSessionStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i313.RemoteDataSource>(
      () => _i392.DioRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i895.MarketRepository>(
      () => _i672.TgjuMarketRepositoryImpl(gh<_i313.RemoteDataSource>()),
    );
    gh.lazySingleton<_i132.WatchlistRepository>(
      () => _i883.WatchlistRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i313.RemoteDataSource>(),
        gh<_i675.SessionStore>(),
      ),
    );
    gh.lazySingleton<_i638.MofidPortfolioSource>(
      () => _i413.MofidPortfolioRepositoryImpl(
        gh<_i313.RemoteDataSource>(),
        gh<_i675.SessionStore>(),
      ),
    );
    gh.lazySingleton<_i101.BrokerAccountRepository>(
      () => _i974.PreferencesBrokerAccountRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i675.SessionStore>(),
      ),
    );
    gh.lazySingleton<_i374.BiometricAuthenticator>(
      () => _i374.LocalBiometricAuthenticator(gh<_i152.LocalAuthentication>()),
    );
    gh.lazySingleton<_i967.LocalPortfolioRepository>(
      () => _i554.PreferencesLocalPortfolioRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i675.SessionStore>(),
      ),
    );
    gh.lazySingleton<_i670.IPasargadAuthenticationRepository>(
      () => _i305.IPasargadAuthenticationRepositoryImpl(
        gh<_i313.RemoteDataSource>(),
        gh<_i101.BrokerAccountRepository>(),
        gh<_i491.IPasargadSessionStore>(),
      ),
    );
    gh.lazySingleton<_i1057.GetMarketPrices>(
      () => _i1057.GetMarketPrices(gh<_i895.MarketRepository>()),
    );
    gh.lazySingleton<_i416.IPasargadPortfolioSource>(
      () => _i981.IPasargadPortfolioRepositoryImpl(
        gh<_i313.RemoteDataSource>(),
        gh<_i491.IPasargadSessionStore>(),
      ),
    );
    gh.lazySingleton<_i433.GetLocalPortfolios>(
      () => _i433.GetLocalPortfolios(gh<_i967.LocalPortfolioRepository>()),
    );
    gh.lazySingleton<_i741.SaveSymbolAllocations>(
      () => _i741.SaveSymbolAllocations(gh<_i967.LocalPortfolioRepository>()),
    );
    gh.lazySingleton<_i417.WatchlistCubit>(
      () => _i417.WatchlistCubit(gh<_i132.WatchlistRepository>()),
    );
    gh.factory<_i903.IPasargadLoginCubit>(
      () => _i903.IPasargadLoginCubit(
        gh<_i670.IPasargadAuthenticationRepository>(),
      ),
    );
    gh.lazySingleton<_i797.AuthenticationRepository>(
      () => _i955.MofidAuthenticationRepositoryImpl(
        gh<_i313.RemoteDataSource>(),
        gh<_i57.MofidLoginRemoteDataSource>(),
        gh<_i675.SessionStore>(),
        gh<_i445.MofidCredentialStore>(),
        gh<_i374.BiometricAuthenticator>(),
      ),
    );
    gh.lazySingleton<_i968.BrokerAccountsCubit>(
      () => _i968.BrokerAccountsCubit(
        gh<_i101.BrokerAccountRepository>(),
        gh<_i491.IPasargadSessionStore>(),
      ),
    );
    gh.factory<_i980.MarketCubit>(
      () => _i980.MarketCubit(gh<_i1057.GetMarketPrices>()),
    );
    gh.lazySingleton<_i826.PortfolioRepository>(
      () => _i24.MultiAccountPortfolioRepositoryImpl(
        gh<_i638.MofidPortfolioSource>(),
        gh<_i416.IPasargadPortfolioSource>(),
        gh<_i101.BrokerAccountRepository>(),
      ),
    );
    gh.lazySingleton<_i1008.PortfolioSharingRepository>(
      () => _i904.LanPortfolioSharingRepositoryImpl(
        gh<_i826.PortfolioRepository>(),
        gh<_i967.LocalPortfolioRepository>(),
        gh<_i361.Dio>(),
      ),
    );
    gh.lazySingleton<_i317.AuthenticationCubit>(
      () => _i317.AuthenticationCubit(gh<_i797.AuthenticationRepository>()),
    );
    gh.lazySingleton<_i910.SharingCubit>(
      () => _i910.SharingCubit(gh<_i1008.PortfolioSharingRepository>()),
    );
    gh.lazySingleton<_i307.GetAccountSnapshot>(
      () => _i307.GetAccountSnapshot(gh<_i826.PortfolioRepository>()),
    );
    gh.lazySingleton<_i350.PortfolioCubit>(
      () => _i350.PortfolioCubit(
        gh<_i307.GetAccountSnapshot>(),
        gh<_i967.LocalPortfolioRepository>(),
        gh<_i741.SaveSymbolAllocations>(),
      ),
    );
    return this;
  }
}

class _$NetworkModule extends _i567.NetworkModule {}
