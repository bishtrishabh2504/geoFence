import 'package:dio/dio.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart';
import 'package:geofence_demo/helper/local_storage.dart';
const String baseUrl = "https://api.helixtahr.com/api/v1/";
enum HttpMethod { get, post }
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();

  factory NetworkService() => _instance;
  late Dio _dio;

  static const String baseUrl = "https://api.helixtahr.com/api/v1/";
  static const String demoEmail = "NAV1003";
  static const String demoPassword = "Pp@1234567";

  NetworkService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppStoragePref.shared.getAuthToken}'
        },
      ),
    );

    // Add Logging Interceptor
    _dio.interceptors.add(
     LogInterceptor(
       responseHeader: true,
       responseBody: true,
       requestHeader: true,
       requestBody: true,
       request: true
     )
    );
  }
  Future<T> request<T>({
    required String endpoint,
    required HttpMethod method,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      Response response;
      if (method == HttpMethod.get) {
        response = await _dio.get(endpoint, queryParameters: queryParameters);
      } else {
        response = await _dio.post(endpoint, data: data);
      }
      return fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message ?? "Unknown error");
    }
  }
}