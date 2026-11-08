import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar_resource_hour.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';

void main() {
  const panel = Solar3dObject(
    id: 'M01', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(0, 1, 0),
    width: 1, depth: 2, height: 0.05, mpptIndex: 1,
  );

  SolarResourceHour oneHour(int hour, {double direct = 700, double total = 900}) =>
      SolarResourceHour(
        startUtc: DateTime.utc(2023, 1, 1, hour),
        solarAzimuthDegrees: 90,
        apparentSolarElevationDegrees: 45,
        poaGlobalWm2: total,
        poaDirectWm2: direct,
        poaSkyDiffuseWm2: total-direct,
        poaGroundWm2: 0,
      );

  test('Raycasting horizontal: livre, sombra total e ausência de sol frontal', () {
    final clear = Solar3dScene([panel]);
    expect(Solar3dGeometricShading.blockedFraction(
      panel: panel, scene: clear,
      sunAzimuthDegrees: 90, sunElevationDegrees: 45, rows: 2, columns: 2), 0);
    final blocked = Solar3dScene([
      panel,
      const Solar3dObject(
        id: 'overhang', kind: Solar3dObjectKind.obstacle,
        center: Solar3dVector(0, 3, 0),
        width: 10, depth: 10, height: 0.2,
      ),
    ]);
    expect(Solar3dGeometricShading.blockedFraction(
      panel: panel, scene: blocked,
      sunAzimuthDegrees: 90, sunElevationDegrees: 45, rows: 2, columns: 2), 1);
    expect(Solar3dGeometricShading.blockedFraction(
      panel: panel, scene: clear,
      sunAzimuthDegrees: 90, sunElevationDegrees: -5), isNull);
  });

  test('Aplica somente irradiância direta bloqueada, preserva céu difuso', () {
    final hours = List.generate(24, (index) => oneHour(index));
    final resource = HourlySolarResource(
      yearUtc: 2023, monthUtc: 1, source: 'fixture',
      inclinationDegrees: 0, azimuthDegrees: 0,
      monthlyReferenceHsp: List.filled(12, 5),
      samples: hours,
    );
    final blocked = Solar3dScene([
      panel,
      const Solar3dObject(
        id: 'roof', kind: Solar3dObjectKind.obstacle,
        center: Solar3dVector(0, 3, 0),
        width: 10, depth: 10, height: 0.2,
      ),
    ]);
    final result = Solar3dGeometricShading.calculate(
      scene: blocked, resource: resource, rows: 2, columns: 2).single;
    expect(result.referenceHsp, closeTo(21.6, 1e-9));
    expect(result.correctedHsp, closeTo(4.8, 1e-9));
    expect(result.shadeLossPercent, closeTo(100*700/900, 1e-6));
  });

  test('Rejeita POA da inclinação errada para um módulo', () {
    final resource = HourlySolarResource(
      yearUtc: 2023, monthUtc: 1, source: 'fixture',
      inclinationDegrees: 20, azimuthDegrees: 0,
      monthlyReferenceHsp: List.filled(12, 5),
      samples: [oneHour(0)],
    );
    expect(() => Solar3dGeometricShading.calculate(
      scene: const Solar3dScene([panel]), resource: resource, rows: 2,
      columns: 2), throwsFormatException);
  });

  test('Sombra às 17h pode atingir uma placa e não a vizinha', () {
    // A late-afternoon WEST low-angle beam can hit one module yet pass
    // ABOVE an obstacle for another module farther from that obstacle.
    const free = Solar3dObject(
      id: 'M01', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, 1, 0),
      width: 1, depth: 2, height: .05, mpptIndex: 1,
    );
    const shaded = Solar3dObject(
      id: 'M02', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(-4, 1, 0),
      width: 1, depth: 2, height: .05, mpptIndex: 2,
    );
    const obstacle = Solar3dObject(
      id: 'wall', kind: Solar3dObjectKind.obstacle,
      center: Solar3dVector(-6, 1.5, 0),
      width: 1.6, depth: 3, height: 3,
    );
    const scene = Solar3dScene([free, shaded, obstacle]);
    final clear = Solar3dGeometricShading.inspectPanel(
      panel: free, scene: scene,
      sunAzimuthDegrees: 270, sunElevationDegrees: 30,
      rows: 12, columns: 8,
    );
    final blocked = Solar3dGeometricShading.inspectPanel(
      panel: shaded, scene: scene,
      sunAzimuthDegrees: 270, sunElevationDegrees: 30,
      rows: 12, columns: 8,
    );
    expect(clear, isNotNull);
    expect(blocked, isNotNull);
    expect(clear!.totalSamples, 96);
    expect(clear.blockedSamples, 0);
    expect(blocked!.fraction, greaterThan(.5));
    expect(blocked.firstHitByObject['wall'], greaterThan(0));
  });

  test('O diagnóstico diferencia sombra de ausência de feixe frontal', () {
    final inspected = Solar3dGeometricShading.inspectPanel(
      panel: panel, scene: const Solar3dScene([panel]),
      sunAzimuthDegrees: 90, sunElevationDegrees: -3,
      rows: 12, columns: 8,
    );
    expect(inspected, isNull);
    final sunlight = Solar3dGeometricShading.inspectPanel(
      panel: panel, scene: const Solar3dScene([panel]),
      sunAzimuthDegrees: 90, sunElevationDegrees: 30,
      rows: 12, columns: 8,
    );
    expect(sunlight, isNotNull);
    expect(sunlight!.fraction, 0);
    expect(sunlight.blockedSamples, 0);
    expect(sunlight.firstHitByObject, isEmpty);
  });

  test('Valida geometria, IDs duplicados e atribuição ao MPPT', () {
    expect(() => Solar3dScene([panel, panel]).validate(),
      throwsFormatException);
    expect(() => Solar3dScene([
      const Solar3dObject(
        id: 'M02', kind: Solar3dObjectKind.panel,
        center: Solar3dVector(0, 1, 0),
        width: 1, depth: 2, height: 0.05,
      )
    ]).validate(), throwsFormatException);
  });

  test('Valida contrato e rejeita amostra anual incompleta', () {
    final json = {
      'schema_version': 1,
      'modelo': 'recurso_solar_poa_horario_sem_obstaculos_v1',
      'sem_obstaculos': true, 'sem_perdas_eletricas': true,
      'fonte': 'fixture',
      'orientacao': {'inclinacao_graus': 0, 'azimute_graus': 0},
      'periodo': {'ano_utc': 2023, 'mes_utc': 1,
        'passo_minutos': 60, 'horas_retornadas': 1,
        'ano_completo_validado': true},
      'hsp_referencia_mensal_kwh_m2_dia': List.filled(12, 5.0),
      'amostras': [{
        'inicio_utc': '2023-01-01T00:00:00+00:00',
        'azimute_solar_graus': 90, 'elevacao_solar_aparente_graus': 45,
        'poa_total_w_m2': 900, 'poa_direta_w_m2': 700,
        'poa_difusa_ceu_w_m2': 200, 'poa_refletida_solo_w_m2': 0,
      }],
    };
    expect(() => HourlySolarResource.fromJson(json), throwsFormatException);
    expect(SolarResourceHour.fromJson(
      Map<String, dynamic>.from((json['amostras'] as List).first)).poaDirectWm2, 700);
  });
}
