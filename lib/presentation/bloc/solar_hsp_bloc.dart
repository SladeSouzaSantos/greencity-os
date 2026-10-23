import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/calculate_peak_sun_hours.dart';
import 'solar_hsp_state.dart';

// Evento simples para disparar o cálculo
class CalculateHspEvent {
  final double lat;
  final double lon;
  final List<SolarScenario> items;
  CalculateHspEvent(this.lat, this.lon, this.items);
}

@injectable // Também registramos o BLoC para ser injetado!
class SolarHspBloc extends Bloc<CalculateHspEvent, SolarHspState> {
  final CalculatePeakSunHours calculateUseCase;
  int _latestRequestId = 0;

  SolarHspBloc(this.calculateUseCase) : super(SolarHspInitial()) {
    on<CalculateHspEvent>((event, emit) async {
      final requestId = ++_latestRequestId;
      emit(SolarHspLoading());

      try {
        final result = await calculateUseCase(event.lat, event.lon, event.items);
        if (requestId == _latestRequestId && !emit.isDone) {
          emit(SolarHspSuccess(result));
        }
      } catch (e) {
        if (requestId == _latestRequestId && !emit.isDone) {
          emit(SolarHspError(e.toString()));
        }
      }
    });
  }
}