import 'dart:async';
import 'dart:math' as math;


import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/datasources/solar_resource_hourly_data_source.dart';
import '../../../data/datasources/solar3d_scene_storage.dart';
import '../../../domain/entities/solar_project.dart';
import '../../../domain/entities/solar_system.dart';
import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import '../../../domain/solar3d/solar3d_plan_factory.dart';
import '../../../domain/solar3d/solar3d_panel_height.dart';
import '../../../domain/solar3d/solar3d_obstacle_height.dart';
import '../../../domain/solar3d/solar3d_study_string_suggestions.dart';
import '../../../domain/solar3d/solar3d_optical_correction.dart';
import '../../../domain/solar3d/solar3d_electrical_audit.dart';
import '../../../domain/solar3d/solar3d_scene_document.dart';
import '../../../domain/solar3d/solar3d_sun_position.dart';
import '../../widgets/photovoltaic/solar3d_scene_painter.dart';
import '../../widgets/photovoltaic/solar3d_touch_surface.dart';
import '../../widgets/photovoltaic/solar3d_camera_controls.dart';
import '../../widgets/photovoltaic/solar3d_obstacle_numeric_dialog.dart';
import '../../widgets/photovoltaic/solar3d_position_dialog.dart';
import '../../widgets/photovoltaic/solar3d_collapsible_section.dart';
import '../../widgets/photovoltaic/solar3d_object_picker.dart';

/// New opt-in scene editor. The legacy HSP calculation and SolarSystem remain
/// untouched. All MPPT/string edits here are PRELIMINARY scene metadata until
/// the electric circuit model and Isar project persistence are completed.
class Solar3dEditorPage extends StatefulWidget {
  final SolarProject project;
  final List<SolarSystem> systems;
  const Solar3dEditorPage({
    super.key, required this.project, required this.systems,
  });

  @override
  State<Solar3dEditorPage> createState() => _Solar3dEditorPageState();
}

class _Solar3dEditorPageState extends State<Solar3dEditorPage> {
  Solar3dSceneDocument? document;
  Solar3dSceneStorage? storage;
  Timer? _autosaveTimer;
  Future<void> _storageWriteQueue = Future<void>.value();
  bool _sceneEdited = false;

  /// Every geometry/MPPT change auto-persists locally, without storing the
  /// temporary optical monthly results or changing the production circuit.
  void _scheduleSceneAutosave(Solar3dSceneDocument snapshot) {
    if (storage == null) return;
    _sceneEdited = true;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 350), () {
      _autosaveTimer = null;
      unawaited(_queueSceneSave(snapshot));
    });
  }

  Future<void> _queueSceneSave(Solar3dSceneDocument snapshot) {
    final destination = storage;
    if (destination == null) return Future<void>.value();
    // Serialize writes: a slow disk operation cannot overwrite the next
    // document snapshot out of order.
    _storageWriteQueue = _storageWriteQueue.then((_) async {
      try {
        await destination.save(snapshot);
      } catch (error) {
        debugPrint('Solar3D autosave failed: $error');
      }
    });
    return _storageWriteQueue;
  }

  Future<void> _flushSceneAutosave(Solar3dSceneDocument snapshot) {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    return _queueSceneSave(snapshot);
  }

  Future<void> _clearSceneStorage() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _sceneEdited = false;
    final destination = storage!;
    _storageWriteQueue = _storageWriteQueue.then(
      (_) => destination.clear(),
    );
    return _storageWriteQueue;
  }

  // Freeze framing during edits, so dragging does not recenter the scene.
  Solar3dScene? cameraFrameScene;
  Solar3dScene? catalogInitialScene;
  String? draggingId;
  Solar3dVector? dragStartCenter;
  Solar3dVector? dragStartWorld;
  Solar3dProjection? dragProjection;
  // Viewport-only translation for two-finger panning. No scene geometry changes.
  Offset cameraPan = Offset.zero;
  Timer? sunPlayback;
  DateTime previewDay = DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int previewMinutes = 12 * 60;
  // Brazil defaults to UTC-3; this is an explicit PROJECT setting.
  // UTC offset is editable and never inferred silently from longitude.
  int projectUtcOffset = -3;
  String? initError;
  String? selectedId;
  double yaw = 0, pitch = 0.80, zoom = 1;
  // 0 = ask HSP for its latest COMPLETE UTC calendar year.
  // On the current NASA POWER production defaults, this is 2024;
  // the choice advances automatically when the server adds 2025.
  int yearSelection = 0;
  int? calculatedYearUtc;
  bool busy = false;
  String progress = '';
  Map<int, List<PanelMonthlyIrradianceLoss>> monthly = {};
  int sceneRevision = 0;
  // Cache expensive per-panel ray intersections across camera-only
  // interactions (orbit, pinch, zoom, pan). Invalidate on scene/solar
  // time/selection changes, not each finger movement.
  (int, String?, DateTime, int, int)? _previewShadeKey;
  Map<String, Solar3dPanelShadeInspection?> _previewShadeCache = {};
  Solar3dElectricalAudit? electricalAudit;
  String? lastCalculatedHourlyEndpoint;
  static const String hourlyUrl = String.fromEnvironment(
    'HSP_HOURLY_URL',
    defaultValue: SolarResourceHourlyDataSource.publicEndpoint,
  );
  static const String localHourlyUrl =
      'http://127.0.0.1:8000/recurso-solar/horario';
  late final TextEditingController hourlyEndpointController =
      TextEditingController(text: hourlyUrl);

  @override
  void initState() {
    super.initState();
    try {
      final scene = Solar3dPlanFactory.fromSystems(widget.systems);
      document = Solar3dSceneDocument(scene: scene);
      cameraFrameScene = scene;
      catalogInitialScene = scene;
      selectedId = scene.objects.firstWhere((o) =>
          o.kind == Solar3dObjectKind.panel).id;
      storage = Solar3dSceneStorage([
        widget.project.clientName, widget.project.city,
        widget.project.state,
        widget.project.latitude.toStringAsFixed(6),
        widget.project.longitude.toStringAsFixed(6),
        ...widget.systems.map((s) => s.id),
      ].join('|'));
      _loadSaved();
    } on FormatException catch (err) {
      initError = err.message;
    }
  }

  @override
  void dispose() {
    sunPlayback?.cancel();
    _autosaveTimer?.cancel();
    if (_sceneEdited && document != null) {
      // Leaving immediately after dragging still saves the last position.
      unawaited(_queueSceneSave(document!));
    }
    hourlyEndpointController.dispose();
    super.dispose();
  }

  DateTime get _previewInstantUtc {
    final local = DateTime.utc(previewDay.year, previewDay.month,
        previewDay.day, previewMinutes ~/ 60, previewMinutes % 60);
    return local.subtract(Duration(hours: projectUtcOffset));
  }

  Solar3dSunPosition get _sun => Solar3dSunPosition.calculate(
    utc: _previewInstantUtc,
    latitude: widget.project.latitude,
    longitude: widget.project.longitude,
  );

  String get _previewClock {
    final hour = (previewMinutes ~/ 60).toString().padLeft(2, '0');
    final minute = (previewMinutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _toggleSunPlayback() {
    if (sunPlayback != null) {
      sunPlayback?.cancel();
      setState(() => sunPlayback = null);
      return;
    }
    sunPlayback = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted) return;
      setState(() {
        previewMinutes += 15;
        if (previewMinutes >= 1440) {
          previewMinutes = 0;
          previewDay = previewDay.add(const Duration(days: 1));
        }
      });
    });
    setState(() {});
  }

  Future<void> _selectPreviewDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(previewDay.year, previewDay.month, previewDay.day),
      firstDate: DateTime(2001),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => previewDay =
          DateTime.utc(selected.year, selected.month, selected.day));
    }
  }

  Future<void> _loadSaved() async {
    try {
      final initialRevision = sceneRevision;
      final saved = await storage!.load();
      if (!mounted || saved == null || document == null ||
          sceneRevision != initialRevision) {
        return;
      }
      setState(() {
        document = saved.reconciledWith(document!.scene);
        cameraFrameScene = document!.scene;
        selectedId = document!.scene.objects.firstWhere(
          (o) => o.kind == Solar3dObjectKind.panel).id;
        monthly = {};
        calculatedYearUtc = null;
        electricalAudit = null;
        sceneRevision++;
        lastCalculatedHourlyEndpoint = null;
      });
    } catch (err) {
      if (mounted) {
        _notice('Não foi possível abrir a cena salva: $err');
      }
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  }

  Solar3dObject? get selected {
    final doc = document;
    if (doc == null || selectedId == null) return null;
    for (final item in doc.scene.objects) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  int _systemIndexFor(String panelId) =>
      widget.systems.indexWhere((s) => panelId.startsWith('${s.id}/'));

  String _trackerLabel(Solar3dObject panel) {
    final index = _systemIndexFor(panel.id);
    final sys = index < 0 ? null : widget.systems[index];
    return 'Inversor ${index + 1}'
        '${sys == null ? "" : " · ${sys.inverter.modelName}"}'
        ' / MPPT ${panel.mpptIndex ?? "?"}';
  }

  Future<void> _resetStudy() async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar projeto original?'),
        content: const Text(
          'Remover todos os objetos/obstáculos e posições salvos no '
          'laboratório 3D, restaurar os MPPTs de cada arranjo original '
          'e descartar os 12 meses de resultados ópticos? '
          'A estimativa de geração voltará ao HSP original. '
          'O cadastro de inversores e módulos não será apagado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar original')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await _clearSceneStorage();
      if (!mounted) return;
      final base = catalogInitialScene ??
          Solar3dPlanFactory.fromSystems(widget.systems);
      sunPlayback?.cancel();
      sunPlayback = null;
      _onScaleEnd();
      widget.project.opticalCorrection = null;
      setState(() {
        document = Solar3dSceneDocument(scene: base);
        cameraFrameScene = base;
        selectedId = base.objects.firstWhere(
          (o) => o.kind == Solar3dObjectKind.panel).id;
        monthly = {};
        calculatedYearUtc = null;
        electricalAudit = null;
        lastCalculatedHourlyEndpoint = null;
        sceneRevision++;
      });
      _notice('Cena e análise 3D restauradas. '
          'A geração voltou ao projeto original.');
    } catch (err) {
      _notice('Falha ao restaurar cena: $err');
    }
  }

  void _setPanelMppt(Solar3dObject panel, int mppt) {
    final system = _systemFor(panel.id);
    if (system == null || mppt < 1 ||
        mppt > system.inverter.mpptCount) {
      _notice('Esse MPPT não pertence ao inversor desta placa.');
      return;
    }
    _replace(panel.copyWith(mpptIndex: mppt));
  }

  SolarSystem? _systemFor(String panelId) {
    for (final system in widget.systems) {
      if (panelId.startsWith('${system.id}/')) return system;
    }
    return null;
  }

  void _changeDocument(Solar3dSceneDocument next) {
    next.scene.validate();
    setState(() {
      document = next;
      monthly = {};
      calculatedYearUtc = null;
      electricalAudit = null;
      lastCalculatedHourlyEndpoint = null;
      sceneRevision++;
    });
    _scheduleSceneAutosave(next);
  }

  void _replace(Solar3dObject next) {
    final doc = document!;
    final changed = doc.scene.objects.map((o) =>
        o.id == next.id ? next : o).toList();
    _changeDocument(Solar3dSceneDocument(
      scene: Solar3dScene(changed),
      hiddenIds: doc.hiddenIds, excludedIds: doc.excludedIds,
    ));
  }

  double? _registeredLowerEdgeHeight(String objectId) {
    final base = catalogInitialScene;
    if (base == null) return null;
    for (final object in base.objects) {
      if (object.id == objectId &&
          object.kind == Solar3dObjectKind.panel) {
        return Solar3dPanelHeight.lowerEdgeOf(object);
      }
    }
    return null;
  }

  Map<String, double> _legacyHeightCandidates(Solar3dScene scene) {
    final base = catalogInitialScene;
    if (base == null) return {};
    final registered = {
      for (final o in base.objects.where(
          (o) => o.kind == Solar3dObjectKind.panel))
        o.id: o,
    };
    final candidates = <String, double>{};
    for (final panel in scene.objects.where(
        (o) => o.kind == Solar3dObjectKind.panel)) {
      final original = registered[panel.id];
      // Only scenes built with the OLD centre-height convention whose
      // baseline edge is actually below ground qualify for opt-in repair.
      if (original == null ||
          Solar3dPanelHeight.lowerEdgeOf(original) >= -1e-4 ||
          !_panelCrossesTerrain(panel) ||
          !original.center.y.isFinite ||
          original.center.y < 0 || original.center.y > 500) {
        continue;
      }
      candidates[panel.id] = original.center.y;
    }
    return candidates;
  }

  Future<void> _repairLegacyHeights() async {
    if (busy || document == null) return;
    final doc = document!;
    final revision = sceneRevision;
    final candidates = _legacyHeightCandidates(doc.scene);
    if (candidates.isEmpty) {
      _notice('Não há alturas legadas incompatíveis para corrigir.');
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adaptar alturas antigas?'),
        content: Text(
          'O cadastro antigo considerava a altura do CENTRO, '
          'o que colocou ${candidates.length} placa(s) parcialmente '
          'abaixo do solo no estudo 3D.\n\n'
          'Com sua confirmação, o mesmo número em metros '
          'será interpretado como a altura da BORDA INFERIOR '
          'para essas placas. As posições X/Z, MPPTs, strings '
          'e demais objetos serão preservados. '
          'O cálculo óptico mensal anterior será invalidado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Corrigir alturas')),
        ],
      ),
    );
    if (!mounted || accepted != true || revision != sceneRevision) return;
    final adjusted = Solar3dScene([
      for (final o in doc.scene.objects)
        if (candidates.containsKey(o.id))
          Solar3dPanelHeight.withLowerEdge(o, candidates[o.id]!)
        else
          o,
    ]);
    _changeDocument(Solar3dSceneDocument(
      scene: adjusted,
      hiddenIds: doc.hiddenIds,
      excludedIds: doc.excludedIds,
    ));
    _notice('Alturas legadas adaptadas. Salve a cena e '
        'recalcule os 12 meses para atualizar a geração.');
  }

  void _restoreRegisteredHeight() {
    final panel = selected;
    if (panel == null || panel.kind != Solar3dObjectKind.panel) return;
    final clearance = _registeredLowerEdgeHeight(panel.id);
    if (clearance == null) return;
    _replace(Solar3dPanelHeight.withLowerEdge(panel,
      math.max(0, clearance)));
  }

  void _toggle({required bool visibility}) {
    final doc = document!;
    final id = selectedId;
    if (id == null) return;
    final ids = {...(visibility ? doc.hiddenIds : doc.excludedIds)};
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    _changeDocument(Solar3dSceneDocument(
      scene: doc.scene,
      hiddenIds: visibility ? ids : doc.hiddenIds,
      excludedIds: visibility ? doc.excludedIds : ids,
    ));
  }

  Future<void> _addObstacle() async {
    final doc = document!;
    if (doc.scene.objects.length >= 100) {
      _notice('Limite de 100 objetos no cenário inicial');
      return;
    }
    final draft = Solar3dObject(
      id: 'obstacle-${DateTime.now().microsecondsSinceEpoch}',
      kind: Solar3dObjectKind.obstacle,
      center: const Solar3dVector(0, 1.5, 0),
      width: 2, depth: 2, height: 3,
    );
    final configured = await showDialog<Solar3dObject>(
      context: context,
      builder: (_) => Solar3dObstacleNumericDialog(
        obstacle: Solar3dObstacleHeight.withBase(draft, 0),
        creating: true,
      ),
    );
    if (!mounted || configured == null) return;
    final latest = document!;
    if (latest.scene.objects.length >= 100) {
      _notice('Limite de 100 objetos no cenário inicial');
      return;
    }
    try {
      _changeDocument(Solar3dSceneDocument(
        scene: Solar3dScene([...latest.scene.objects, configured]),
        hiddenIds: latest.hiddenIds, excludedIds: latest.excludedIds,
      ));
      setState(() => selectedId = configured.id);
    } on FormatException catch (error) {
      _notice(error.message);
    }
  }

  Future<void> _editObstacleNumerically() async {
    final current = selected;
    if (current == null ||
        current.kind == Solar3dObjectKind.panel) {
      return;
    }
    final edited = await showDialog<Solar3dObject>(
      context: context,
      builder: (_) => Solar3dObstacleNumericDialog(obstacle: current),
    );
    if (!mounted || edited == null) return;
    try {
      _replace(edited);
    } on FormatException catch (error) {
      _notice(error.message);
    }
  }

  void _deleteObstacle() {
    final current = selected;
    if (current == null || current.kind == Solar3dObjectKind.panel) return;
    final doc = document!;
    _changeDocument(Solar3dSceneDocument(
      scene: Solar3dScene(doc.scene.objects.where((o) =>
          o.id != current.id).toList()),
      hiddenIds: {...doc.hiddenIds}..remove(current.id),
      excludedIds: {...doc.excludedIds}..remove(current.id),
    ));
    setState(() => selectedId = doc.scene.objects.firstWhere(
      (o) => o.kind == Solar3dObjectKind.panel).id);
  }

  Future<void> _setString() async {
    final current = selected;
    if (current == null || current.kind != Solar3dObjectKind.panel) return;
    var value = current.stringId ?? '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('String da placa — estudo'),
        content: TextFormField(
          initialValue: value,
          maxLength: 40,
          onChanged: (text) => value = text,
          decoration: const InputDecoration(
            labelText: 'ID da string (ex.: S1)',
            helperText: 'Não altera ainda o dimensionamento do inversor.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(
            dialogContext, value.trim()), child: const Text('Aplicar')),
        ],
      ),
    );
    if (!mounted || submitted == null) return;
    _replace(current.copyWith(
      stringId: submitted.isEmpty ? null : submitted,
      clearString: submitted.isEmpty,
    ));
  }

  Solar3dScene get analysisScene {
    final doc = document!;
    return Solar3dScene(doc.scene.objects.where((o) =>
        !doc.excludedIds.contains(o.id)).toList());
  }

  /// Detailed ray sampling distinguishes:
  /// - a shadow cast on the GROUND,
  /// - a ray actually intercepted on each MODULE FRONT FACE,
  /// - no direct incidence on the front face (null, not 0% loss).
  Map<String, Solar3dPanelShadeInspection?> _previewShadows(
      Solar3dSunPosition sun) {
    final key = (
      sceneRevision, selectedId, previewDay,
      previewMinutes, projectUtcOffset,
    );
    if (_previewShadeKey == key || (draggingId != null &&
        _previewShadeKey != null)) {
      return _previewShadeCache;
    }
    final scene = analysisScene;
    final result = <String, Solar3dPanelShadeInspection?>{};
    if (!sun.aboveHorizon) {
      _previewShadeKey = key;
      _previewShadeCache = result;
      return result;
    }
    final panels = scene.objects.where(
      (o) => o.kind == Solar3dObjectKind.panel,
    ).toList();
    // Cap synchronous work: selected module sampled at 12x8, others at
    // 8x6. Detailed MONTHLY simulation still uses separate hourly POA.
    final first = selected;
    final candidates = <Solar3dObject>[
      if (first != null && first.kind == Solar3dObjectKind.panel &&
          panels.any((o) => o.id == first.id)) first,
      ...panels.where((o) => o.id != first?.id).take(24),
    ];
    for (final panel in candidates) {
      result[panel.id] = Solar3dGeometricShading.inspectPanel(
        panel: panel,
        scene: scene,
        sunAzimuthDegrees: sun.azimuthDegrees,
        sunElevationDegrees: sun.elevationDegrees,
        rows: first?.id == panel.id ? 12 : 8,
        columns: first?.id == panel.id ? 8 : 6,
      );
    }
    _previewShadeKey = key;
    _previewShadeCache = result;
    return result;
  }

  static String _shortPanelId(String id) {
    final parts = id.split('/');
    return parts.length >= 2
        ? parts.sublist(parts.length - 2).join('/')
        : id;
  }

  static double _panelLowestPoint(Solar3dObject panel) =>
      Solar3dPanelHeight.lowerEdgeOf(panel);

  bool _panelCrossesTerrain(Solar3dObject panel) =>
      panel.kind == Solar3dObjectKind.panel &&
      _panelLowestPoint(panel) < -0.0001;

  Future<void> _calculate() async {
    final doc = document;
    if (doc == null || busy) return;
    final endpoint = hourlyEndpointController.text.trim();
    final revision = sceneRevision;
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty || uri.userInfo.isNotEmpty ||
        !uri.path.endsWith('/recurso-solar/horario')) {
      _notice('Informe a URL completa da rota /recurso-solar/horario '
          'em HTTP(S), sem credenciais.');
      return;
    }
    final scene = analysisScene;
    final panels = scene.objects.where((o) =>
        o.kind == Solar3dObjectKind.panel).toList();
    if (panels.isEmpty) {
      _notice('Nenhuma placa incluída na análise');
      return;
    }
    if (panels.length > 30) {
      _notice('Análise de pesquisa limitada a 30 placas; reduza a seleção.');
      return;
    }
    if (panels.any(_panelCrossesTerrain)) {
      _notice('Uma ou mais placas atravessam o terreno. Ajuste a altura '
          'da borda inferior antes de calcular perdas mensais.');
      return;
    }
    final groups = <String, List<Solar3dObject>>{};
    for (final panel in panels) {
      final key = '${panel.tiltDegrees.toStringAsFixed(4)}|${panel.azimuthDegrees.toStringAsFixed(4)}';
      groups.putIfAbsent(key, () => []).add(panel);
    }
    if (groups.length > 8) {
      _notice('Máximo de 8 orientações distintas por análise de pesquisa.');
      return;
    }
    setState(() {
      busy = true;
      progress = 'Preparando séries';
      monthly = {};
        calculatedYearUtc = null;
      lastCalculatedHourlyEndpoint = null;
    });
    final client = SolarResourceHourlyDataSource(
        dio: Dio(), endpoint: endpoint);
    final output = <int, List<PanelMonthlyIrradianceLoss>>{};
    int? sourceYearUtc;
    try {
      for (var m = 1; m <= 12; m++) {
        if (!mounted) return;
        if (revision != sceneRevision) {
          throw StateError(
            'A cena mudou durante o cálculo. Calcule novamente.');
        }
        setState(() => progress = 'Calculando mês $m/12');
        final values = <PanelMonthlyIrradianceLoss>[];
        for (final group in groups.values) {
          final sample = group.first;
          final resource = await client.getHourlyResource(
            latitude: widget.project.latitude,
            longitude: widget.project.longitude,
            inclination: sample.tiltDegrees,
            azimuth: sample.azimuthDegrees,
            yearUtc: yearSelection == 0 ? null : yearSelection,
            monthUtc: m,
            source: 'NASA POWER',
          );
          // Every month and every orientation must use the SAME
          // meteorological year; otherwise annual losses cannot
          // legitimately be applied to the generation estimate.
          if (sourceYearUtc != null && sourceYearUtc != resource.yearUtc) {
            throw StateError('A fonte mudou de ano durante o cálculo. '
                'Reinicie a análise de 12 meses.');
          }
          sourceYearUtc = resource.yearUtc;
          values.addAll(Solar3dGeometricShading.calculate(
            scene: scene, resource: resource,
            targetPanelIds: group.map((p) => p.id).toSet(),
          ));
          // Defer expensive geometry updates so the progress view can paint.
          await Future<void>.delayed(Duration.zero);
        }
        output[m] = values;
      }
      if (mounted) {
        if (revision != sceneRevision) {
          throw StateError(
            'A cena mudou durante o cálculo. Calcule novamente.');
        }
        setState(() {
          monthly = output;
          calculatedYearUtc = sourceYearUtc;
          lastCalculatedHourlyEndpoint = endpoint;
        });
      }
    } catch (err) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Não foi possível consultar o recurso solar'),
          content: SingleChildScrollView(child: Text(
            '$err\n\n'
            'Endpoint: $endpoint\n\n'
            'Verifique se a URL horária escolhida está disponível, '
            'e se o dispositivo tem acesso à rede. '
            'O endpoint público depende de deploy e pode retornar 404 '
            'até a versão de HSP com esta rota estar no servidor. '
            'Para rodar localmente no Windows, use o HSP Simulator '
            'na branch dev: python -m uvicorn api:app --host '
            '127.0.0.1 --port 8000.\n\n'
            'No Android, 127.0.0.1 aponta para o PRÓPRIO aparelho. '
            'Use o endpoint público HTTPS após publicação, ou uma '
            'URL de desenvolvimento acessível pela rede do dispositivo. '
            'A visualização 3D funciona sem API.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            FilledButton(
              onPressed: () {
                hourlyEndpointController.text = localHourlyUrl;
                Navigator.pop(context);
              },
              child: const Text('Usar API local Windows'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() { busy = false; progress = ''; });
    }
  }

  Solar3dProjection _projection(Size size) {
    final scene = document!.scene;
    return Solar3dProjection(
      size: size, scene: scene, frameScene: cameraFrameScene,
      yaw: yaw, pitch: pitch, zoom: zoom, cameraPan: cameraPan,
    );
  }

  /// Use the silhouette actually rendered on screen (including obstacle
  /// side faces) and a controlled mobile tap tolerance.
  Solar3dObject? _hitObject(Offset at, Solar3dProjection view) =>
      Solar3dObjectPicker.pick(
        at: at, view: view, scene: document!.scene,
        hiddenIds: document!.hiddenIds,
      );

  /// Explicitly hand the optical scenario back to the generation screen.
  /// It changes only the monthly energy-estimate overlay in this session.
  /// The actual electrical topology, production and quote are not silently
  /// rewritten; no string mismatch/bypass yield is asserted.
  Future<void> _suggestStudyStrings() async {
    final doc = document;
    if (doc == null || busy) return;
    final missing = Solar3dStudyStringSuggestions.missingCount(doc.scene);
    if (missing == 0) {
      _notice('Todas as placas já têm uma string informada.');
      return;
    }
    final revision = sceneRevision;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sugerir strings apenas para estudo?'),
        content: Text(
          'As $missing placa(s) ainda sem string receberão um '
          'identificador experimental. Placas do mesmo arranjo '
          'original E do mesmo MPPT 3D serão agrupadas em uma '
          'string hipotética em série.\n\n'
          'Isso NÃO confirma a quantidade real de strings, '
          'as conexões físicas ou a viabilidade do inversor. '
          'Revise os resultados da auditoria e valide com '
          'o projeto elétrico antes de executar a instalação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Gerar strings de estudo'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true || revision != sceneRevision) return;
    try {
      final updated = Solar3dStudyStringSuggestions.fillMissing(doc.scene);
      _changeDocument(Solar3dSceneDocument(
        scene: updated,
        hiddenIds: doc.hiddenIds,
        excludedIds: doc.excludedIds,
      ));
      _auditElectrical();
    } on FormatException catch (error) {
      _notice(error.message);
    }
  }

  void _auditElectrical() {
    final doc = document;
    if (doc == null) return;
    final climate = widget.project.climate;
    final temps = climate?.tempMinMonthly.where((v) =>
        v.isFinite && v >= -60 && v <= 80).toList() ?? [];
    try {
      final report = Solar3dElectricalAudit.inspect(
        systems: widget.systems,
        scene: doc.scene,
        minimumAmbientC: temps.isEmpty ? null :
            temps.reduce(math.min),
      );
      setState(() => electricalAudit = report);
    } on FormatException catch (error) {
      _notice(error.message);
    }
  }

  Widget _electricalAuditPanel() {
    final report = electricalAudit;
    return Card(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Auditoria preliminar de strings e MPPT',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 7),
          const Text(
            'DC: a corrente de uma string em série é limitada pela '
            'placa mais fraca; em paralelo, as correntes se somam no '
            'MPPT. Imp acima do máximo operacional pode indicar '
            'limitação de corrente (aviso); Isc acima do limite '
            'de curto-circuito impede a aplicação (bloqueio). '
            'A análise é STC e requer confirmação do fabricante.'),
          const Text(
            'AC: o cálculo convencional já inclui eficiência nominal '
            'do inversor. Ainda não calcula clipping horário, '
            'curva de eficiência, mismatch elétrico nem bypass '
            'sob sombreamento. Não duplicamos essas perdas.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : _auditElectrical,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('VALIDAR STRINGS E LIMITES DO INVERSOR'),
          ),
          if (document != null &&
              Solar3dStudyStringSuggestions.missingCount(
                  document!.scene) > 0) ...[
            const Text(
              'As mensagens UNASSIGNED_STRING são avisos de '
              'configuração incompleta, não erros de cálculo.',
              style: TextStyle(fontSize: 12),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : _suggestStudyStrings,
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: const Text('SUGERIR STRINGS PARA ESTUDO'),
            ),
          ],
          if (report != null) ...[
            Text(
              'Placas com string: ${report.assignedPanels}/'
              '${report.totalPanels} · '
              '${report.findings.where((f) =>
                f.severity == Solar3dElectricalSeverity.blocking).length}'
              ' bloqueio(s) · '
              '${report.findings.where((f) =>
                f.severity == Solar3dElectricalSeverity.warning).length}'
              ' aviso(s).',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!report.topologyComplete)
              const Text('Identifique as strings em cada placa '
                  'ou use a sugestão experimental acima; '
                  'isso não representa a ligação elétrica real.'),
            for (final tracker in report.trackers)
              ExpansionTile(
                title: Text(
                  'Inversor ${widget.systems.indexWhere((s) =>
                      s.id == tracker.inverterId) + 1} · '
                  'MPPT ${tracker.mpptIndex} · '
                  '${tracker.strings.length} string(s)'),
                subtitle: Text(
                  'DC STC: ${tracker.totalPowerWp.toStringAsFixed(0)} Wp '
                  '· Imp STC ${tracker.parallelImpStcA.toStringAsFixed(1)} A '
                  '/ máx. operacional '
                  '${tracker.operatingCurrentLimitA.toStringAsFixed(1)} A'
                  ' · Isc STC ${tracker.parallelIscStcA.toStringAsFixed(1)} A '
                  '/ máx. curto-circuito '
                  '${tracker.shortCircuitCurrentLimitA.toStringAsFixed(1)} A'),
                children: [
                  for (final string in tracker.strings)
                    ListTile(
                      dense: true,
                      title: Text(
                        '${string.stringId} · '
                        '${string.moduleCount} módulo(s) em série'),
                      subtitle: Text(
                        'Vmp STC ${string.vmpStcV.toStringAsFixed(1)} V · '
                        'Voc STC ${string.vocStcV.toStringAsFixed(1)} V'
                        ' · Imp STC ${string.impStcA.toStringAsFixed(1)} A'
                        '${string.estimatedVocColdV == null ? "" :
                          " · Voc frio estimado "
                          "${string.estimatedVocColdV!.toStringAsFixed(1)} V"}'),
                    ),
                ],
              ),
            if (report.findings.isNotEmpty)
              ExpansionTile(
                initiallyExpanded: report.hasBlockers,
                title: const Text('Inconsistências e limitações técnicas'),
                children: [
                  for (final finding in report.findings)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        finding.severity ==
                                Solar3dElectricalSeverity.blocking
                          ? Icons.error_outline
                          : finding.severity ==
                                Solar3dElectricalSeverity.warning
                            ? Icons.warning_amber_outlined
                            : Icons.info_outline,
                        color: finding.severity ==
                                Solar3dElectricalSeverity.blocking
                            ? Colors.redAccent : null,
                      ),
                      title: Text(finding.message),
                      subtitle: Text(
                        '${finding.scope} · ${finding.code}'),
                    ),
                ],
              ),
          ],
          const Text(
            'Essa checagem é preliminar. Não há topologia celular '
            'nem curvas I-V/bypass calibradas para declarar perdas '
            'DC ou geração AC certificadas.'),
        ],
      ),
    ));
  }

  Future<void> _applyOpticalToProject() async {
    if (busy) return;
    if (calculatedYearUtc == null || monthly.length != 12) {
      _notice('Calcule os 12 meses completos antes de aplicar.');
      return;
    }
    if (lastCalculatedHourlyEndpoint == null ||
        lastCalculatedHourlyEndpoint !=
            hourlyEndpointController.text.trim()) {
      _notice('Recalcule os 12 meses após alterar o endpoint HSP.');
      return;
    }
    try {
      final doc = document!;
      final correction = Solar3dOpticalCorrection.fromAnalysis(
        systems: widget.systems,
        scene: doc.scene,
        monthly: monthly,
        yearUtc: calculatedYearUtc!,
        excludedPanelIds: doc.excludedIds,
      );
      // Electrical blockers do NOT change ray-cast POA.
      // The user may still compare an optical scenario but must be warned
      // that it is not a physically operable PV electrical design.
      final temps = widget.project.climate?.tempMinMonthly.where((v) =>
          v.isFinite && v >= -60 && v <= 80).toList() ?? [];
      final audit = Solar3dElectricalAudit.inspect(
        systems: widget.systems, scene: doc.scene,
        minimumAmbientC: temps.isEmpty ? null : temps.reduce(math.min));
      if (audit.topologyComplete && audit.hasBlockers) {
        // A fully specified but physically incompatible design must
        // never be promoted to the project generation estimate.
        // Its optical raycast remains available for diagnostics only.
        setState(() => electricalAudit = audit);
        final blocking = audit.findings.where((f) =>
            f.severity == Solar3dElectricalSeverity.blocking).toList();
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Circuito elétrico incompatível'),
            content: SingleChildScrollView(child: Text(
              'Não é possível aplicar à geração projetada uma '
              'topologia completa que viola limites do inversor.\n\n'
              '${blocking.take(6).map((f) =>
                "${f.scope}: ${f.message}").join("\n")}\n\n'
              'Corrija a quantidade de módulos em série/MPPT, '
              'as correntes e as strings. A análise de HSP óptico '
              'permanece disponível para estudo.',
            )),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Revisar strings e MPPTs'),
              ),
            ],
          ),
        );
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aplicar cenário óptico à geração?'),
          content: Text(
            'Serão considerados ${correction.panelCount} módulos e '
            'os 12 meses de ${correction.weatherYearUtc}. '
            'O GreenCity OS recalculará cada inversor '
            'independentemente. As placas serão agrupadas pelos MPPTs '
            'escolhidos no 3D (inclusive se forem diferentes dos '
            'grupos originais), respeitando o número real de MPPTs '
            'do inversor. O cenário aplica uma correção óptica única '
            'por MPPT sobre a base HSP dos módulos.\n\n'
            '${audit.findings.any((f) =>
                  f.code == "MPPT_CURRENT_LIMIT")
                ? "AVISO: Imp excede o máximo operacional em um ou mais "
                  "MPPTs. O clipping de corrente não foi estimado. "
                  "Confirme a compatibilidade com o fabricante.\n\n"
                : ""}'
            'As conexões físicas originais NÃO serão alteradas. '
            'A geração estimada pode mudar pela nova distribuição '
            'hipotética dos MPPTs além da sombra. '
            'A cena de estudo é salva automaticamente neste aparelho.\n\n'
            'ATENÇÃO: É uma estimativa experimental de irradiância; '
            'não modela eletricamente strings, bypass nem mismatch '
            'sob sombras parciais. Não representa geração AC '
            'validada e ainda não é salva como projeto homologado. '
            'Os obstáculos da API HSP convencional precisam estar '
            'desativados para evitar dupla contagem.\n\n'
            'Auditoria elétrica preliminar: '
            '${audit.topologyComplete ? "strings atribuídas" :
                "strings incompletas"}; '
            '${audit.findings.where((f) =>
                  f.severity ==
                    Solar3dElectricalSeverity.blocking).length} '
            'bloqueio(s) de viabilidade. A aplicação permanece '
            'SOMENTE óptica e não autoriza executar esse circuito.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Aplicar estimativa óptica'),
            ),
          ],
        ),
      );
      if (!mounted || confirm != true) return;
      // Applying the scenario also persists its geometry and per-panel
      // assignment locally; otherwise reopening the editor would restore
      // the previous layout even while the session uses the new ratios.
      await _flushSceneAutosave(doc);
      if (!mounted) return;
      Navigator.pop(context, correction);
    } on FormatException catch (error) {
      _notice(error.message);
    } on StateError catch (error) {
      _notice(error.message);
    } catch (error) {
      _notice('Não foi possível salvar o cenário 3D: $error');
    }
  }

  /// Canvas gesture owns the placement of objects exclusively.
  /// Blank canvas does not rotate/pan the camera.
  void _touchStart(Offset local, Size size) {
    _onPanEnd();
    final view = _projection(size);
    final item = _hitObject(local, view);
    if (item == null) return;
    draggingId = item.id;
    dragStartCenter = item.center;
    dragProjection = view;
    dragStartWorld = view.pointOnHorizontalPlane(local, item.center.y);
    if (selectedId != item.id) setState(() => selectedId = item.id);
  }

  static double _wrapYaw(double v) =>
      (v + math.pi) % (2 * math.pi) - math.pi;

  void _touchMove(Offset local) {
    if (draggingId != null) _dragTo(local);
  }

  void _setCameraHeading(double targetYaw) {
    _onScaleEnd();
    setState(() => yaw = _wrapYaw(targetYaw));
  }

  void _changeCameraPitch(double delta) {
    _onScaleEnd();
    setState(() {
      pitch = (pitch + delta).clamp(.25, math.pi / 2).toDouble();
    });
  }

  void _changeCameraYaw(double delta) {
    _onScaleEnd();
    setState(() => yaw = _wrapYaw(yaw + delta));
  }

  void _panCamera(Offset delta) {
    _onScaleEnd();
    setState(() => cameraPan += delta);
  }

  void _resetCameraPan() {
    _onScaleEnd();
    setState(() => cameraPan = Offset.zero);
  }

  void _zoomCamera(bool zoomIn) {
    _onScaleEnd();
    setState(() {
      zoom = (zoom * (zoomIn ? 1.25 : .8)).clamp(.45, 4.0).toDouble();
    });
  }

  void _restorePerspective() {
    _onScaleEnd();
    setState(() {
      yaw = .6;
      pitch = .80;
      cameraPan = Offset.zero;
    });
  }

  void _onScaleEnd() {
    final hadDragging = draggingId != null;
    _onPanEnd();
    // Ray samples are deferred during a drag to keep the phone responsive.
    if (hadDragging && mounted) {
      setState(() => _previewShadeKey = null);
    }
  }

  void _dragTo(Offset localPosition) {
    final id = draggingId;
    final start = dragStartCenter;
    final anchor = dragStartWorld;
    final projection = dragProjection;
    if (id == null || start == null || anchor == null || projection == null) {
      return;
    }
    final current = selected;
    if (current == null || current.id != id) {
      return;
    }
    final world = projection.pointOnHorizontalPlane(
      localPosition, start.y);
    final east = start.x + world.x - anchor.x;
    final north = start.z + world.z - anchor.z;
    if (!east.isFinite || !north.isFinite ||
        east.abs() > 500 || north.abs() > 500) {
      return;
    }
    if ((east - current.center.x).abs() < .0001 &&
        (north - current.center.z).abs() < .0001) {
      return;
    }
    _replace(current.copyWith(center: Solar3dVector(east, start.y, north)));
  }

  void _onPanEnd() {
    draggingId = null;
    dragStartCenter = null;
    dragStartWorld = null;
    dragProjection = null;
  }

  Future<void> _editPosition() async {
    final current = selected;
    if (current == null) return;
    final updated = await showDialog<Solar3dObject>(
      context: context,
      builder: (_) => Solar3dPositionDialog(object: current),
    );
    if (!mounted || updated == null) return;
    try {
      _replace(updated);
    } on FormatException catch (error) {
      _notice(error.message);
    }
  }

  void _topView() {
    _onScaleEnd();
    setState(() {
      yaw = 0;
      pitch = math.pi / 2;
      cameraPan = Offset.zero;
    });
  }

  Widget _monthlyTable() {
    if (monthly.isEmpty) return const SizedBox.shrink();
    final current = selected;
    if (current == null || current.kind != Solar3dObjectKind.panel) {
      return const Text('Selecione uma placa para os resultados individuais.');
    }
    final values = monthly.entries.toList()..sort((a,b) => a.key.compareTo(b.key));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('HSP corrigido e perdas ópticas: ${current.id}',
          style: Theme.of(context).textTheme.titleMedium),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: DataTable(columns: const [
          DataColumn(label: Text('Mês')),
          DataColumn(label: Text('HSP base')),
          DataColumn(label: Text('HSP sombra')),
          DataColumn(label: Text('Perda óptica')),
        ], rows: [
          for (final entry in values)
            for (final v in entry.value.where((r) => r.panelId == current.id))
              DataRow(cells: [
                DataCell(Text('${entry.key}')),
                DataCell(Text(v.referenceHsp.toStringAsFixed(3))),
                DataCell(Text(v.correctedHsp.toStringAsFixed(3))),
                DataCell(Text(v.shadeLossPercent == null ? '—' :
                    '${v.shadeLossPercent!.toStringAsFixed(2)}%')),
              ]),
        ]),
      ),
      const Text('Por MPPT: as placas estão identificadas, mas a perda de '
          'energia DC/AC depende do circuito das strings, ainda não validado.'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (initError != null || document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Análise 3D')),
        body: Center(child: Text(initError ?? 'Nenhum arranjo disponível')),
      );
    }
    final doc = document!;
    final current = selected;
    final mpptSystem = current == null ? null : _systemFor(current.id);
    final sun = _sun;
    final inspections = _previewShadows(sun);
    final previewShades = <String, double?>{
      for (final entry in inspections.entries)
        entry.key: entry.value?.fraction,
    };
    final terrainCrossingPanels = doc.scene.objects.where(
      _panelCrossesTerrain,
    ).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Análise 3D · GreenCity OS'),
        actions: [

        ]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Card(child: Padding(padding: EdgeInsets.all(12), child: Text(
          'Laboratório de sombreamento: cena editável e perdas de '
          'IRRADIÂNCIA por placa. Alterações de geometria e MPPT '
          'são salvas automaticamente neste aparelho. '
          'As posições iniciais são ilustrativas; '
          'a API HSP e o circuito original continuam intactos.'
        ))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COORDENADAS USADAS NO SOMBREAMENTO',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, runSpacing: 2, children: [
                Chip(
                  avatar: const Icon(Icons.location_on_outlined, size: 17),
                  label: Text('Latitude: '
                      '${widget.project.latitude.toStringAsFixed(6)}°'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.explore_outlined, size: 17),
                  label: Text('Longitude: '
                      '${widget.project.longitude.toStringAsFixed(6)}°'),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              const Text('Valores do projeto utilizados na posição do Sol '
                  'e na consulta HSP; não são obtidos do GPS do celular.'),
            ],
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          // Reserve space for camera orientation AND the four-way viewport
          // controls without overlaying each other on compact phones.
          final size = Size(constraints.maxWidth, math.min(520.0,
              math.max(390.0, MediaQuery.of(context).size.height*.58)));
          return SizedBox(
            width: size.width, height: size.height,
            child: Stack(children: [
              Positioned.fill(
                child: Solar3dTouchSurface(
                  onSingleStart: (at) => _touchStart(at, size),
                  onSingleMove: _touchMove,
                  onInteractionEnd: _onScaleEnd,
                  onMouseScroll: (dy) => setState(() {
                    zoom = (zoom * math.exp(-dy * .0015))
                        .clamp(.45, 4.0).toDouble();
                  }),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      size: size,
                      painter: Solar3dScenePainter(
                        scene: doc.scene,
                        frameScene: cameraFrameScene,
                        hiddenIds: doc.hiddenIds,
                        excludedIds: doc.excludedIds,
                        selectedId: selectedId,
                        yaw: yaw, pitch: pitch, zoom: zoom,
                        cameraPan: cameraPan,
                        showCompass: false,
                        sunAzimuthDegrees: sun.azimuthDegrees,
                        sunElevationDegrees: sun.elevationDegrees,
                        directShadeByPanel: previewShades,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Solar3dCameraControls(
                  yaw: yaw, pitch: pitch, zoom: zoom,
                  onHeading: _setCameraHeading,
                  onPitchStep: _changeCameraPitch,
                  onYawStep: _changeCameraYaw,
                  onPanStep: _panCamera,
                  onResetPan: _resetCameraPan,
                  onDefaultPerspective: _restorePerspective,
                  onTopView: _topView,
                  onZoomIn: () => _zoomCamera(true),
                  onZoomOut: () => _zoomCamera(false),
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        const Text('CÂMERA 3D: N/S/L/O escolhem a orientação; '
            'os ícones de giro à esquerda/direita rotacionam '
            'horizontalmente e as setas de inclinação elevam/abaixam '
            'a perspectiva. +/− controlam o zoom. '
            'As quatro setas MOVER VISTA deslocam a imagem sem mover '
            'placas e obstáculos.'),
        const Text('A ÁREA 3D É PARA MOVER OBJETOS: toque e arraste '
            'uma placa ou obstáculo em X/Z, mantendo sua altura. '
            'Arrastar o fundo não gira a câmera. '
            'Altura da placa = borda inferior; '
            'altura do obstáculo = base (0 m = solo).'),
        Solar3dCollapsibleSection(
          title: 'Trajetória solar e sombras por placa',
          initiallyExpanded: true,
          children: [
            Text('Sombra ao longo do dia e do ano',
            style: Theme.of(context).textTheme.titleMedium),
        Text('Coordenadas solares do projeto — '
            'latitude ${widget.project.latitude.toStringAsFixed(6)}°; '
            'longitude ${widget.project.longitude.toStringAsFixed(6)}°. '
            'A mesma localização é enviada à API HSP.'),
        Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _selectPreviewDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('${previewDay.day.toString().padLeft(2, "0")}/'
                  '${previewDay.month.toString().padLeft(2, "0")}/'
                  '${previewDay.year}'),
            ),
            SizedBox(width: 178, child: DropdownButtonFormField<int>(
              key: ValueKey(projectUtcOffset),
              initialValue: projectUtcOffset,
              decoration: const InputDecoration(
                labelText: 'Fuso do projeto (UTC)'),
              items: [
                for (var h = -12; h <= 14; h++)
                  DropdownMenuItem(
                    value: h,
                    child: Text('UTC${h >= 0 ? "+" : ""}$h'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => projectUtcOffset = v);
              },
            )),
            IconButton.filledTonal(
              onPressed: _toggleSunPlayback,
              tooltip: sunPlayback == null ? 'Reproduzir o dia' : 'Pausar',
              icon: Icon(sunPlayback == null
                  ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
          ]),
        Text('Hora do projeto: $_previewClock '
            '${sun.aboveHorizon ? "· Sol acima do horizonte" : "· Noite"}'),
        Slider(
          value: previewMinutes.toDouble(),
          min: 0, max: 1425, divisions: 95,
          label: _previewClock,
          onChanged: (value) => setState(() =>
              previewMinutes = value.round()),
        ),
        if (terrainCrossingPanels.isNotEmpty)
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Geometria inconsistente: '
                  '${terrainCrossingPanels.length} placa(s) atravessam o '
                  'plano do terreno. A posição do Sol está correta, '
                  'mas os resultados dessas placas não são confiáveis. '
                  'Edite a altura da borda inferior ao solo '
                  '(0 m significa encostada no terreno).'),
                if (_legacyHeightCandidates(doc.scene).isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: busy ? null : _repairLegacyHeights,
                    icon: const Icon(Icons.height_outlined),
                    label: Text('Adaptar altura antiga de '
                      '${_legacyHeightCandidates(doc.scene).length}'
                      ' placa(s) para borda inferior'),
                  ),
              ],
            ),
          )),
        if (current != null && current.kind == Solar3dObjectKind.panel) ...[
          Text('Placa ${current.id}: '
            '${!sun.aboveHorizon
              ? "noite; sem Sol direto"
              : inspections[current.id] == null
                ? "sem incidência solar direta na face frontal"
                : "${(inspections[current.id]!.fraction * 100).toStringAsFixed(1)}% "
                  "da face bloqueada "
                  "(${inspections[current.id]!.blockedSamples}/"
                  "${inspections[current.id]!.totalSamples} pontos)"}'),
          if (inspections[current.id] != null)
            Text(inspections[current.id]!.firstHitByObject.isEmpty
              ? 'Nenhum obstáculo interceptou os raios amostrados '
                'desta placa neste horário.'
              : 'Primeiro bloqueio dos raios por: '
                '${inspections[current.id]!.firstHitByObject.entries.map(
                  (e) => "${e.key} (${e.value} pontos)"
                ).join(", ")}'),
        ],
        if (sun.aboveHorizon && inspections.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text('Sombreamento por placa agora '
              '(fração geométrica da face frontal; não energia):'),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final entry in inspections.entries)
              ActionChip(
                label: Text('${_shortPanelId(entry.key)} · '
                  'MPPT ${doc.scene.objects.firstWhere((o) =>
                    o.id == entry.key).mpptIndex} · '
                  '${entry.value == null ? "sem feixe" :
                    "${(entry.value!.fraction * 100).round()}%"}'),
                avatar: Icon(
                  entry.value == null
                    ? Icons.nightlight_outlined
                    : entry.value!.fraction > .01
                      ? Icons.warning_amber_rounded
                      : Icons.wb_sunny_outlined,
                  size: 15,
                  color: entry.value != null &&
                      entry.value!.fraction > .01
                      ? Colors.deepOrange : null,
                ),
                onPressed: () => setState(() => selectedId = entry.key),
              ),
          ]),
        ],
        const Text('As porcentagens acima descrevem a face iluminada '
            'e não a sombra projetada no chão. A simulação óptica por '
            'placa não equivale a perdas elétricas das strings/MPPTs.'),
        const Text('As sombras seguem a trajetória solar calculada para '
            'a latitude/longitude e a data/hora escolhidas. '
            'O fuso é ajustável (padrão UTC−3), pois depende do projeto.'),
          ],
        ),
        Solar3dCollapsibleSection(
          title: 'Objetos, posições e MPPTs',
          children: [
            Text('Objetos e módulos', style: Theme.of(context).textTheme.titleMedium),
        const Text('Cada inversor possui seus próprios MPPTs: '
            '“Inversor 1 / MPPT 1” é independente de '
            '“Inversor 2 / MPPT 1”. Selecione uma placa '
            'e escolha um MPPT existente no inversor correspondente.'),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final item in doc.scene.objects)
            InputChip(
              label: Text(item.kind == Solar3dObjectKind.panel
                ? '${item.id.split("/").skip(1).join("/")}'
                  ' · ${_trackerLabel(item)}'
                : 'Obstáculo ${item.id}'),
              selected: selectedId == item.id,
              onPressed: () => setState(() => selectedId = item.id),
              avatar: Icon(item.kind == Solar3dObjectKind.panel
                ? Icons.solar_power : Icons.domain, size: 16),
            ),
        ]),
        if (current != null) ...[
          const SizedBox(height: 9),
          Text('Selecionado: ${current.id}',style: Theme.of(context).textTheme.titleMedium),
          Text('Posição (m): Leste ${current.center.x.toStringAsFixed(2)}, '
              '${current.kind == Solar3dObjectKind.panel
                  ? "borda inferior" : "base"} '
              '${(current.kind == Solar3dObjectKind.panel
                  ? Solar3dPanelHeight.lowerEdgeOf(current)
                  : Solar3dObstacleHeight.baseOf(current)).toStringAsFixed(2)}, '
              'Norte ${current.center.z.toStringAsFixed(2)}'),
          if (current.kind == Solar3dObjectKind.panel) ...[
            Text('Altura da BORDA INFERIOR ao solo: '
                '${Solar3dPanelHeight.lowerEdgeOf(current).toStringAsFixed(3)} m'
                ' · Cadastro: '
                '${_registeredLowerEdgeHeight(current.id)?.toStringAsFixed(3) ?? "?"} m'),
            if (_registeredLowerEdgeHeight(current.id) != null &&
                (Solar3dPanelHeight.lowerEdgeOf(current) -
                  _registeredLowerEdgeHeight(current.id)!).abs() > .0001)
              OutlinedButton.icon(
                onPressed: _restoreRegisteredHeight,
                icon: const Icon(Icons.height_outlined),
                label: const Text('Usar altura da borda inferior cadastrada'),
              ),
            if (_panelCrossesTerrain(current)) ...[
              const Text('Atenção: a borda inferior está abaixo do solo. '
                  'Edite a altura informando a borda, não o centro.'),
              OutlinedButton.icon(
                onPressed: () => _replace(
                  Solar3dPanelHeight.withLowerEdge(current, 0)),
                icon: const Icon(Icons.vertical_align_bottom),
                label: const Text('Elevar borda inferior a 0 m'),
              ),
            ],
          ] else ...[
            Text('Altura da BASE ao solo: '
                '${Solar3dObstacleHeight.baseOf(current).toStringAsFixed(3)} m'
                ' · Topo: ${Solar3dObstacleHeight.topOf(current).toStringAsFixed(3)} m'),
            if (Solar3dObstacleHeight.baseOf(current) < -1e-4) ...[
              const Text('Base abaixo do terreno nesta cena antiga. '
                  'A posição anterior foi preservada; corrija manualmente.'),
              OutlinedButton.icon(
                onPressed: () => _replace(
                    Solar3dObstacleHeight.withBase(current, 0)),
                icon: const Icon(Icons.vertical_align_bottom),
                label: const Text('Apoiar base no solo (0 m)'),
              ),
            ],
          ],
          OutlinedButton.icon(
            onPressed: current.kind == Solar3dObjectKind.panel
                ? _editPosition : _editObstacleNumerically,
            icon: const Icon(Icons.edit_note_outlined),
            label: Text(current.kind == Solar3dObjectKind.panel
                ? 'Editar coordenadas X / Z / Y'
                : 'Digitar medidas e posição do obstáculo'),
          ),
          Text('Azimute do objeto: ${current.azimuthDegrees.toStringAsFixed(0)}°'),
          Slider(
            value: current.azimuthDegrees.clamp(0.0, 359.9).toDouble(),
            min: 0, max: 359.9,
            onChanged: (v) => _replace(current.copyWith(azimuthDegrees: v)),
          ),
          if (current.kind == Solar3dObjectKind.panel) ...[
            Text('Inclinação da placa: ${current.tiltDegrees.toStringAsFixed(0)}°'),
            Slider(
              value: current.tiltDegrees,
              min: 0, max: 90,
              onChanged: (v) => _replace(
                Solar3dPanelHeight.withLowerEdge(
                  current,
                  math.max(0, Solar3dPanelHeight.lowerEdgeOf(current)),
                  tiltDegrees: v,
                ),
              ),
            ),
          ] else ...[
            Text('Largura: ${current.width.toStringAsFixed(2)} m'),
            Slider(
              value: current.width,
              min: math.min(0.2, current.width),
              max: math.max(20.0, current.width),
              onChanged: (v) => _replace(current.copyWith(width: v)),
            ),
            Text('Profundidade: ${current.depth.toStringAsFixed(2)} m'),
            Slider(
              value: current.depth,
              min: math.min(0.2, current.depth),
              max: math.max(20.0, current.depth),
              onChanged: (v) => _replace(current.copyWith(depth: v)),
            ),
            Text('Altura do obstáculo: ${current.height.toStringAsFixed(2)} m'),
            Slider(
              value: current.height,
              min: math.min(0.2, current.height),
              max: math.max(20.0, current.height),
              onChanged: (v) {
                try {
                  _replace(Solar3dObstacleHeight.withHeight(current, v));
                } on FormatException catch (error) {
                  _notice(error.message);
                }
              },
            ),
          ],
          if (current.kind == Solar3dObjectKind.panel) ...[
            if (mpptSystem != null) ...[
              Text('Conexão no laboratório: ${_trackerLabel(current)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              Text('MPPT da placa — inversor '
                  '${_systemIndexFor(current.id) + 1}'),
              DropdownButton<int>(
                key: ValueKey('solar3d-mppt-${current.id}'),
                isExpanded: true,
                value: current.mpptIndex != null &&
                        current.mpptIndex! >= 1 &&
                        current.mpptIndex! <= mpptSystem.inverter.mpptCount
                    ? current.mpptIndex : null,
                hint: const Text('Selecionar MPPT'),
                items: [
                  for (var idx = 1; idx <= mpptSystem.inverter.mpptCount; idx++)
                    DropdownMenuItem(
                      value: idx,
                      child: Text('MPPT $idx · '
                          '${mpptSystem.inverter.modelName}'),
                    ),
                ],
                onChanged: busy ? null : (value) {
                  if (value != null && value != current.mpptIndex) {
                    _setPanelMppt(current, value);
                  }
                },
              ),
              const Text('Altera somente a distribuição hipotética na '
                  'análise 3D; não reconfigura o circuito físico.'),
              if (mpptSystem.inverter.mpptCount == 1)
                const Text('Este inversor possui somente 1 MPPT '
                    'no cadastro. Para usar mais MPPTs, selecione '
                    'um inversor compatível no projeto original.'),
            ],
            OutlinedButton.icon(onPressed: _setString,
              icon: const Icon(Icons.cable), label: Text(
                'String: ${current.stringId ?? "não definida"} (estudo)')),
          ],
          Wrap(spacing: 7, children: [
            FilterChip(
              label: const Text('Ocultar na cena'),
              selected: doc.hiddenIds.contains(current.id),
              onSelected: (_) => _toggle(visibility:true),
            ),
            FilterChip(
              label: const Text('Ignorar na análise'),
              selected: doc.excludedIds.contains(current.id),
              onSelected: (_) => _toggle(visibility:false),
            ),
            if (current.kind != Solar3dObjectKind.panel)
              OutlinedButton.icon(onPressed: _deleteObstacle,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover obstáculo')),
          ]),
          const Text('Ocultar muda só a visualização. Ignorar exclui o '
              'objeto dos raios geométricos, sem alterar o circuito do inversor.'),
        ],
        Wrap(spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(onPressed: busy ? null : _addObstacle,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Adicionar obstáculo')),

          OutlinedButton.icon(onPressed: busy ? null : _resetStudy,
            icon: const Icon(Icons.restart_alt_outlined),
            label: const Text('RESETAR ANÁLISE 3D')),
        ]),
          ],
        ),
        Solar3dCollapsibleSection(
          title: 'Auditoria elétrica preliminar',
          children: [_electricalAuditPanel()],
        ),
        Solar3dCollapsibleSection(
          title: 'Calcular perdas ópticas · 12 meses',
          children: [
            Text('HSP por placa · consulta horária opcional',
            style: Theme.of(context).textTheme.titleMedium),
        const Text('A consulta HSP horária utiliza uma rota independente '
            'do dimensionamento clássico. O domínio público HTTPS '
            'precisa ter a versão com /recurso-solar/horario implantada. '
            'Para testes offline, a cena e as sombras 3D funcionam '
            'sem conectar à API.'),
        TextField(
          controller: hourlyEndpointController,
          decoration: const InputDecoration(
            labelText: 'Endpoint horário HSP',
            helperText: 'Pode ser alterado sem recompilar o aplicativo.',
            prefixIcon: Icon(Icons.api_outlined),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {
            monthly = {};
        calculatedYearUtc = null;
            lastCalculatedHourlyEndpoint = null;
          }),
        ),
        Wrap(spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(
            onPressed: () => setState(() {
              hourlyEndpointController.text =
                  SolarResourceHourlyDataSource.publicEndpoint;
              monthly = {};
        calculatedYearUtc = null;
              lastCalculatedHourlyEndpoint = null;
            }),
            icon: const Icon(Icons.public),
            label: const Text('Usar HSP público HTTPS'),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              hourlyEndpointController.text = localHourlyUrl;
              monthly = {};
        calculatedYearUtc = null;
              lastCalculatedHourlyEndpoint = null;
            }),
            icon: const Icon(Icons.computer_outlined),
            label: const Text('Usar HSP local Windows'),
          ),
        ]),
        const Text('Ano meteorológico:'),
        SizedBox(
          width: double.infinity,
          child: DropdownButton<int>(
              isExpanded: true,
              value: yearSelection,
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Mais recente completo (automático)'),
                ),
                for (final y in [2022, 2023, 2024])
                  DropdownMenuItem(value: y, child: Text('Ano $y')),
              ],
              onChanged: busy ? null : (value) {
                if (value != null) {
                  setState(() {
                    yearSelection = value;
                    monthly = {};
                    calculatedYearUtc = null;
                    lastCalculatedHourlyEndpoint = null;
                  });
                }
              },
            ),
        ),
        const Text('O servidor HSP escolhe automaticamente o último '
            'ano civil UTC completo. Na configuração NASA POWER atual '
            'é 2024; quando forem publicados dados completos de 2025, '
            'o aplicativo poderá utilizá-los sem alteração. '
            'Janeiro a dezembro são sempre calculados em sequência.'),
        if (calculatedYearUtc != null)
          Text('Ano confirmado na resposta HSP: $calculatedYearUtc',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        FilledButton.icon(onPressed:busy?null:_calculate,
          icon: const Icon(Icons.calculate_outlined),
          label:Text(busy ? progress : 'Calcular perdas ópticas por placa')),
        if (busy) const LinearProgressIndicator(),
        _monthlyTable(),
          ],
        ),
        Solar3dCollapsibleSection(
          title: 'Aplicar correção óptica na geração',
          children: [
            Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Aplicar na geração estimada',
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              const Text('Necessário calcular os 12 meses para todas '
                  'as placas. A correção será aplicada uma única vez '
                  'por MPPT, separando o cenário sem sombra do ajuste '
                  'óptico. O fator não representa ainda o comportamento '
                  'elétrico das strings.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: !busy && monthly.length == 12
                    ? _applyOpticalToProject : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('APLICAR CORREÇÃO ÓPTICA NA GERAÇÃO'),
              ),
              if (monthly.length != 12)
                const Text('Execute o cálculo de janeiro a dezembro '
                    'para habilitar a aplicação da correção.'),
            ],
          ),
        )),
        const SizedBox(height: 12),
        const Text('Esta tela não substitui o cálculo do arranjo no GreenCity OS. '
            'Perdas por MPPT exigem modelagem elétrica adicional (strings, '
            'bypass e curvas I–V calibradas).'),
        const SizedBox(height: 24),
          ],
        ),
      ]),
    );
  }
}
