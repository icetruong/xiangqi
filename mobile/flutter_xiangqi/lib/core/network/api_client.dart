import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? dioOverride})
      : dio = dioOverride ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );

  // Future methods will be added here
}

final dioProvider = Provider<Dio>((ref) {
  return ApiClient().dio;
});
