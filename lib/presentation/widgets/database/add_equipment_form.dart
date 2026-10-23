import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../../core/injection/injection.dart';
import 'equipment_error_dialog.dart';
import '../../../core/services/datasheet_ai_service.dart';
import '../../../data/repositories/equipment_catalog.dart';
import '../../../domain/services/equipment_input_validator.dart';
import '../../../data/models/ai_extraction_result_model.dart';
import '../../../data/models/ai_equipment_refinement.dart';
import '../../../data/models/ai_datasheet_semantic_auditor.dart';
import '../../../data/models/ai_equipment_mapper.dart';
import '../../../domain/entities/inverter.dart';
import '../../../domain/entities/inverter_mppt_configuration.dart';
import '../../../domain/entities/pv_module.dart';
import '../../../domain/enums/cell_technology.dart';
import '../../../domain/enums/grid_connection.dart';
import '../../../domain/enums/inverter_type.dart';

class AddEquipmentForm extends StatefulWidget {
  final String initialType;
  final PvModule? moduleToEdit;
  final Inverter? inverterToEdit;

  const AddEquipmentForm({
    super.key,
    this.initialType = 'modulo',
    this.moduleToEdit,
    this.inverterToEdit,
  }) : assert(moduleToEdit == null || inverterToEdit == null);

  @override
  State<AddEquipmentForm> createState() => _AddEquipmentFormState();
}

class _AddEquipmentFormState extends State<AddEquipmentForm> {
  String type = 'modulo';
  bool get _editing => widget.moduleToEdit != null ||
      widget.inverterToEdit != null;
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _ctrl = {};

  CellTechnology _modCellTech = CellTechnology.topcon;
  bool _modTier1 = true;
  bool _modBifacial = false;

  InverterType _invType = InverterType.string;
  GridConnection _invGridConn = GridConnection.triphasic;
  bool _invHybrid = false;

  final List<Object> _pendingAiModels = [];
  final Set<String> _registeredModuleKeys = {};
  final Set<String> _registeredInverterKeys = {};
  Map<String, List<String>> _aiAuditWarnings = {};
  String _aiProviderDescription = '';
  final Set<String> _manualEditedFields = {};
  bool _isLoadingAi = false;
  bool _isSaving = false;
  int _totalAiModels = 0;
  int _savedAiModels = 0;
  final _brandFocusNode = FocusNode();

  // [ADICIONADO] Lista para armazenar fabricantes que já existem no banco
  List<String> _existingManufacturers = [];

  @override
  void initState() {
    super.initState();
    type = widget.moduleToEdit != null ? 'modulo' :
        widget.inverterToEdit != null ? 'inversor' : widget.initialType;
    _initControllers();
    _fillExistingEquipment();
    _loadManufacturers();
  }

  // [ADICIONADO] Busca fabricantes no Isar dependendo do tipo selecionado
  Future<void> _loadManufacturers() async {
    final currentType = type;
    final isar = getIt<Isar>();
    Set<String> manufacturers = {};

    if (type == 'modulo') {
      final modules = await isar.pvModules.where().findAll();
      manufacturers = modules.map((m) => m.manufacturer).toSet();
    } else {
      final inverters = await isar.inverters.where().findAll();
      manufacturers = inverters.map((i) => i.manufacturer).toSet();
    }

    if (!mounted || currentType != type) return;
    setState(() {
      _existingManufacturers = manufacturers.toList()..sort();
    });
  }

  void _initControllers() {
    final fields = [
      'brand', 'model', 'weight',
      'powerWp', 'efficiency', 'length', 'width', 'vOc', 'iSc', 'vMp', 'iMp',
      'maxSystemVoltage', 'tempCoefVoc', 'tempCoefIsc', 'tempCoefPmax',
      'minOpTempMod', 'maxOpTempMod', 'fuseCurrent', 'physWarranty', 'effWarranty', 'effLoss',
      'nomPowerKw', 'maxInPowerKw', 'maxEff', 'euroEff', 'mpptCount',
      'totalDcInputs', 'mpptCurrents', 'mpptIscCurrents',
      'maxInVolts', 'nomVoltsDc', 'startVolts', 'minMpptVolts', 'maxMpptVolts',
      'maxInCurrPerMppt', 'maxIsc', 'maxOutCurr', 'nomVoltsAc', 'dimensions',
      'minOpTempInv', 'maxOpTempInv', 'protDegree', 'warrantyYrs'
    ];
    for (var f in fields) {
      _ctrl[f] = TextEditingController();
    }
    _setDefaults();
  }

  void _setDefaults() {
    _ctrl['maxSystemVoltage']?.text = '1500';
    _ctrl['minOpTempMod']?.text = '-40';
    _ctrl['maxOpTempMod']?.text = '85';
    _ctrl['fuseCurrent']?.text = '25';
    _ctrl['physWarranty']?.text = '12';
    _ctrl['effWarranty']?.text = '25';
    _ctrl['effLoss']?.text = '15';
    
    _ctrl['minOpTempInv']?.text = '-25';
    _ctrl['maxOpTempInv']?.text = '60';
    _ctrl['protDegree']?.text = 'IP65';
    _ctrl['warrantyYrs']?.text = '10';
  }

  void _fillExistingEquipment() {
    void put(String field, Object? value) {
      if (value != null) _ctrl[field]!.text = value.toString();
    }
    final module = widget.moduleToEdit;
    if (module != null) {
      put('brand', module.manufacturer);
      put('model', module.modelName);
      put('powerWp', module.powerWp);
      put('efficiency', module.efficiency);
      put('length', module.length);
      put('width', module.width);
      put('weight', module.weight);
      put('vOc', module.vOc);
      put('iSc', module.iSc);
      put('vMp', module.vMp);
      put('iMp', module.iMp);
      put('maxSystemVoltage', module.maxSystemVoltage);
      put('tempCoefVoc', module.tempCoefVoc);
      put('tempCoefIsc', module.tempCoefIsc);
      put('tempCoefPmax', module.tempCoefPmax);
      put('minOpTempMod', module.minOperatingTemp);
      put('maxOpTempMod', module.maxOperatingTemp);
      put('fuseCurrent', module.fuseCurrent);
      put('physWarranty', module.physicalWarranty);
      put('effWarranty', module.efficiencyWarranty);
      put('effLoss', module.efficiencyLoss);
      _modCellTech = module.cellTechnology;
      _modBifacial = module.isBifacial;
      _modTier1 = module.isTier1;
    }
    final inverter = widget.inverterToEdit;
    if (inverter != null) {
      put('brand', inverter.manufacturer);
      put('model', inverter.modelName);
      put('nomPowerKw', inverter.nominalPowerKw);
      put('maxInPowerKw', inverter.maxInputPowerKw);
      put('maxEff', inverter.maxEfficiency * 100);
      put('euroEff', inverter.euroEfficiency * 100);
      put('mpptCount', inverter.mpptCount);
      final config = inverter.mpptConfiguration;
      put('totalDcInputs', config?.totalDcInputs);
      put('mpptCurrents', config?.inputCurrentsA?.join('/'));
      put('mpptIscCurrents', config?.shortCircuitCurrentsA?.join('/'));
      put('maxInVolts', inverter.maxInputVoltage);
      put('nomVoltsDc', inverter.nominalVoltageDc);
      put('startVolts', inverter.startVoltage);
      put('minMpptVolts', inverter.minMpptVoltage);
      put('maxMpptVolts', inverter.maxMpptVoltage);
      put('maxInCurrPerMppt', inverter.maxInputCurrentPerMppt);
      put('maxIsc', inverter.maxShortCircuitCurrent);
      put('maxOutCurr', inverter.maxOutputCurrent);
      put('nomVoltsAc', inverter.nominalVoltageAc);
      put('dimensions', inverter.dimensions);
      put('weight', inverter.weight);
      put('minOpTempInv', inverter.minOperatingTemp);
      put('maxOpTempInv', inverter.maxOperatingTemp);
      put('protDegree', inverter.protectionDegree);
      put('warrantyYrs', inverter.warrantyYears);
      _invType = inverter.inverterType;
      _invGridConn = inverter.gridConnection;
      _invHybrid = inverter.isHybrid;
    }
  }

  @override
  void dispose() {
    _brandFocusNode.dispose();
    for (var c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isProcessingQueue = _pendingAiModels.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isProcessingQueue),
              const SizedBox(height: 15),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'modulo', label: Text('Módulo'), icon: Icon(Icons.wb_sunny)),
                  ButtonSegment(value: 'inversor', label: Text('Inversor'), icon: Icon(Icons.inventory_2)),
                ],
                selected: {type},
                // [MODIFICADO] Chama _onTypeChanged para atualizar a lista de fabricantes ao trocar de aba
                onSelectionChanged: isProcessingQueue || _isSaving || _editing ?
                    null : (val) => _onTypeChanged(val.first),
              ),
              const SizedBox(height: 20),

              if (!isProcessingQueue && !_editing) _buildAIActions(),
              if (isProcessingQueue) _buildImportQueue(),
              const Divider(height: 30),

              _buildSectionTitle("Informações Básicas"),
              
              // [MODIFICADO] Chamada do novo widget de Fabricante com Autocomplete
              _buildManufacturerField(),
              
              _buildTextField("Modelo", 'model'),
              
              if (type == 'modulo') ..._buildModuleFields(),
              if (type == 'inversor') ..._buildInverterFields(),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving || _isLoadingAi ? null : _saveAndNext,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55)),
                child: Text(_isSaving
                    ? 'Salvando...'
                    : _editing ? 'ATUALIZAR EQUIPAMENTO'
                    : isProcessingQueue
                        ? 'REVISAR E SALVAR (${_pendingAiModels.length} restante(s))'
                        : 'SALVAR NO BANCO'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // [ADICIONADO] Função para gerenciar a troca de tipo e recarregar fabricantes
  void _onTypeChanged(String newType) {
    setState(() => type = newType);
    _loadManufacturers();
  }

  // RawAutocomplete utiliza diretamente o controller do formulário.
  // Isso evita divergência ao preencher o fabricante via IA ou selecionar
  // um fabricante já cadastrado.
  Widget _buildManufacturerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) => RawAutocomplete<String>(
          textEditingController: _ctrl['brand'],
          focusNode: _brandFocusNode,
          optionsBuilder: (value) {
            if (value.text.trim().isEmpty) {
              return const Iterable<String>.empty();
            }
            return _existingManufacturers.where((manufacturer) =>
                manufacturer.toLowerCase().contains(value.text.toLowerCase()));
          },
          onSelected: (value) => _ctrl['brand']!.text = value,
          fieldViewBuilder: (context, textController, focusNode, onSubmit) =>
              TextFormField(
            controller: textController,
            focusNode: focusNode,
            decoration: _inputDecoration('Fabricante *'),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Informe o fabricante.'
                : null,
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: SizedBox(
                width: constraints.maxWidth,
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: options
                      .map((option) => ListTile(
                            title: Text(option),
                            onTap: () => onSelected(option),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isProcessingQueue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isProcessingQueue ? 'Revisando Fila da IA' :
              _editing ? 'Editar Equipamento' : 'Novo Equipamento',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (isProcessingQueue)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _isSaving ? null : () => setState(() {
              _pendingAiModels.clear();
              _totalAiModels = 0;
              _savedAiModels = 0;
              _clearManualForm();
            }),
            tooltip: "Cancelar Fila",
          )
      ],
    );
  }

  void _clearManualForm() {
    _manualEditedFields.clear();
    _aiAuditWarnings = {};
    for (final controller in _ctrl.values) {
      controller.clear();
    }
    _setDefaults();
    type = widget.initialType;
    _modCellTech = CellTechnology.topcon;
    _modBifacial = false;
    _modTier1 = false;
    _invType = InverterType.string;
    _invGridConn = GridConnection.triphasic;
    _invHybrid = false;
  }

  Widget _buildAIActions() {
    return _isLoadingAi
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton.icon(
            onPressed: _readDatasheetWithAI,
            icon: const Icon(Icons.document_scanner),
            label: const Text("Importar datasheet PDF com IA"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.purple.shade600,
              minimumSize: const Size.fromHeight(45),
            ),
          );
  }

  String _queueKey(Object item) {
    if (item is AiExtractedModule) {
      return EquipmentCatalog.key(item.manufacturer, item.modelName);
    }
    final inv = item as AiExtractedInverter;
    return EquipmentCatalog.key(inv.manufacturer, inv.modelName);
  }

  bool _isRegistered(Object item) {
    final key = _queueKey(item);
    return item is AiExtractedModule
        ? _registeredModuleKeys.contains(key)
        : _registeredInverterKeys.contains(key);
  }

  String _typedQueueKey(Object item) =>
      (item is AiExtractedModule ? 'module:' : 'inverter:') + _queueKey(item);

  Widget _buildImportQueue() {
    final currentNumber = _totalAiModels - _pendingAiModels.length + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisando $currentNumber de $_totalAiModels: '
          '${_pendingAiModels.length} modelo(s) pendente(s)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Confira cada valor extraído. Campos não identificados ficam '
          'em branco; complete os obrigatórios antes de salvar. '
          '$_aiProviderDescription',
          style: const TextStyle(fontSize: 12),
        ),
        if (_pendingAiModels.first is AiExtractedInverter &&
            (_pendingAiModels.first as AiExtractedInverter)
                    .hasAsymmetricMpptCurrents)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Atenção: correntes diferentes por MPPT: '
              '${(_pendingAiModels.first as AiExtractedInverter).mpptInputCurrentsA!.join(' / ')} A. '
              'O catálogo preserva os limites individuais; os campos '
              'escalares usam o MENOR limite somente para cálculos legados.',
              style: const TextStyle(color: Colors.deepOrange),
            ),
          ),
        if (_aiAuditWarnings.containsKey(
            AiDatasheetSemanticAuditor.key(_pendingAiModels.first)))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auditoria do datasheet:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                for (final warning in _aiAuditWarnings[
                    AiDatasheetSemanticAuditor.key(_pendingAiModels.first)]!)
                  Text('• $warning',
                      style: const TextStyle(color: Colors.deepOrange)),
              ],
            ),
          ),
        if (_manualEditedFields.isNotEmpty)
          Text('REVISADO MANUALMENTE: ${_manualEditedFields.join(', ')}',
              style: const TextStyle(color: Colors.green)),
        const Text('Estados: EXTRAÍDO DA FONTE = valor conferido; '
            'NÃO CONFIRMADO = revisar no PDF; INCONSISTENTE = divergência; '
            'REVISADO MANUALMENTE = campo alterado no formulário.',
            style: TextStyle(fontSize: 11)),
        if (_isRegistered(_pendingAiModels.first))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'JÁ CADASTRADO: fabricante e modelo encontrados no banco. '
              'O PDF foi lido normalmente. Pule este registro para não '
              'substituir os dados existentes.',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 125),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _pendingAiModels.length,
            itemBuilder: (context, index) {
              final item = _pendingAiModels[index];
              final manufacturer = item is AiExtractedModule
                  ? item.manufacturer
                  : (item as AiExtractedInverter).manufacturer;
              final modelName = item is AiExtractedModule
                  ? item.modelName
                  : (item as AiExtractedInverter).modelName;
              final registered = _isRegistered(item);
              final duplicatedInPdf = _pendingAiModels
                  .take(index)
                  .any((previous) => _typedQueueKey(previous) ==
                      _typedQueueKey(item));
              final gaps = item is AiExtractedModule
                  ? AiEquipmentRefinement.missingModuleFields(item).length
                  : AiEquipmentRefinement.missingInverterFields(
                      item as AiExtractedInverter).length;
              final suffix = registered
                  ? ' — JÁ CADASTRADO'
                  : duplicatedInPdf ? ' — REPETIDO NO PDF' : '';
              final pending = gaps == 0
                  ? '' : ' — $gaps campo(s) não confirmado(s)';
              return Text(
                '${index == 0 ? '▶ ' : '• '}$manufacturer — $modelName '
                '(${item is AiExtractedModule ? 'Módulo' : 'Inversor'})$suffix$pending',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (registered || duplicatedInPdf)
                    ? const TextStyle(color: Colors.deepOrange)
                    : null,
              );
            },
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: _isSaving ? null : _importAllAiModels,
          icon: const Icon(Icons.library_add_check),
          label: const Text('IMPORTAR TODOS (SE COMPLETOS)'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isSaving ? null : _skipCurrentAiModel,
          icon: const Icon(Icons.skip_next),
          label: const Text('Pular este modelo sem salvar'),
        ),
      ],
    );
  }

  Future<void> _importAllAiModels() async {
    if (_isSaving || _pendingAiModels.isEmpty) return;
    final modules = <PvModule>[];
    final inverters = <Inverter>[];
    final incomplete = <String>[];
    final seenInPdf = <String>{};
    var duplicates = 0;
    for (final item in _pendingAiModels) {
      if (_isRegistered(item) ||
          !seenInPdf.add(_typedQueueKey(item))) {
        duplicates++;
        continue;
      }
      final auditIssues = _aiAuditWarnings[
          AiDatasheetSemanticAuditor.key(item)] ?? const <String>[];
      if (auditIssues.isNotEmpty) {
        final label = item is AiExtractedModule
            ? item.modelName : (item as AiExtractedInverter).modelName;
        incomplete.add('$label: revisão documental obrigatória '
            '(${auditIssues.length} aviso(s))');
        continue;
      }
      if (item is AiExtractedModule) {
        final issues = AiEquipmentMapper.moduleProblems(item);
        if (issues.isNotEmpty) {
          incomplete.add('${item.modelName}: ${issues.join(', ')}');
        } else {
          modules.add(AiEquipmentMapper.module(item));
        }
      } else if (item is AiExtractedInverter) {
        final issues = AiEquipmentMapper.inverterProblems(item);
        if (issues.isNotEmpty) {
          incomplete.add('${item.modelName}: ${issues.join(', ')}');
        } else {
          inverters.add(AiEquipmentMapper.inverter(item));
        }
      }
    }

    if (modules.isEmpty && inverters.isEmpty && incomplete.isEmpty) {
      _showError('Nenhum modelo novo para importar: $duplicates já existe(m) '
          'ou está(ão) repetido(s) no PDF.');
      return;
    }
    if (incomplete.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Revise os modelos incompletos'),
          content: SingleChildScrollView(
            child: Text('A importação em lote não salva cadastros incompletos. '
                'Revise estes modelos individualmente:\n\n'
                '${incomplete.take(15).join('\n')}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar importação em lote'),
        content: Text('Adicionar ${modules.length} módulo(s) e '
            '${inverters.length} inversor(es)? '
            'Os dados serão usados como a IA os extraiu, sem aplicar '
            'eventuais edições ainda não salvas no formulário. '
            'Confirme as especificações do PDF antes de prosseguir. '
            '$duplicates duplicado(s) identificado(s) e ignorado(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final report = await EquipmentCatalog(getIt<Isar>()).importMany(
        modules: modules,
        inverters: inverters,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${report.totalAdded} equipamento(s) incluído(s); '
            '${report.duplicatesSkipped} duplicado(s) ignorado(s).'),
      ));
    } catch (error) {
      _showError('Falha na importação em lote: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _skipCurrentAiModel() {
    if (_pendingAiModels.isEmpty) return;
    setState(() {
      _pendingAiModels.removeAt(0);
      if (_pendingAiModels.isNotEmpty) {
        _loadCurrentAiModel();
      } else {
        _totalAiModels = 0;
        _savedAiModels = 0;
        _clearManualForm();
      }
    });
    _loadManufacturers();
  }

  List<Widget> _buildModuleFields() {
    return [
      Row(
        children: [
          Expanded(child: _buildTextField("Potência (Wp)", 'powerWp')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Eficiência (%)", 'efficiency')),
        ],
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<CellTechnology>(
        key: ValueKey('cell_${_modCellTech.name}_${_pendingAiModels.length}'),
        initialValue: _modCellTech,
        decoration: _inputDecoration("Tecnologia da Célula"),
        items: CellTechnology.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
        onChanged: (val) => setState(() => _modCellTech = val!),
      ),
      SwitchListTile(title: const Text("É Bifacial?"), value: _modBifacial, onChanged: (v) => setState(() => _modBifacial = v)),
      SwitchListTile(title: const Text("Tier 1?"), value: _modTier1, onChanged: (v) => setState(() => _modTier1 = v)),
      
      _buildSectionTitle("Físico e Dimensões"),
      Row(
        children: [
          Expanded(child: _buildTextField("Altura (mm)", 'length')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Largura (mm)", 'width')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Peso (kg)", 'weight')),
        ],
      ),

      _buildSectionTitle("Parâmetros Elétricos (STC)"),
      Row(
        children: [
          Expanded(child: _buildTextField("Voc (V)", 'vOc')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Isc (A)", 'iSc')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildTextField("Vmp (V)", 'vMp')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Imp (A)", 'iMp')),
        ],
      ),

      _buildSectionTitle("Coeficientes de Temperatura (%/°C)"),
      Row(
        children: [
          Expanded(child: _buildTextField("Pmax", 'tempCoefPmax')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Voc", 'tempCoefVoc')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Isc", 'tempCoefIsc')),
        ],
      ),
      _buildSectionTitle('Limites e Garantias'),
      Row(children: [
        Expanded(child: _buildTextField('Tensão Máx do Sistema (V)', 'maxSystemVoltage')),
        const SizedBox(width: 10),
        Expanded(child: _buildTextField('Fusível Máx (A)', 'fuseCurrent')),
      ]),
      Row(children: [
        Expanded(child: _buildTextField('Temp. Mín (°C)', 'minOpTempMod')),
        const SizedBox(width: 10),
        Expanded(child: _buildTextField('Temp. Máx (°C)', 'maxOpTempMod')),
      ]),
      Row(children: [
        Expanded(child: _buildTextField('Garantia Física (anos)', 'physWarranty')),
        const SizedBox(width: 10),
        Expanded(child: _buildTextField('Garantia Eficiência (anos)', 'effWarranty')),
      ]),
      _buildTextField('Perda de Eficiência Final (%)', 'effLoss'),
    ];
  }

  List<Widget> _buildInverterFields() {
    return [
      const SizedBox(height: 10),

      DropdownButtonFormField<InverterType>(
        key: ValueKey('inv_${_invType.name}_${_pendingAiModels.length}'),
        initialValue: _invType,
        decoration: _inputDecoration("Tipo de Inversor"),
        items: InverterType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
        onChanged: (val) => setState(() => _invType = val!),
      ),

      const SizedBox(height: 20),

      DropdownButtonFormField<GridConnection>(
        key: ValueKey('grid_${_invGridConn.name}_${_pendingAiModels.length}'),
        initialValue: _invGridConn,
        decoration: _inputDecoration("Conexão com a Rede"),
        items: GridConnection.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
        onChanged: (val) => setState(() => _invGridConn = val!),
      ),

      const SizedBox(height: 5),

      SwitchListTile(title: const Text("É Híbrido?"), value: _invHybrid, onChanged: (v) => setState(() => _invHybrid = v)),
      
      _buildSectionTitle("Potência e Eficiência"),
      
      Row(
        children: [
          Expanded(child: _buildTextField("Nominal (kW)", 'nomPowerKw')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Max Entrada (kW)", 'maxInPowerKw')),
        ],
      ),

      Row(
        children: [
          Expanded(child: _buildTextField("Eficiência Máx (%)", 'maxEff')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Eficiência Euro (%)", 'euroEff')),
        ],
      ),

      _buildSectionTitle("Entrada DC (MPPT)"),
      if (_mpptTopologyWarning() != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _mpptTopologyWarning()!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      Row(
        children: [
          Expanded(child: _buildTextField("Qtd MPPTs", 'mpptCount')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Entradas CC totais", 'totalDcInputs')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Tensão Máx (V)", 'maxInVolts')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildTextField("Tensão Início (V)", 'startVolts')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Tensão Nominal CC (V)", 'nomVoltsDc')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildTextField("MPPT Mín (V)", 'minMpptVolts')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("MPPT Máx (V)", 'maxMpptVolts')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildTextField("Corrente Máx/MPPT (A)", 'maxInCurrPerMppt')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Corrente Isc (A)", 'maxIsc')),
        ],
      ),

      _buildTextField('Correntes Impp por MPPT (A, ex.: 32/16)', 'mpptCurrents'),
      _buildTextField('Correntes Isc por MPPT (A, ex.: 40/20)', 'mpptIscCurrents'),
      const Text(
        'As correntes por MPPT são preservadas. Os campos escalares acima '
        'representam os menores limites para cálculos legados.',
      ),
      _buildSectionTitle("Saída AC"),
      Row(
        children: [
          Expanded(child: _buildTextField("Tensão Nominal (V)", 'nomVoltsAc')),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Corrente Máx (A)", 'maxOutCurr')),
        ],
      ),
      _buildSectionTitle('Físico, Ambiental e Garantia'),
      _buildTextField('Dimensões (mm)', 'dimensions'),
      Row(children: [
        Expanded(child: _buildTextField('Peso (kg)', 'weight')),
        const SizedBox(width: 10),
        Expanded(child: _buildTextField('Grau de Proteção', 'protDegree')),
      ]),
      Row(children: [
        Expanded(child: _buildTextField('Temp. Mín (°C)', 'minOpTempInv')),
        const SizedBox(width: 10),
        Expanded(child: _buildTextField('Temp. Máx (°C)', 'maxOpTempInv')),
      ]),
      _buildTextField('Garantia (anos)', 'warrantyYrs'),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ),
    );
  }

  String? _mpptTopologyWarning() =>
      EquipmentInputValidator.validateMpptTopology(
        mpptCount: _ctrl['mpptCount']!.text,
        totalDcInputs: _ctrl['totalDcInputs']!.text,
        mpptCurrents: _ctrl['mpptCurrents']!.text,
        mpptIscCurrents: _ctrl['mpptIscCurrents']!.text,
      );

  Widget _buildTextField(String label, String ctrlKey) {
    final required = EquipmentInputValidator.isRequired(
      ctrlKey, isModule: type == 'modulo',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ctrl[ctrlKey],
        decoration: _inputDecoration(required ? '$label *' : label),
        keyboardType: EquipmentInputValidator.isTextField(ctrlKey)
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (_) {
          if (_pendingAiModels.isNotEmpty ||
              const {'mpptCount', 'totalDcInputs',
                'mpptCurrents', 'mpptIscCurrents'}.contains(ctrlKey)) {
            setState(() {
              if (_pendingAiModels.isNotEmpty) {
                _manualEditedFields.add(ctrlKey);
              }
            });
          }
        },
        validator: (value) => EquipmentInputValidator.validate(
          key: ctrlKey,
          value: value,
          isModule: type == 'modulo',
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Future<void> _readDatasheetWithAI() async {
    if (_isLoadingAi || _isSaving) return;
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (selection == null || selection.files.isEmpty || !mounted) return;
    final file = selection.files.single;
    if (file.size > 10 * 1024 * 1024) {
      _showError('O arquivo PDF deve ter no máximo 10 MB.');
      return;
    }
    if (file.path == null) {
      _showError('Não foi possível acessar o PDF selecionado.');
      return;
    }
    final aiService = DatasheetAiService();
    // Aviso Base64 somente quando o PDF é realmente transmitido ao provedor.
    if (!aiService.useOllama && file.size > 5 * 1024 * 1024) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('PDF grande'),
          content: Text('O documento tem '
              '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB. '
              'Em Base64, o envio fica cerca de 33% maior e pode ultrapassar '
              'os limites dos modelos gratuitos. É recomendado comprimir '
              'imagens do PDF SEM prejudicar as tabelas técnicas. '
              'Deseja continuar com o arquivo original?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() => _isLoadingAi = true);
    var failureContext = 'na extração do datasheet';
    try {
      // Com Ollama ativo o PDF é processado apenas na própria máquina;
      // com Ollama desativado, preserva o fluxo original OpenRouter.
      final result = await aiService.extractEquipmentData(file.path!);
      if (!mounted) return;
      // Evita ler uma coleção não relacionada: um PDF de módulos não
      // depende da integridade dos registros de inversores e vice-versa.
      failureContext = 'na consulta de duplicatas no banco Isar';
      final isar = getIt<Isar>();
      final modulesAlready = result.modules.isEmpty
          ? <PvModule>[]
          : await isar.pvModules.where().findAll();
      final invertersAlready = result.inverters.isEmpty
          ? <Inverter>[]
          : await isar.inverters.where().findAll();
      if (!mounted) return;
      setState(() {
        _aiAuditWarnings = result.auditWarnings;
        _aiProviderDescription = aiService.providerDescription;
        _manualEditedFields.clear();
        _registeredModuleKeys
          ..clear()
          ..addAll(modulesAlready.map((m) =>
              EquipmentCatalog.key(m.manufacturer, m.modelName)));
        _registeredInverterKeys
          ..clear()
          ..addAll(invertersAlready.map((i) =>
              EquipmentCatalog.key(i.manufacturer, i.modelName)));
        _pendingAiModels
          ..clear()
          ..addAll(result.modules)
          ..addAll(result.inverters);
        _totalAiModels = _pendingAiModels.length;
        _savedAiModels = 0;
        _loadCurrentAiModel();
      });
      _loadManufacturers();
      final missingFields = result.modules.fold<int>(
          0, (sum, m) =>
              sum + AiEquipmentRefinement.missingModuleFields(m).length) +
          result.inverters.fold<int>(
              0, (sum, i) =>
                  sum + AiEquipmentRefinement.missingInverterFields(i).length);
      final invalid = result.inverters.where(
          (i) => AiEquipmentMapper.inverterProblems(i).isNotEmpty).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_pendingAiModels.length} modelo(s) identificado(s), '
            '$missingFields campo(s) não confirmado(s) após refinamento; '
            '$invalid inversor(es) exigem revisão.'),
      ));
    } catch (error) {
      if (!mounted) return;
      _showError('Falha $failureContext: $error');
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  void _loadCurrentAiModel() {
    if (_pendingAiModels.isEmpty) return;
    _manualEditedFields.clear();
    final data = _pendingAiModels.first;

    for (final controller in _ctrl.values) {
      controller.clear();
    }
    void put(String field, Object? value) {
      if (value != null) _ctrl[field]!.text = value.toString();
    }

    if (data is AiExtractedModule) {
      type = 'modulo';
      put('brand', data.manufacturer);
      put('model', data.modelName);
      put('powerWp', data.powerWp == 0 ? null : data.powerWp);
      put('efficiency', data.efficiency == 0 ? null : data.efficiency);
      put('vOc', data.vOc == 0 ? null : data.vOc);
      put('iSc', data.iSc == 0 ? null : data.iSc);
      put('vMp', data.vMp == 0 ? null : data.vMp);
      put('iMp', data.iMp == 0 ? null : data.iMp);
      put('length', data.length);
      put('width', data.width);
      put('weight', data.weight);
      put('tempCoefPmax', data.tempCoefPmax);
      put('tempCoefVoc', data.tempCoefVoc);
      put('tempCoefIsc', data.tempCoefIsc);
      put('maxSystemVoltage', data.maxSystemVoltage);
      put('minOpTempMod', data.minOperatingTemp);
      put('maxOpTempMod', data.maxOperatingTemp);
      put('fuseCurrent', data.fuseCurrent);
      put('physWarranty', data.physicalWarranty);
      put('effWarranty', data.efficiencyWarranty);
      put('effLoss', data.efficiencyLoss);
      _modCellTech = _parseCellTechnology(data.cellTechnology);
      _modBifacial = data.isBifacial;
      // Tier 1 é informação de classificação, não inferir se ausente.
      _modTier1 = data.isTier1 ?? false;
    } else if (data is AiExtractedInverter) {
      type = 'inversor';
      put('brand', data.manufacturer);
      put('model', data.modelName);
      put('nomPowerKw', data.nominalPowerKw == 0 ? null : data.nominalPowerKw);
      put('maxInPowerKw', data.maxInputPowerKw);
      // O cadastro usa percentuais na UI e frações no Isar.
      put('maxEff', _asPercent(data.maxEfficiency));
      put('euroEff', _asPercent(data.euroEfficiency));
      put('mpptCount', data.mpptCount);
      put('totalDcInputs', data.totalDcInputs);
      put('mpptCurrents', data.mpptInputCurrentsA?.join('/'));
      put('mpptIscCurrents', data.mpptShortCircuitCurrentsA?.join('/'));
      put('maxInVolts', data.maxInputVoltage);
      put('nomVoltsDc', data.nominalVoltageDc);
      put('startVolts', data.startVoltage);
      put('minMpptVolts', data.minMpptVoltage);
      put('maxMpptVolts', data.maxMpptVoltage);
      put('maxInCurrPerMppt', data.maxInputCurrentPerMppt);
      put('maxIsc', data.maxShortCircuitCurrent);
      put('maxOutCurr', data.maxOutputCurrent);
      put('nomVoltsAc', data.nominalVoltageAc);
      put('dimensions', data.dimensions);
      put('weight', data.weight);
      put('minOpTempInv', data.minOperatingTemp);
      put('maxOpTempInv', data.maxOperatingTemp);
      put('protDegree', data.protectionDegree);
      put('warrantyYrs', data.warrantyYears);
      _invType = _parseInverterType(data.inverterType);
      _invGridConn = _parseGridConnection(data.gridConnection);
      _invHybrid = data.isHybrid;
    }
  }

  double? _asPercent(double? value) {
    if (value == null) return null;
    return value <= 1 ? value * 100 : value;
  }

  void _showError(String message) {
    if (!mounted) return;
    // SnackBars do Scaffold principal ficam atrás do modal de equipamento.
    // O diálogo usa o Navigator raiz e permanece legível acima do formulário.
    EquipmentErrorDialog.show(context, message);
  }

  Future<void> _saveAndNext() async {
    if (_isSaving || _isLoadingAi) return;
    if (!_formKey.currentState!.validate()) {
      _showError('Revise os campos obrigatórios e os números informados.');
      return;
    }
    if (_pendingAiModels.isNotEmpty &&
        _isRegistered(_pendingAiModels.first)) {
      _showError('Este fabricante e modelo já está cadastrado. '
          'Use Pular este modelo ou edite o registro existente.');
      return;
    }
    final brand = _ctrl['brand']!.text.trim();
    final model = _ctrl['model']!.text.trim();
    if (brand.isEmpty || model.isEmpty) {
      _showError('Informe o fabricante e o modelo.');
      return;
    }

    double number(String key) =>
        double.tryParse(_ctrl[key]!.text.trim().replaceAll(',', '.')) ?? 0;
    int integer(String key) =>
        double.tryParse(_ctrl[key]!.text.trim().replaceAll(',', '.'))
            ?.toInt() ?? 0;

    if (type == 'inversor') {
      final minVoltage = number('minMpptVolts');
      final maxVoltage = number('maxMpptVolts');
      final inputVoltage = number('maxInVolts');
      if (minVoltage > maxVoltage || maxVoltage > inputVoltage) {
        _showError('Corrija o MPPT: mínimo ≤ máximo ≤ tensão de entrada.');
        return;
      }
    }

    List<double>? currents(String key) {
      final source = _ctrl[key]!.text.trim();
      if (source.isEmpty) return null;
      return source.split(RegExp(r'[/;]'))
          .map((v) => double.parse(v.trim().replaceAll(',', '.')))
          .toList();
    }
    InverterMpptConfiguration? mpptConfig;
    if (type == 'inversor') {
      final candidate = InverterMpptConfiguration(
        inputCurrentsA: currents('mpptCurrents'),
        shortCircuitCurrentsA: currents('mpptIscCurrents'),
        totalDcInputs: _ctrl['totalDcInputs']!.text.trim().isEmpty
            ? null : integer('totalDcInputs'),
      );
      final problems = candidate.validate(integer('mpptCount'));
      if (problems.isNotEmpty) {
        _showError(problems.join('; '));
        return;
      }
      if (candidate.hasDetails) mpptConfig = candidate;
    }
    if (_pendingAiModels.isNotEmpty) {
      final warnings = _aiAuditWarnings[
          AiDatasheetSemanticAuditor.key(_pendingAiModels.first)] ??
          const <String>[];
      if (warnings.isNotEmpty) {
        final approved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmar revisão técnica'),
            content: SingleChildScrollView(
              child: Text('Existem propriedades não confirmadas ou '
                  'corrigidas durante a auditoria. Confira com o PDF '
                  'antes de salvar:\n\n${warnings.join('\n')}\n\n'
                  'Deseja confirmar manualmente este cadastro?'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Continuar revisando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Revisei e confirmo'),
              ),
            ],
          ),
        );
        if (approved != true || !mounted) return;
      }
    }
    setState(() => _isSaving = true);
    try {
      final catalog = EquipmentCatalog(getIt<Isar>());
      if (type == 'modulo') {
        final record = PvModule(
          manufacturer: brand,
          modelName: model,
          powerWp: integer('powerWp'),
          efficiency: number('efficiency'),
          cellTechnology: _modCellTech,
          isBifacial: _modBifacial,
          isTier1: _modTier1,
          length: number('length'),
          width: number('width'),
          weight: number('weight'),
          vOc: number('vOc'),
          iSc: number('iSc'),
          vMp: number('vMp'),
          iMp: number('iMp'),
          maxSystemVoltage: number('maxSystemVoltage'),
          tempCoefVoc: number('tempCoefVoc'),
          tempCoefIsc: number('tempCoefIsc'),
          tempCoefPmax: number('tempCoefPmax'),
          minOperatingTemp: number('minOpTempMod'),
          maxOperatingTemp: number('maxOpTempMod'),
          fuseCurrent: number('fuseCurrent'),
          physicalWarranty: integer('physWarranty'),
          efficiencyWarranty: integer('effWarranty'),
          efficiencyLoss: number('effLoss'),
        );
        if (widget.moduleToEdit != null) {
          record.id = widget.moduleToEdit!.id;
          await catalog.updateModule(record);
        } else {
          await catalog.addModule(record);
        }
      } else {
        final record = Inverter(
          manufacturer: brand,
          modelName: model,
          inverterType: _invType,
          nominalPowerKw: number('nomPowerKw'),
          maxInputPowerKw: number('maxInPowerKw'),
          maxEfficiency: number('maxEff') / 100,
          euroEfficiency: number('euroEff') / 100,
          mpptCount: integer('mpptCount'),
          mpptConfigurationJson: mpptConfig?.encode(),
          maxInputVoltage: number('maxInVolts'),
          nominalVoltageDc: number('nomVoltsDc'),
          startVoltage: number('startVolts'),
          minMpptVoltage: number('minMpptVolts'),
          maxMpptVoltage: number('maxMpptVolts'),
          maxInputCurrentPerMppt: mpptConfig?.inputCurrentsA == null
              ? number('maxInCurrPerMppt')
              : mpptConfig!.inputCurrentsA!
                  .reduce((a, b) => a < b ? a : b),
          maxShortCircuitCurrent: mpptConfig?.shortCircuitCurrentsA == null
              ? number('maxIsc')
              : mpptConfig!.shortCircuitCurrentsA!
                  .reduce((a, b) => a < b ? a : b),
          gridConnection: _invGridConn,
          maxOutputCurrent: number('maxOutCurr'),
          nominalVoltageAc: number('nomVoltsAc'),
          dimensions: _ctrl['dimensions']!.text.trim(),
          weight: number('weight'),
          minOperatingTemp: number('minOpTempInv'),
          maxOperatingTemp: number('maxOpTempInv'),
          protectionDegree: _ctrl['protDegree']!.text.trim(),
          isHybrid: _invHybrid,
          warrantyYears: integer('warrantyYrs'),
        );
        if (widget.inverterToEdit != null) {
          record.id = widget.inverterToEdit!.id;
          await catalog.updateInverter(record);
        } else {
          await catalog.addInverter(record);
        }
      }
      if (!mounted) return;
      if (_pendingAiModels.isNotEmpty) {
        setState(() {
          final savedItem = _pendingAiModels.removeAt(0);
          final key = _queueKey(savedItem);
          if (savedItem is AiExtractedModule) {
            _registeredModuleKeys.add(key);
          } else {
            _registeredInverterKeys.add(key);
          }
          _savedAiModels++;
          if (_pendingAiModels.isNotEmpty) {
            _loadCurrentAiModel();
          }
        });
        if (_pendingAiModels.isNotEmpty) {
          _loadManufacturers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$_savedAiModels salvo(s). '
                'Confira o próximo modelo da fila.')),
          );
          return;
        }
      }
      final saved = _savedAiModels;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved > 0
            ? '$saved equipamento(s) importado(s) e salvo(s).'
            : _editing ? 'Equipamento atualizado com sucesso.'
            : 'Equipamento salvo no banco local.')),
      );
    } catch (error) {
      _showError('Não foi possível salvar: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  CellTechnology _parseCellTechnology(String tech) {
    final lower = tech.toLowerCase();
    if (lower.contains('perc')) return CellTechnology.perc;
    if (lower.contains('n-type') || lower.contains('ntype') || lower.contains('topcon')) return CellTechnology.topcon;
    if (lower.contains('hjt')) return CellTechnology.hjt;
    if (lower.contains('bsf')) return CellTechnology.alBSF;
    return CellTechnology.topcon;
  }

  InverterType _parseInverterType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('micro')) return InverterType.microInverter;
    if (lower.contains('optim')) return InverterType.optimizer;
    return InverterType.string;
  }

  GridConnection _parseGridConnection(String conn) {
    final lower = conn.toLowerCase();
    if (lower.contains('tri')) return GridConnection.triphasic;
    if (lower.contains('bi')) return GridConnection.biphasic;
    return GridConnection.monophasic;
  }
}