import '../entities/hsp.dart';
import '../entities/solar_engine_result.dart';
import '../entities/solar_project.dart';

/// Atualiza a referência de LOCALIDADE sem confundi-la com a POA do arranjo.
/// A API moderna retorna detalhes.hsp_horizontal em cada item. Como fallback
/// para APIs antigas, usamos exclusivamente o cálculo placeholder horizontal.
class SolarReferenceService {
  static void updateProjectReference(
    SolarProject project,
    SolarEngineResult response,
  ) {
    if (response.results.isEmpty) return;
    final result = response.results.first;
    final placeholders = response.results.where((item) => item.id == 'placeholder');
    final placeholder = placeholders.isEmpty ? null : placeholders.first;

    final horizontal = result.horizontalHsp ?? placeholder?.averageHspReal;
    if (horizontal != null && horizontal > 0) {
      final monthly = placeholder?.monthlyHspReal ??
          project.referenceHspHorizontal?.monthlyValues ??
          <double>[];
      project.referenceHspHorizontal = Hsp(
        annualAverage: horizontal,
        monthlyValues: monthly,
      );
    }

    project.hspDataSource = result.dataSource ?? project.hspDataSource;
    project.hspTranspositionModel =
        result.transpositionModel ?? project.hspTranspositionModel;
    project.climate = response.climate;
  }
}
