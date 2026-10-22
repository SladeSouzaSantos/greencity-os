import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/pv_module.dart';
import '../../domain/entities/inverter.dart';

@module
abstract class ExternalModules {
  @lazySingleton
  Dio get dio {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Este interceptor vai printar TUDO no seu console (URL, Body, Headers)
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    return dio;
  }
  
  @preResolve
  Future<Isar> get isar async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [PvModuleSchema, InverterSchema], // Adicione seus schemas aqui
      directory: dir.path,
    );
  }
}