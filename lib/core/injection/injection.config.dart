// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i3;
import 'package:get_it/get_it.dart' as _i1;
import 'package:greencity_os/core/injection/external_modules.dart' as _i10;
import 'package:greencity_os/data/datasources/solar_remote_data_source.dart'
    as _i5;
import 'package:greencity_os/data/repositories/solar_repository_impl.dart'
    as _i7;
import 'package:greencity_os/domain/repositories/solar_repository.dart' as _i6;
import 'package:greencity_os/domain/usecases/calculate_peak_sun_hours.dart'
    as _i8;
import 'package:greencity_os/presentation/bloc/solar_hsp_bloc.dart' as _i9;
import 'package:injectable/injectable.dart' as _i2;
import 'package:isar/isar.dart' as _i4;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final externalModules = _$ExternalModules();
    gh.lazySingleton<_i3.Dio>(() => externalModules.dio);
    await gh.factoryAsync<_i4.Isar>(
      () => externalModules.isar,
      preResolve: true,
    );
    gh.lazySingleton<_i5.SolarRemoteDataSource>(
        () => _i5.SolarRemoteDataSourceImpl(dio: gh<_i3.Dio>()));
    gh.lazySingleton<_i6.SolarRepository>(() => _i7.SolarRepositoryImpl(
        remoteDataSource: gh<_i5.SolarRemoteDataSource>()));
    gh.factory<_i8.CalculatePeakSunHours>(
        () => _i8.CalculatePeakSunHours(gh<_i6.SolarRepository>()));
    gh.factory<_i9.SolarHspBloc>(
        () => _i9.SolarHspBloc(gh<_i8.CalculatePeakSunHours>()));
    return this;
  }
}

class _$ExternalModules extends _i10.ExternalModules {}
