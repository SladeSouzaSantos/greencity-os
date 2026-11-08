import 'dart:math' as math;

import 'solar_resource_hour.dart';

/// Coordinates: X=east, Y=elevation, Z=north. Metres; degrees geographic.
class Solar3dVector {
  final double x, y, z;
  const Solar3dVector(this.x, this.y, this.z);
  Solar3dVector operator +(Solar3dVector v) =>
      Solar3dVector(x + v.x, y + v.y, z + v.z);
  Solar3dVector operator -(Solar3dVector v) =>
      Solar3dVector(x - v.x, y - v.y, z - v.z);
  Solar3dVector scale(double k) => Solar3dVector(x*k, y*k, z*k);
  double dot(Solar3dVector v) => x*v.x + y*v.y + z*v.z;
  double get norm => math.sqrt(dot(this));
}

enum Solar3dObjectKind { panel, building, obstacle }

class Solar3dObject {
  final String id;
  final Solar3dObjectKind kind;
  final Solar3dVector center;
  final double width, depth, height, azimuthDegrees, tiltDegrees;

  /// Physical panel identity, not equipment model identity.
  final String? moduleModel;
  final String? stringId;
  final int? mpptIndex;

  const Solar3dObject({
    required this.id, required this.kind, required this.center,
    required this.width, required this.depth, required this.height,
    this.azimuthDegrees = 0, this.tiltDegrees = 0,
    this.moduleModel, this.stringId, this.mpptIndex,
  });

  Solar3dObject copyWith({
    Solar3dVector? center, String? stringId, bool clearString = false,
    int? mpptIndex,
    double? width, double? depth, double? height,
    double? azimuthDegrees, double? tiltDegrees,
  }) => Solar3dObject(
    id: id, kind: kind, center: center ?? this.center,
    width: width ?? this.width, depth: depth ?? this.depth,
    height: height ?? this.height,
    azimuthDegrees: azimuthDegrees ?? this.azimuthDegrees,
    tiltDegrees: tiltDegrees ?? this.tiltDegrees,
    moduleModel: moduleModel,
    stringId: clearString ? null : (stringId ?? this.stringId),
    mpptIndex: mpptIndex ?? this.mpptIndex,
  );

  void validate() {
    if (id.isEmpty || ![center.x, center.y, center.z, width, depth,
          height, azimuthDegrees, tiltDegrees].every((v) => v.isFinite) ||
        width <= 0 || depth <= 0 || height <= 0 ||
        width > 1000 || depth > 1000 || height > 1000 ||
        azimuthDegrees < 0 || azimuthDegrees >= 360 ||
        tiltDegrees < 0 || tiltDegrees > 90) {
      throw const FormatException('Objeto 3D com geometria inválida');
    }
    if (kind == Solar3dObjectKind.panel &&
        (mpptIndex == null || mpptIndex! < 1)) {
      throw const FormatException('Placa sem MPPT definido');
    }
  }

  Map<String, Object?> toSceneJson() => {
    'id': id,
    'name': id,
    'kind': kind.name,
    'position': {
      'east': center.x,
      'north': center.z,
      'elevation': center.y,
    },
    'width': width,
    'depth': depth,
    'height': height,
    'azimuth': azimuthDegrees,
    'tilt': tiltDegrees,
    if (kind == Solar3dObjectKind.panel) 'greencity': {
      'module_model': moduleModel,
      'string_id': stringId,
      'mppt_index': mpptIndex,
    },
  };
}

class Solar3dScene {
  final List<Solar3dObject> objects;
  const Solar3dScene(this.objects);

  void validate() {
    final ids = <String>{};
    if (!objects.any((o) => o.kind == Solar3dObjectKind.panel) ||
        objects.length > 100) {
      throw const FormatException('Cena precisa ter placas e até 100 objetos');
    }
    for (final obj in objects) {
      obj.validate();
      if (!ids.add(obj.id)) {
        throw const FormatException('IDs 3D duplicados');
      }
    }
  }
}

/// Pure Dart analogue of the direct-beam ray/opaque-box test in Solar3D.
/// It does NOT calculate diffuse sky shading, cell bypass or MPPT efficiency.
class Solar3dGeometricShading {
  static const double _eps = 1e-5;
  static double _rad(double angle) => angle * math.pi / 180;

  static List<Solar3dVector> _basis(Solar3dObject o) {
    final a = _rad(o.azimuthDegrees);
    final b = _rad(o.kind == Solar3dObjectKind.panel ? o.tiltDegrees : 0);
    final ca = math.cos(a), sa = math.sin(a);
    final cb = math.cos(b), sb = math.sin(b);
    return [
      Solar3dVector(ca, 0, -sa),
      Solar3dVector(sa * sb, cb, ca * sb),
      Solar3dVector(sa * cb, -sb, ca * cb),
    ];
  }

  static Solar3dVector _toWorld(
      Solar3dObject o, Solar3dVector local, List<Solar3dVector> basis) =>
      o.center + basis[0].scale(local.x) +
      basis[1].scale(local.y) + basis[2].scale(local.z);

  static Solar3dVector _toLocal(Solar3dVector v, List<Solar3dVector> basis) =>
      Solar3dVector(v.dot(basis[0]), v.dot(basis[1]), v.dot(basis[2]));

  static Solar3dVector _towardSun(double azimuth, double elevation) {
    final a = _rad(azimuth), h = _rad(elevation);
    return Solar3dVector(
      math.sin(a) * math.cos(h), math.sin(h), math.cos(a) * math.cos(h));
  }

  static bool _intersectsBox(Solar3dVector origin, Solar3dVector dir,
      Solar3dObject box, List<Solar3dVector> basis) {
    final localOrigin = _toLocal(origin - box.center, basis);
    final localDir = _toLocal(dir, basis);
    final pos = [localOrigin.x, localOrigin.y, localOrigin.z];
    final directions = [localDir.x, localDir.y, localDir.z];
    final bounds = [box.width/2, box.height/2, box.depth/2];
    var near = -double.infinity;
    var far = double.infinity;
    for (var i = 0; i < 3; i++) {
      final d = directions[i];
      if (d.abs() < 1e-12) {
        if (pos[i] < -bounds[i] || pos[i] > bounds[i]) return false;
        continue;
      }
      final p = (-bounds[i] - pos[i]) / d;
      final q = (bounds[i] - pos[i]) / d;
      near = math.max(near, math.min(p,q));
      far = math.min(far, math.max(p,q));
    }
    return far >= math.max(near, _eps);
  }

  /// A diagnostic sample grid on the FRONT face of the individual panel.
  /// The shade cast on the GROUND is not equivalent to shade on the module.
  /// A null result means the sun is behind the face or below the horizon,
  /// NOT a measured 0% direct-irradiance loss.
  static Solar3dPanelShadeInspection? inspectPanel({
    required Solar3dObject panel,
    required Solar3dScene scene,
    required double sunAzimuthDegrees,
    required double sunElevationDegrees,
    int rows = 12,
    int columns = 8,
  }) {
    if (panel.kind != Solar3dObjectKind.panel ||
        rows < 2 || rows > 24 || columns < 2 || columns > 24) {
      throw const FormatException('Amostragem do módulo inválida');
    }
    final sunlight = _towardSun(sunAzimuthDegrees, sunElevationDegrees);
    final basis = _basis(panel);
    if (sunlight.y <= 0 || sunlight.dot(basis[1]) <= 1e-12) return null;
    final obstacles = scene.objects.where((o) => o.id != panel.id).toList();
    final obstacleBasis = obstacles.map(_basis).toList();
    final blockers = <String, int>{};
    var blocked = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final point = _toWorld(panel, Solar3dVector(
          (col + 0.5) * panel.width / columns - panel.width / 2,
          panel.height/2 + _eps,
          (row + 0.5) * panel.depth / rows - panel.depth / 2,
        ), basis);
        for (var i = 0; i < obstacles.length; i++) {
          if (_intersectsBox(point, sunlight, obstacles[i], obstacleBasis[i])) {
            blocked++;
            final id = obstacles[i].id;
            blockers[id] = (blockers[id] ?? 0) + 1;
            break;
          }
        }
      }
    }
    return Solar3dPanelShadeInspection(
      blockedSamples: blocked,
      totalSamples: rows * columns,
      firstHitByObject: Map.unmodifiable(blockers),
    );
  }

  /// Raw FRONT-FACE ray samples, retaining the spatial mask for a
  /// separately documented physical substring/cell layout.
  ///
  /// This is an ADDITIONAL read-only experiment: inspectPanel(),
  /// blockedFraction() and calculate() keep their approved optical
  /// semantics unchanged. No 3-substring or half-cut layout is assumed.
  static Solar3dPanelShadowGrid? inspectPanelGrid({
    required Solar3dObject panel,
    required Solar3dScene scene,
    required double sunAzimuthDegrees,
    required double sunElevationDegrees,
    required int rows,
    required int columns,
  }) {
    if (panel.kind != Solar3dObjectKind.panel ||
        rows < 2 || rows > 24 || columns < 2 || columns > 24) {
      throw const FormatException('Grade espacial fora do limite');
    }
    final sunlight = _towardSun(sunAzimuthDegrees, sunElevationDegrees);
    final basis = _basis(panel);
    if (sunlight.y <= 0 || sunlight.dot(basis[1]) <= 1e-12) return null;
    final obstacles = scene.objects.where((o) => o.id != panel.id).toList();
    final obstacleBasis = obstacles.map(_basis).toList();
    final blocked = <bool>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final point = _toWorld(panel, Solar3dVector(
          (col + 0.5) * panel.width / columns - panel.width / 2,
          panel.height / 2 + _eps,
          (row + 0.5) * panel.depth / rows - panel.depth / 2,
        ), basis);
        var hit = false;
        for (var index = 0; index < obstacles.length; index++) {
          if (_intersectsBox(point, sunlight, obstacles[index],
              obstacleBasis[index])) {
            hit = true;
            break;
          }
        }
        blocked.add(hit);
      }
    }
    return Solar3dPanelShadowGrid(
      rows: rows, columns: columns,
      blocked: List.unmodifiable(blocked),
    );
  }

  /// Direct-beam front-face blocked AREA fraction; not DC/AC energy loss.
  static double? blockedFraction({
    required Solar3dObject panel,
    required Solar3dScene scene,
    required double sunAzimuthDegrees,
    required double sunElevationDegrees,
    int rows = 6,
    int columns = 4,
  }) => inspectPanel(
    panel: panel, scene: scene,
    sunAzimuthDegrees: sunAzimuthDegrees,
    sunElevationDegrees: sunElevationDegrees,
    rows: rows, columns: columns,
  )?.fraction;

  /// Hourly weighted irradiance only, not DC electrical yield. Complexity
  /// budget avoids blocking the UI thread for industrial-sized scenes.
  static List<PanelMonthlyIrradianceLoss> calculate({
    required Solar3dScene scene,
    required HourlySolarResource resource,
    Set<String>? targetPanelIds,
    int rows = 6, int columns = 4,
  }) {
    scene.validate();
    if (resource.monthUtc == null) {
      throw const FormatException('Solicite um mês UTC para calcular perdas mensais');
    }
    final panels = scene.objects.where((o) =>
      o.kind == Solar3dObjectKind.panel &&
      (targetPanelIds == null || targetPanelIds.contains(o.id))).toList();
    if (panels.isEmpty) {
      throw const FormatException('Não há placas selecionadas para a análise');
    }
    if (resource.samples.length * panels.length * rows * columns *
        math.max(1, scene.objects.length - 1) > 8000000) {
      throw const FormatException(
          'Cena excede limite síncrono; calcule por mês ou utilize worker');
    }
    final monthly = <PanelMonthlyIrradianceLoss>[];
    for (final panel in panels) {
      final azimuthDelta = (panel.azimuthDegrees -
          resource.azimuthDegrees).abs() % 360;
      if ((panel.tiltDegrees - resource.inclinationDegrees).abs() > 1e-6 ||
          math.min(azimuthDelta, 360 - azimuthDelta) > 1e-6) {
        throw const FormatException(
          'Cada orientação de placa precisa da sua própria série POA horária');
      }
      var referenceWhm2 = 0.0, shadedWhm2 = 0.0, beamLostWhm2 = 0.0;
      for (final hour in resource.samples) {
        final fraction = hour.poaDirectWm2 <= 0 ? null : blockedFraction(
          panel: panel, scene: scene,
          sunAzimuthDegrees: hour.solarAzimuthDegrees,
          sunElevationDegrees: hour.apparentSolarElevationDegrees,
          rows: rows, columns: columns,
        );
        final lost = hour.poaDirectWm2 * (fraction ?? 0.0);
        referenceWhm2 += hour.poaGlobalWm2;
        beamLostWhm2 += lost;
        shadedWhm2 += math.max(0, hour.poaGlobalWm2 - lost);
      }
      final days = resource.samples.length / 24.0;
      final referenceHsp = referenceWhm2 / (1000 * days);
      final correctedHsp = shadedWhm2 / (1000 * days);
      monthly.add(PanelMonthlyIrradianceLoss(
        panelId: panel.id,
        mpptIndex: panel.mpptIndex!,
        stringId: panel.stringId,
        monthUtc: resource.monthUtc,
        referenceHsp: referenceHsp,
        correctedHsp: correctedHsp,
        directLossKwhM2: beamLostWhm2 / 1000,
        shadeLossPercent: referenceWhm2 > 0 ? 100 * beamLostWhm2 / referenceWhm2 : null,
      ));
    }
    return monthly;
  }
}

/// Spatial sampling result, row-major, on the physical front face.
/// A grid cell is an optical sample, NOT a modeled silicon cell or substring.
class Solar3dPanelShadowGrid {
  final int rows, columns;
  final List<bool> blocked;
  const Solar3dPanelShadowGrid({
    required this.rows, required this.columns, required this.blocked,
  });

  double blockedFractionFor(Iterable<int> sampleIndices) {
    final indices = sampleIndices.toList();
    if (indices.isEmpty || blocked.length != rows * columns ||
        indices.toSet().length != indices.length ||
        indices.any((i) => i < 0 || i >= blocked.length)) {
      throw const FormatException('Mapa de amostragem inválido');
    }
    return indices.where((index) => blocked[index]).length /
        indices.length;
  }
}

/// Optical ray samples that intersect an opaque object before the sun.
/// A first-hit attribution is not a partition of electric or optical yield.
class Solar3dPanelShadeInspection {
  final int blockedSamples;
  final int totalSamples;
  final Map<String, int> firstHitByObject;

  const Solar3dPanelShadeInspection({
    required this.blockedSamples,
    required this.totalSamples,
    required this.firstHitByObject,
  });

  double get fraction => totalSamples == 0 ? 0 :
      blockedSamples / totalSamples;
}

class PanelMonthlyIrradianceLoss {
  final String panelId;
  final int mpptIndex;
  final String? stringId;
  final int? monthUtc;
  final double referenceHsp;
  final double correctedHsp;
  final double directLossKwhM2;
  final double? shadeLossPercent;

  const PanelMonthlyIrradianceLoss({
    required this.panelId, required this.mpptIndex, required this.stringId,
    required this.monthUtc, required this.referenceHsp,
    required this.correctedHsp, required this.directLossKwhM2,
    required this.shadeLossPercent,
  });
}
