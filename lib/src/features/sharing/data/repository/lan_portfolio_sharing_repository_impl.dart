import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../portfolio/domain/repository/local_portfolio_repository.dart';
import '../../../portfolio/domain/repository/portfolio_repository.dart';
import '../../domain/entities/share_server_info.dart';
import '../../domain/entities/shared_portfolio_bundle.dart';
import '../../domain/repository/portfolio_sharing_repository.dart';
import '../models/shared_portfolio_bundle_model.dart';
import '../share_basic_auth.dart';
import '../share_credentials.dart';

@LazySingleton(as: PortfolioSharingRepository)
class LanPortfolioSharingRepositoryImpl implements PortfolioSharingRepository {
  LanPortfolioSharingRepositoryImpl(
    this._portfolioRepository,
    this._localPortfolioRepository,
    this._dio,
  );

  final PortfolioRepository _portfolioRepository;
  final LocalPortfolioRepository _localPortfolioRepository;
  final Dio _dio;

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _serverSubscription;
  SharedPortfolioBundle? _publishedBundle;

  @override
  bool get isServerRunning => _server != null;

  @override
  SharedPortfolioBundle? get publishedBundle => _publishedBundle;

  @override
  Future<Either<Failure, SharedPortfolioBundle>> refreshPublishedBundle() async {
    final snapshotResult = await _portfolioRepository.getAccountSnapshot();
    final snapshotFailure = snapshotResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (snapshotFailure != null) {
      return left(snapshotFailure);
    }

    final portfoliosResult = await _localPortfolioRepository.getPortfolios();
    final portfolioFailure = portfoliosResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (portfolioFailure != null) {
      return left(portfolioFailure);
    }

    final allocationsResult = await _localPortfolioRepository.getAllocations();
    final allocationFailure = allocationsResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (allocationFailure != null) {
      return left(allocationFailure);
    }

    final bundle = SharedPortfolioBundle(
      snapshot: snapshotResult.getOrElse(
        () => throw StateError('snapshot result unexpectedly missing'),
      ),
      portfolios: portfoliosResult.getOrElse(() => const []),
      allocations: allocationsResult.getOrElse(() => const []),
      publishedAt: DateTime.now(),
    );
    _publishedBundle = bundle;
    return right(bundle);
  }

  @override
  Future<Either<Failure, ShareServerInfo>> startServer() async {
    try {
      if (_publishedBundle == null) {
        final refreshResult = await refreshPublishedBundle();
        final failure = refreshResult.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          return left(failure);
        }
      }

      if (_server == null) {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          ShareCredentials.port,
          shared: true,
        );
        _serverSubscription = _server!.listen(_handleRequest);
      }

      final addresses = await _localIpv4Addresses();
      return right(
        ShareServerInfo(
          addresses: addresses,
          port: ShareCredentials.port,
          username: ShareCredentials.username,
          password: ShareCredentials.password,
        ),
      );
    } catch (error, stackTrace) {
      await _serverSubscription?.cancel();
      _serverSubscription = null;
      await _server?.close(force: true);
      _server = null;
      return left(
        Failure.detailed(
          'راه‌اندازی اشتراک‌گذاری محلی ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> stopServer() async {
    try {
      await _serverSubscription?.cancel();
      _serverSubscription = null;
      await _server?.close(force: true);
      _server = null;
      return right(unit);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'توقف اشتراک‌گذاری ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SharedPortfolioBundle>> connect({
    required String serverAddress,
    required String username,
    required String password,
  }) async {
    final normalized = _normalizeAddress(serverAddress);
    if (normalized == null) {
      return left(
        const Failure('آدرس معتبر نیست. نمونه: 192.168.1.20:8787'),
      );
    }

    try {
      final response = await _dio.get<Object?>(
        '$normalized/portfolio',
        options: Options(
          headers: <String, dynamic>{
            HttpHeaders.authorizationHeader:
                ShareBasicAuth.authorizationHeader(username, password),
            HttpHeaders.acceptHeader: ContentType.json.mimeType,
          },
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == HttpStatus.unauthorized) {
        return left(
          Failure.invalidResponse(
            'نام کاربری یا رمز اشتراک‌گذاری اشتباه است.',
            <String, Object?>{
              'statusCode': response.statusCode,
              'statusMessage': response.statusMessage,
              'data': response.data,
            },
          ),
        );
      }
      if (response.statusCode != HttpStatus.ok) {
        return left(
          Failure.invalidResponse(
            'سرور اشتراک‌گذاری پاسخ ${response.statusCode} داد.',
            <String, Object?>{
              'statusCode': response.statusCode,
              'statusMessage': response.statusMessage,
              'data': response.data,
            },
          ),
        );
      }

      final raw = response.data;
      if (raw is! Map) {
        return left(
          Failure.invalidResponse(
            'پاسخ اشتراک‌گذاری معتبر نیست.',
            raw,
          ),
        );
      }
      final json = raw.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
      return right(SharedPortfolioBundleModel.fromJson(json).toDomain());
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'اتصال به پرتفوی اشتراکی ناموفق بود. هر دو گوشی باید به یک شبکه دسترسی داشته باشند.',
          error,
          stackTrace,
        ),
      );
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers.set(
      HttpHeaders.contentTypeHeader,
      ContentType.json.mimeType,
    );
    request.response.headers.set('Cache-Control', 'no-store');

    if (request.method == 'GET' && request.uri.path == '/health') {
      request.response.statusCode = HttpStatus.ok;
      request.response.write(jsonEncode(<String, dynamic>{'ok': true}));
      await request.response.close();
      return;
    }

    if (request.method != 'GET' || request.uri.path != '/portfolio') {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(
        jsonEncode(<String, dynamic>{'error': 'not_found'}),
      );
      await request.response.close();
      return;
    }

    final authorization =
        request.headers.value(HttpHeaders.authorizationHeader);
    if (!ShareBasicAuth.isAuthorized(authorization)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.set(
        HttpHeaders.wwwAuthenticateHeader,
        'Basic realm="portfolio"',
      );
      request.response.write(
        jsonEncode(<String, dynamic>{'error': 'unauthorized'}),
      );
      await request.response.close();
      return;
    }

    final bundle = _publishedBundle;
    if (bundle == null) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(
        jsonEncode(<String, dynamic>{'error': 'snapshot_unavailable'}),
      );
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.write(
      jsonEncode(SharedPortfolioBundleModel.fromDomain(bundle).toJson()),
    );
    await request.response.close();
  }

  String? _normalizeAddress(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      return null;
    }
    value = value.replaceAll(RegExp(r'/+$'), '');
    if (!value.contains('://')) {
      if (!RegExp(r':\d+$').hasMatch(value)) {
        value = '$value:${ShareCredentials.port}';
      }
      value = 'http://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty || uri.scheme != 'http') {
      return null;
    }
    if (!RegExp(r':\d+$').hasMatch(uri.authority)) {
      return '${uri.scheme}://${uri.host}:${ShareCredentials.port}';
    }
    return '${uri.scheme}://${uri.authority}';
  }

  Future<List<String>> _localIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final addresses = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (_isPrivateIpv4(address.address)) {
          addresses.add(address.address);
        }
      }
    }
    if (addresses.isEmpty) {
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          addresses.add(address.address);
        }
      }
    }
    return addresses.toList(growable: false)..sort();
  }

  bool _isPrivateIpv4(String address) {
    if (address.startsWith('10.') || address.startsWith('192.168.')) {
      return true;
    }
    final match = RegExp(r'^172\.(\d+)\.').firstMatch(address);
    final second = int.tryParse(match?.group(1) ?? '');
    return second != null && second >= 16 && second <= 31;
  }
}
