import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/datasources/solar_resource_hourly_data_source.dart';
import '../../../data/datasources/solar3d_scene_storage.dart';
import '../../../domain/entities/solar_project.dart';
import '../../../domain/entities/solar_system.dart';
import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import '../../../domain/solar3d/solar3d_plan_factory.dart';
import '../../../domain/solar3d/solar3d_scene_document.dart';
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
  String? initError;
  String? selectedId;
  double yaw = 0.6, pitch = 0.65, zoom = 1;
  double sunAzimuth = 90, sunElevation = 40;
  int month = 1, year = 2023;
  bool allMonths = false, busy = false;
  String progress = '';
  Map<int, List<PanelMonthlyIrradianceLoss>> monthly = {};
  static const String hourlyUrl = String.fromEnvironment(
    'HSP_HOURLY_URL',
    defaultValue: 'https://hsp.greencity.net.br/api/recurso-solar/horario',
  );

  @override
  void initState() {
    super.initState();
    try {
      final scene = Solar3dPlanFactory.fromSystems(widget.systems);
      document = Solar3dSceneDocument(scene: scene);
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

  Future<void> _loadSaved() async {
    try {
      final saved = await storage!.load();
      if (!mounted || saved == null || document == null) return;
      setState(() {
        document = saved.reconciledWith(document!.scene);
        selectedId = document!.scene.objects.firstWhere(
          (o) => o.kind == Solar3dObjectKind.panel).id;
        monthly = {};
      });
    } catch (err) {
      if (mounted) {
      _notice('Não foi possível abrir a cena salva: $err');
    }
    }
  }

  void _notice(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Solar3dObject? get selected {
    final doc = document;
    if (doc == null || selectedId == null) return null;
    for (final item in doc.scene.objects) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  SolarSystem? _systemFor(String panelId) {
    for (final system in widget.systems) {
      if (panelId.startsWith('${system.id}/')) return system;
    }
    return null;
  }

  void _changeDocument(Solar3dSceneDocument next) {
    next.scene.validate();
    setState(() { document = next; monthly = {}; });
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

  void _move(double dx, double dy, double dz) {
    final current = selected;
    if (current == null) return;
    _replace(current.copyWith(center: Solar3dVector(
      current.center.x + dx,
      current.center.y + dy,
      current.center.z + dz,
    )));
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

  Map<String, double?> _previewShadows() {
    final current = selected;
    if (current == null || current.kind != Solar3dObjectKind.panel ||
        document!.excludedIds.contains(current.id)) return {};
    final value = Solar3dGeometricShading.blockedFraction(
      panel: current, scene: analysisScene,
      sunAzimuthDegrees: sunAzimuth,
      sunElevationDegrees: sunElevation, rows: 6, columns: 4,
    );
    return {current.id: value};
  }

  Future<void> _calculate() async {
    final doc = document;
    if (doc == null || busy) return;
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
    final groups = <String, List<Solar3dObject>>{};
    for (final panel in panels) {
      final key = '${panel.tiltDegrees.toStringAsFixed(4)}|${panel.azimuthDegrees.toStringAsFixed(4)}';
      groups.putIfAbsent(key, () => []).add(panel);
    }
    if (groups.length > 8) {
      _notice('Máximo de 8 orientações distintas por análise de pesquisa.');
      return;
    }
    setState(() { busy = true; progress = 'Preparando séries'; monthly = {}; });
    final client = SolarResourceHourlyDataSource(dio: Dio(), endpoint: hourlyUrl);
    final output = <int, List<PanelMonthlyIrradianceLoss>>{};
    try {
      final months = allMonths ? List.generate(12, (i) => i + 1) : [month];
      for (final m in months) {
        if (!mounted) return;
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
        setState(() => monthly = output);
      }
    } catch (err) {
      _notice('Falha no cálculo horário: $err. Confirme o endpoint local/DEV.');
    } finally {
      if (mounted) setState(() { busy = false; progress = ''; });
    }
  }

  void _onTapDown(TapDownDetails details, Size size) {
    final doc = document!;
    final view = Solar3dProjection(
      size: size, scene: doc.scene, yaw: yaw, pitch: pitch, zoom: zoom,
    );
    String? nearest;
    var minDistance = 55.0;
    for (final item in doc.scene.objects) {
      if (doc.hiddenIds.contains(item.id)) continue;
      final p = view.project(item.center);
      final delta = (p - details.localPosition).distance;
      if (delta < minDistance) {
        nearest = item.id; minDistance = delta;
      }
    }
    if (nearest != null) setState(() => selectedId = nearest);
  }

  Widget _adjustButtons() => Wrap(spacing: 4, runSpacing: 2, children: [
    OutlinedButton(onPressed: () => _move(-.25,0,0), child: const Text('← Oeste')),
    OutlinedButton(onPressed: () => _move(.25,0,0), child: const Text('Leste →')),
    OutlinedButton(onPressed: () => _move(0,0,.25), child: const Text('↑ Norte')),
    OutlinedButton(onPressed: () => _move(0,0,-.25), child: const Text('Sul ↓')),
    OutlinedButton(onPressed: () => _move(0,.25,0), child: const Text('Altura +')),
    OutlinedButton(onPressed: () => _move(0,-.25,0), child: const Text('Altura −')),
  ]);

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
          return GestureDetector(
            onTapDown: (event) => _onTapDown(event,size),
            child: SizedBox(height: size.height, width: size.width,
              child: ClipRRect(borderRadius: BorderRadius.circular(12),
                child: CustomPaint(size: size, painter: Solar3dScenePainter(
                  scene: doc.scene,
                  hiddenIds: doc.hiddenIds,
                  excludedIds: doc.excludedIds,
                  selectedId: selectedId, yaw: yaw, pitch: pitch,
                  zoom: zoom, directShadeByPanel: _previewShadows(),
                )),
              ),
            ),
          );
        }),
        Wrap(spacing: 12, children: [
          SizedBox(width: 190, child: Column(children: [
            const Text('Rotação da câmera'),
            Slider(value: yaw, min: -math.pi, max: math.pi,
              onChanged: (v) => setState(() => yaw = v)),
          ])),
          SizedBox(width: 190, child: Column(children: [
            const Text('Inclinação da câmera'),
            Slider(value: pitch, min: .15, max: 1.45,
              onChanged: (v) => setState(() => pitch = v)),
          ])),
          SizedBox(width: 160, child: Column(children: [
            const Text('Zoom'),
            Slider(value: zoom, min: .5, max: 2.5,
              onChanged: (v) => setState(() => zoom = v)),
          ])),
        ]),
        const Divider(),
        Text('Posição solar MANUAL · prévia geométrica',
            style: Theme.of(context).textTheme.titleMedium),
        Text('Azimute ${sunAzimuth.toStringAsFixed(0)}°'),
        Slider(value: sunAzimuth, min: 0, max: 360,
          onChanged: (v) => setState(() => sunAzimuth = v)),
        Text('Elevação ${sunElevation.toStringAsFixed(0)}°'),
        Slider(value: sunElevation, min: -10, max: 90,
          onChanged: (v) => setState(() => sunElevation = v)),
        if (current != null && current.kind == Solar3dObjectKind.panel)
          Text('Bloqueio direto da placa selecionada: ${_previewShadows()[current.id]?.toStringAsFixed(3) ?? "sem feixe incidente"}'
              ' (fração da área, não perda de energia elétrica)'),
        const Divider(),
        Text('Objetos e módulos', style: Theme.of(context).textTheme.titleMedium),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final item in doc.scene.objects)
            InputChip(
              label: Text(item.kind == Solar3dObjectKind.panel
                ? '${item.id} · MPPT ${item.mpptIndex}' : 'Obstáculo ${item.id}'),
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
          _adjustButtons(),
          if (current.kind == Solar3dObjectKind.panel) ...[
            if (mpptSystem != null) DropdownButtonFormField<int>(
              key: ValueKey('${current.id}/${current.mpptIndex}'),
              initialValue: current.mpptIndex,
              decoration: const InputDecoration(labelText: 'MPPT — somente cenário 3D'),
              items: [
                for(var idx=1;idx<=mpptSystem.inverter.mpptCount;idx++)
                  DropdownMenuItem(value:idx,child: Text('MPPT $idx')),
              ],
              onChanged: (value) {
                if(value!=null) _replace(current.copyWith(mpptIndex:value));
              },
            ),
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
        Row(children: [
          OutlinedButton.icon(onPressed:_addObstacle,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Adicionar obstáculo')),
          const SizedBox(width:8),
          FilledButton.icon(onPressed:_save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar cena')),
        ]),
        const Divider(),
        Text('HSP por placa · consulta horária opcional',
            style: Theme.of(context).textTheme.titleMedium),
        const Text('O botão utiliza a nova rota HSP, ainda não implantada '
            'em produção. Use --dart-define=HSP_HOURLY_URL=... para testar '
            'contra a API local. Equipamentos e MPPTs não sofrem alteração.'),
        Wrap(spacing: 14, children: [
          DropdownButton<int>(value: year, items: [
            for (final y in [2022,2023,2024])
              DropdownMenuItem(value:y,child:Text('Ano $y')),
          ],onChanged:busy ? null : (v) {if(v!=null)setState(()=>year=v);}),
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
        const Text('Esta tela não substitui o cálculo do arranjo no GreenCity OS. '
            'Perdas por MPPT exigem modelagem elétrica adicional (strings, '
            'bypass e curvas I–V calibradas).'),
        const SizedBox(height: 24),
      ]),
    );
  }
}
