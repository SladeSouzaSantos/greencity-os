import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/datasources/solar_resource_hourly_data_source.dart';
import '../../../data/datasources/solar3d_scene_storage.dart';
import '../../../domain/entities/solar_project.dart';
import '../../../domain/entities/solar_system.dart';
import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import '../../../domain/solar3d/solar3d_plan_factory.dart';
import '../../../domain/solar3d/solar3d_optical_correction.dart';
import '../../../domain/solar3d/solar3d_scene_document.dart';
import '../../../domain/solar3d/solar3d_sun_position.dart';
import '../../widgets/photovoltaic/solar3d_scene_painter.dart';

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
  // Freeze framing during edits, so dragging does not recenter the scene.
  Solar3dScene? cameraFrameScene;
  Solar3dScene? catalogInitialScene;
  String? draggingId;
  Solar3dVector? dragStartCenter;
  Solar3dVector? dragStartWorld;
  Solar3dProjection? dragProjection;
  Offset? lastGesturePoint;
  double lastGestureScale = 1, lastGestureRotation = 0;
  bool multiTouch = false;
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
  int month = 1, year = 2023;
  bool allMonths = false, busy = false;
  String progress = '';
  Map<int, List<PanelMonthlyIrradianceLoss>> monthly = {};
  int sceneRevision = 0;
  String? lastCalculatedHourlyEndpoint;
  static const String hourlyUrl = String.fromEnvironment(
    'HSP_HOURLY_URL',
    defaultValue: 'https://hsp.greencity.net.br/api/recurso-solar/horario',
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
      await storage!.clear();
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
      lastCalculatedHourlyEndpoint = null;
      sceneRevision++;
    });
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

   double? _registeredCenterHeight(String objectId) {
    final base = catalogInitialScene;
    if (base == null) return null;
    for (final object in base.objects) {
      if (object.id == objectId &&
          object.kind == Solar3dObjectKind.panel) {
        return object.center.y;
      }
    }
    return null;
  }

  void _restoreRegisteredHeight() {
    final panel = selected;
    if (panel == null || panel.kind != Solar3dObjectKind.panel) return;
    final height = _registeredCenterHeight(panel.id);
    if (height == null) return;
    _replace(panel.copyWith(center: Solar3dVector(
      panel.center.x, height, panel.center.z)));
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

  void _addObstacle() {
    final doc = document!;
    if (doc.scene.objects.length >= 100) {
      _notice('Limite de 100 objetos no cenário inicial');
      return;
    }
    final item = Solar3dObject(
      id: 'obstacle-${DateTime.now().microsecondsSinceEpoch}',
      kind: Solar3dObjectKind.obstacle,
      center: const Solar3dVector(0, 1.5, 0),
      width: 2, depth: 2, height: 3,
    );
    _changeDocument(Solar3dSceneDocument(
      scene: Solar3dScene([...doc.scene.objects, item]),
      hiddenIds: doc.hiddenIds, excludedIds: doc.excludedIds,
    ));
    setState(() => selectedId = item.id);
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
    final ctrl = TextEditingController(text: current.stringId ?? '');
    final submitted = await showDialog<String>(context: context,
      builder: (context) => AlertDialog(
        title: const Text('String da placa — estudo'),
        content: TextField(
          controller: ctrl,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'ID da string (ex.: S1)',
            helperText: 'Não altera ainda o dimensionamento do inversor.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(
            context, ctrl.text.trim()), child: const Text('Aplicar')),
        ],
      ));
    ctrl.dispose();
    if (!mounted || submitted == null) return;
    _replace(current.copyWith(
      stringId: submitted.isEmpty ? null : submitted,
      clearString: submitted.isEmpty,
    ));
  }

  Future<void> _save() async {
    if (document == null || storage == null) return;
    try {
      await storage!.save(document!);
      _notice('Cena 3D salva neste dispositivo; circuito elétrico original preservado.');
    } catch (err) {
      _notice('Falha ao salvar cena: $err');
    }
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
    final scene = analysisScene;
    final result = <String, Solar3dPanelShadeInspection?>{};
    if (!sun.aboveHorizon) return result;
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
    return result;
  }

  static String _shortPanelId(String id) {
    final parts = id.split('/');
    return parts.length >= 2
        ? parts.sublist(parts.length - 2).join('/')
        : id;
  }

  static double _panelLowestPoint(Solar3dObject panel) =>
      panel.center.y -
      panel.depth / 2 * math.sin(panel.tiltDegrees * math.pi / 180) -
      panel.height / 2 * math.cos(panel.tiltDegrees * math.pi / 180);

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
          'do centro ou a inclinação antes de calcular perdas mensais.');
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
      lastCalculatedHourlyEndpoint = null;
    });
    final client = SolarResourceHourlyDataSource(
        dio: Dio(), endpoint: endpoint);
    final output = <int, List<PanelMonthlyIrradianceLoss>>{};
    try {
      final months = allMonths ? List.generate(12, (i) => i + 1) : [month];
      for (final m in months) {
        if (!mounted) return;
        if (revision != sceneRevision) {
          throw StateError(
            'A cena mudou durante o cálculo. Calcule novamente.');
        }
        setState(() => progress = 'Calculando mês $m/${months.last}');
        final values = <PanelMonthlyIrradianceLoss>[];
        for (final group in groups.values) {
          final sample = group.first;
          final resource = await client.getHourlyResource(
            latitude: widget.project.latitude,
            longitude: widget.project.longitude,
            inclination: sample.tiltDegrees,
            azimuth: sample.azimuthDegrees,
            yearUtc: year,
            monthUtc: m,
            source: 'NASA POWER',
          );
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
            'A rota horária não está implantada na API HSP de produção. '
            'Para testar no Windows, execute o HSP Simulator na branch '
            'feature/hourly-resource-api com '
            'python -m uvicorn api:app --host 127.0.0.1 --port 8000 '
            'e selecione o endpoint local.\n\n'
            'Os dois containers hsp-solar3d-lab-* executam outra API '
            'experimental e NÃO oferecem esta rota. '
            'A visualização das sombras 3D funciona sem o servidor.',
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
      yaw: yaw, pitch: pitch, zoom: zoom,
    );
  }

  /// Hit-test the face polygon first; a center-distance fallback helps
  /// select tiny panels on touch screens. Hide does not affect physics.
  Solar3dObject? _hitObject(Offset at, Solar3dProjection view) {
    final doc = document!;
    final visible = doc.scene.objects
        .where((o) => !doc.hiddenIds.contains(o.id)).toList()
      ..sort((a,b) => view.depth(a.center).compareTo(view.depth(b.center)));
    for (final object in visible) {
      final polygon = view.face(object, object.height / 2);
      final path = Path()..addPolygon(polygon, true);
      if (path.contains(at)) return object;
    }
    Solar3dObject? nearest;
    var distance = 34.0;
    for (final object in visible) {
      final d = (view.project(object.center) - at).distance;
      if (d < distance) {
        distance = d; nearest = object;
      }
    }
    return nearest;
  }

  /// Explicitly hand the optical scenario back to the generation screen.
  /// It changes only the monthly energy-estimate overlay in this session.
  /// The actual electrical topology, production and quote are not silently
  /// rewritten; no string mismatch/bypass yield is asserted.
  Future<void> _applyOpticalToProject() async {
    if (busy) return;
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
        yearUtc: year,
        excludedPanelIds: doc.excludedIds,
      );
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
            'As conexões físicas originais NÃO serão alteradas. '
            'A geração estimada pode mudar pela nova distribuição '
            'hipotética dos MPPTs além da sombra. '
            'A cena de estudo será salva localmente no dispositivo.\n\n'
            'ATENÇÃO: É uma estimativa experimental de irradiância; '
            'não modela eletricamente strings, bypass nem mismatch '
            'sob sombras parciais. Não representa geração AC '
            'validada e ainda não é salva como projeto homologado. '
            'Os obstáculos da API HSP convencional precisam estar '
            'desativados para evitar dupla contagem.',
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
      await storage!.save(doc);
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

  void _onTapDown(TapDownDetails details, Size size) {
    final item = _hitObject(details.localPosition, _projection(size));
    if (item != null) setState(() => selectedId = item.id);
  }

  void _onScaleStart(ScaleStartDetails details, Size size) {
    _onPanEnd();
    lastGesturePoint = details.localFocalPoint;
    lastGestureScale = 1;
    lastGestureRotation = 0;
    multiTouch = details.pointerCount >= 2;
    if (multiTouch) return;
    final view = _projection(size);
    final item = _hitObject(details.localFocalPoint, view);
    if (item == null) return; // One finger on empty background orbits.
    draggingId = item.id;
    dragStartCenter = item.center;
    dragProjection = view;
    dragStartWorld = view.pointOnHorizontalPlane(
      details.localFocalPoint, item.center.y);
    setState(() => selectedId = item.id);
  }

  static double _wrapYaw(double v) =>
      (v + math.pi) % (2 * math.pi) - math.pi;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      if (!multiTouch) {
        multiTouch = true;
        _onPanEnd();
        lastGestureScale = details.scale;
        lastGestureRotation = details.rotation;
        lastGesturePoint = details.localFocalPoint;
        return;
      }
      final ratio = lastGestureScale.abs() > 1e-6
          ? details.scale / lastGestureScale : 1.0;
      final twist = details.rotation - lastGestureRotation;
      lastGestureScale = details.scale;
      lastGestureRotation = details.rotation;
      lastGesturePoint = details.localFocalPoint;
      setState(() {
        if (ratio.isFinite && ratio > 0) {
          zoom = (zoom * ratio).clamp(.45, 4.0).toDouble();
        }
        if (twist.isFinite) yaw = _wrapYaw(yaw + twist);
      });
      return;
    }
    if (multiTouch) return;
    if (draggingId != null) {
      _dragTo(details.localFocalPoint);
      return;
    }
    final last = lastGesturePoint ?? details.localFocalPoint;
    final delta = details.localFocalPoint - last;
    lastGesturePoint = details.localFocalPoint;
    setState(() {
      yaw = _wrapYaw(yaw + delta.dx * .009);
      pitch = (pitch - delta.dy * .006).clamp(.2, math.pi / 2).toDouble();
    });
  }

  void _onScaleEnd() {
    _onPanEnd();
    lastGesturePoint = null;
    multiTouch = false;
    lastGestureScale = 1;
    lastGestureRotation = 0;
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
    final eastCtrl = TextEditingController(text: current.center.x.toStringAsFixed(3));
    final northCtrl = TextEditingController(text: current.center.z.toStringAsFixed(3));
    final heightCtrl = TextEditingController(text: current.center.y.toStringAsFixed(3));
    final accepted = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Posicionar objeto (metros)'),
        content: SizedBox(width: 320, child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: eastCtrl,
              decoration: const InputDecoration(labelText: 'X · Leste (+) / Oeste (−)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
            TextField(controller: northCtrl,
              decoration: const InputDecoration(labelText: 'Z · Norte (+) / Sul (−)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
            TextField(controller: heightCtrl,
              decoration: const InputDecoration(labelText: 'Y · Altura do centro do módulo ao solo'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aplicar')),
        ],
      ));
    double? read(TextEditingController ctrl) => double.tryParse(
      ctrl.text.trim().replaceAll(',', '.'));
    final x = read(eastCtrl), z = read(northCtrl), y = read(heightCtrl);
    eastCtrl.dispose();
    northCtrl.dispose();
    heightCtrl.dispose();
    if (!mounted || accepted != true) return;
    if (x == null || z == null || y == null ||
        !x.isFinite || !z.isFinite || !y.isFinite ||
        x.abs() > 500 || z.abs() > 500 || y < 0 || y > 500) {
      _notice('Coordenadas inválidas: X/Z ±500 m e altura Y de 0 a 500 m.');
      return;
    }
    _replace(current.copyWith(center: Solar3dVector(x, y, z)));
  }

  void _reframe() {
    _onPanEnd();
    setState(() => cameraFrameScene = document!.scene);
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
          IconButton(onPressed: _save, tooltip: 'Salvar cena',
            icon: const Icon(Icons.save_outlined)),
        ]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Card(child: Padding(padding: EdgeInsets.all(12), child: Text(
          'Laboratório de sombreamento: cena volumétrica editável e perdas de '
          'IRRADIÂNCIA por placa. Posições iniciais são ilustrativas, '
          'não medições do telhado. A API HSP principal continua intacta.'
        ))),
        LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, math.min(440.0,
              math.max(250.0, MediaQuery.of(context).size.height*.48)));
          return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                setState(() => zoom = (zoom *
                    math.exp(-event.scrollDelta.dy * .0015))
                    .clamp(.45, 4.0).toDouble());
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (event) => _onTapDown(event,size),
              onScaleStart: (event) => _onScaleStart(event,size),
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: (_) => _onScaleEnd(),
              child: SizedBox(height: size.height, width: size.width,
              child: ClipRRect(borderRadius: BorderRadius.circular(12),
                child: CustomPaint(size: size, painter: Solar3dScenePainter(
                  scene: doc.scene,
                  frameScene: cameraFrameScene,
                  hiddenIds: doc.hiddenIds,
                  excludedIds: doc.excludedIds,
                  selectedId: selectedId, yaw: yaw, pitch: pitch,
                  zoom: zoom,
                  sunAzimuthDegrees: sun.azimuthDegrees,
                  sunElevationDegrees: sun.elevationDegrees,
                  directShadeByPanel: previewShades,
                )),
              ),
            ),
            ),
          );
        }),
        const SizedBox(height: 8),
        const Text('N / S / L / O: bússola geográfica, acompanha a câmera. '
            'X: Leste/Oeste · Z: Norte/Sul · Y: distância do centro ao solo.'),
        const Text('Toque em uma placa para mover; arraste no fundo para '
            'girar a câmera. Faça pinça com dois dedos para zoom e giro; '
            'no computador, use a roda do mouse para zoom.'),
        Wrap(spacing: 8, runSpacing: 5, children: [
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _onScaleEnd();
              yaw = 0;
              pitch = math.pi / 2;
            }),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Vista superior · N ↑'),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _onScaleEnd();
              yaw = .6;
              pitch = .80;
            }),
            icon: const Icon(Icons.view_in_ar_outlined),
            label: const Text('Perspectiva'),
          ),
          OutlinedButton.icon(
            onPressed: _reframe,
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('Enquadrar cena'),
          ),
        ]),
        const Divider(),
        Text('Sombra ao longo do dia e do ano',
            style: Theme.of(context).textTheme.titleMedium),
        Text('Local do projeto: '
            '${widget.project.latitude.toStringAsFixed(4)}°, '
            '${widget.project.longitude.toStringAsFixed(4)}°'),
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
            child: Text('Geometria inconsistente: '
              '${terrainCrossingPanels.length} placa(s) atravessam o '
              'plano do terreno devido à altura central e inclinação. '
              'A posição do Sol está correta, mas os resultados de '
              'sombreamento dessas placas não são confiáveis. '
              'Ajuste a altura antes do cálculo mensal.'),
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
        const Divider(),
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
              'altura ${current.center.y.toStringAsFixed(2)}, '
              'Norte ${current.center.z.toStringAsFixed(2)}'),
          if (current.kind == Solar3dObjectKind.panel) ...[
            Text('Altura do CENTRO da placa ao solo: '
                '${current.center.y.toStringAsFixed(3)} m'
                ' · Cadastro: '
                '${_registeredCenterHeight(current.id)?.toStringAsFixed(3) ?? "?"} m'),
            if (_registeredCenterHeight(current.id) != null &&
                (current.center.y -
                  _registeredCenterHeight(current.id)!).abs() > .0001)
              OutlinedButton.icon(
                onPressed: _restoreRegisteredHeight,
                icon: const Icon(Icons.height_outlined),
                label: const Text('Usar altura do centro cadastrada'),
              ),
            if (_panelCrossesTerrain(current))
              const Text('Atenção: parte da placa pode atravessar o '
                  'plano do terreno. Confira altura e inclinação.'),
          ],
          OutlinedButton.icon(
            onPressed: _editPosition,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('Editar coordenadas X / Z / Y'),
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
              onChanged: (v) => _replace(current.copyWith(tiltDegrees: v)),
            ),
          ] else ...[
            Text('Largura: ${current.width.toStringAsFixed(2)} m'),
            Slider(
              value: current.width.clamp(0.2, 20.0).toDouble(),
              min: 0.2, max: 20,
              onChanged: (v) => _replace(current.copyWith(width: v)),
            ),
            Text('Profundidade: ${current.depth.toStringAsFixed(2)} m'),
            Slider(
              value: current.depth.clamp(0.2, 20.0).toDouble(),
              min: 0.2, max: 20,
              onChanged: (v) => _replace(current.copyWith(depth: v)),
            ),
            Text('Altura do obstáculo: ${current.height.toStringAsFixed(2)} m'),
            Slider(
              value: current.height.clamp(0.2, 20.0).toDouble(),
              min: 0.2, max: 20,
              onChanged: (v) => _replace(current.copyWith(height: v)),
            ),
          ],
          if (current.kind == Solar3dObjectKind.panel) ...[
            if (mpptSystem != null) ...[
              Text('Conexão no laboratório: ${_trackerLabel(current)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              DropdownButtonFormField<int>(
                key: ValueKey('${current.id}/${current.mpptIndex}'),
                initialValue: current.mpptIndex! <=
                        mpptSystem.inverter.mpptCount
                    ? current.mpptIndex : null,
                decoration: InputDecoration(
                  labelText: 'MPPT da placa — inversor ${_systemIndexFor(current.id) + 1}',
                  helperText: 'Altera apenas a distribuição hipotética '
                      'na análise 3D (não reconfigura o circuito físico).',
                ),
                items: [
                  for (var idx = 1; idx <= mpptSystem.inverter.mpptCount; idx++)
                    DropdownMenuItem(
                      value: idx,
                      child: Text('MPPT $idx · '
                          '${mpptSystem.inverter.modelName}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _setPanelMppt(current, value);
                },
              ),
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
          FilledButton.icon(onPressed: busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar cena')),
          OutlinedButton.icon(onPressed: busy ? null : _resetStudy,
            icon: const Icon(Icons.restart_alt_outlined),
            label: const Text('RESETAR ANÁLISE 3D')),
        ]),
        const Divider(),
        Text('HSP por placa · consulta horária opcional',
            style: Theme.of(context).textTheme.titleMedium),
        const Text('A API de produção ainda não disponibiliza esta rota '
            'experimental. Inicie o backend HSP com '
            'feature/hourly-resource-api para calcular perdas mensais. '
            'A visualização de sombras acima funciona sem API.'),
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
            lastCalculatedHourlyEndpoint = null;
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => setState(
              () => hourlyEndpointController.text = localHourlyUrl),
            icon: const Icon(Icons.computer_outlined),
            label: const Text('Usar API local Windows · porta 8000'),
          ),
        ),
        Wrap(spacing: 14, children: [
          DropdownButton<int>(value: year, items: [
            for (final y in [2022,2023,2024])
              DropdownMenuItem(value:y,child:Text('Ano $y')),
          ],onChanged:busy ? null : (v) {
            if (v != null) {
              setState(() {
                year = v;
                monthly = {};
              });
            }
          }),
          DropdownButton<int>(value:month, items: [
            for(var m=1;m<=12;m++)
              DropdownMenuItem(value:m,child:Text('Mês $m')),
          ],onChanged:busy ? null : (v) {if(v!=null)setState(()=>month=v);}),
          FilterChip(label: const Text('Calcular 12 meses'),
            selected:allMonths, onSelected:busy?null:(v)=>setState(()=>allMonths=v)),
        ]),
        FilledButton.icon(onPressed:busy?null:_calculate,
          icon: const Icon(Icons.calculate_outlined),
          label:Text(busy ? progress : 'Calcular perdas ópticas por placa')),
        if (busy) const LinearProgressIndicator(),
        _monthlyTable(),
        const SizedBox(height: 12),
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
                const Text('Selecione “Calcular 12 meses” e execute '
                    'o cálculo completo para habilitar a aplicação.'),
            ],
          ),
        )),
        const SizedBox(height: 12),
        const Text('Esta tela não substitui o cálculo do arranjo no GreenCity OS. '
            'Perdas por MPPT exigem modelagem elétrica adicional (strings, '
            'bypass e curvas I–V calibradas).'),
        const SizedBox(height: 24),
      ]),
    );
  }
}
