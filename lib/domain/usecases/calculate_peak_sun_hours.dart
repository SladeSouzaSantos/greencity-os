import 'package:injectable/injectable.dart';

import '../entities/solar_scenario.dart';
import '../entities/solar_engine_result.dart';
import '../repositories/solar_repository.dart';

@injectable
class CalculatePeakSunHours {
  final SolarRepository repository;

  CalculatePeakSunHours(this.repository);

  Future<SolarEngineResult> call(double lat, double lon, List<SolarScenario> items) async {
    // Aqui você pode validar se a lista não está vazia, por exemplo
    if (items.isEmpty) throw Exception("Adicione ao menos um cenário para calcular.");
    
    return await repository.calculateArray(
      latitude: lat,
      longitude: lon,
      items: items,
    );
  }
}