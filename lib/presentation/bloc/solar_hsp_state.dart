import '../../domain/entities/solar_engine_result.dart';

abstract class SolarHspState {}

class SolarHspInitial extends SolarHspState {}

class SolarHspLoading extends SolarHspState {}

class SolarHspSuccess extends SolarHspState {
  final SolarEngineResult result;
  SolarHspSuccess(this.result);
}

class SolarHspError extends SolarHspState {
  final String message;
  SolarHspError(this.message);
}