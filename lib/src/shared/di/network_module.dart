import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/browser_user_agent.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio() => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 10),
          headers: const <String, dynamic>{
            'User-Agent': browserUserAgent,
            'Accept': 'application/json',
          },
        ),
      );

  @preResolve
  Future<SharedPreferences> preferences() => SharedPreferences.getInstance();

  @lazySingleton
  FlutterSecureStorage secureStorage() => const FlutterSecureStorage();

  @lazySingleton
  LocalAuthentication localAuthentication() => LocalAuthentication();
}
