import 'package:dio/dio.dart';

class NetworkService {
  final Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 180),
  ));
}
