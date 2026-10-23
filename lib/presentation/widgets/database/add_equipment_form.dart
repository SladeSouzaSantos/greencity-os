import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../../core/injection/injection.dart';
import '../../../core/services/ia_service.dart';
import '../../../data/repositories/equipment_catalog.dart';
import '../../../data/models/ai_extraction_result_model.dart';
import '../../../data/models/ai_equipment_mapper.dart';
import '../../../domain/entities/inverter.dart';
import '../../../domain/entities/pv_module.dart';
import '../../../domain/enums/cell_technology.dart';
import '../../../domain/enums/grid_connection.dart';
import '../../../domain/enums/inverter_type.dart';

class AddEquipmentForm extends StatefulWidget {
  final String initialType;

  const AddEquipmentForm({super.key, this.initialType = 'modulo'});

  @override
  State<AddEquipmentForm> createState() => _AddEquipmentFormState();
}

class _AddEquipmentFormState extends State<AddEquipmentForm> {
  String type = 'modulo';
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _ctrl = {};

  CellTechnology _modCellTech = CellTechnology.topcon;
  bool _modTier1 = true;
  bool _modBifacial = false;

  InverterType _invType = InverterType.string;
  GridConnection _invGridConn = GridConnection.triphasic;
  bool _invHybrid = false;

  final List<Object> _pendingAiModels = [];
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
    type = widget.initialType;
    _initControllers();
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
                onSelectionChanged: isProcessingQueue || _isSaving ? null : (val) => _onTypeChanged(val.first),
              ),
              const SizedBox(height: 20),

              if (!isProcessingQueue) _buildAIActions(),
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
          isProcessingQueue ? "Revisando Fila da IA" : "Novo Equipamento",
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
        const Text(
          'Confira cada valor extraído. Campos não identificados ficam '
          'em branco; complete os obrigatórios antes de salvar. '
          'O PDF foi enviado ao serviço Gemini.',
          style: TextStyle(fontSize: 12),
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
              return Text(
                '${index == 0 ? '▶ ' : '• '}$manufacturer — $modelName '
                '(${item is AiExtractedModule ? 'Módulo' : 'Inversor'})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    for (final item in _pendingAiModels) {
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
            'Modelos já cadastrados serão ignorados.'),
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
      Row(
        children: [
          Expanded(child: _buildTextField("Qtd MPPTs", 'mpptCount')),
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

  static const _moduleRequired = {
    'powerWp', 'efficiency', 'length', 'width', 'vOc', 'iSc', 'vMp', 'iMp',
  };
  static const _inverterRequired = {
    'nomPowerKw', 'maxInPowerKw', 'mpptCount', 'maxInVolts',
    'minMpptVolts', 'maxMpptVolts', 'maxInCurrPerMppt',
  };
  static const _integerFields = {
    'powerWp', 'mpptCount', 'physWarranty', 'effWarranty', 'warrantyYrs',
  };
  static const _textFields = {'dimensions', 'protDegree'};

  String? _validateEquipmentField(String key, String? raw) {
    if (_textFields.contains(key)) return null;
    final requiredKeys =
        type == 'modulo' ? _moduleRequired : _inverterRequired;
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return requiredKeys.contains(key) ? 'Campo obrigatório.' : null;
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite) return 'Número inválido.';
    if (_integerFields.contains(key) && parsed != parsed.roundToDouble()) {
      return 'Informe um número inteiro.';
    }
    if (requiredKeys.contains(key) && parsed <= 0) {
      return 'Informe um valor maior que zero.';
    }
    if (!key.startsWith('tempCoef') &&
        !key.startsWith('minOpTemp') &&
        !key.startsWith('maxOpTemp') &&
        parsed < 0) {
      return 'Valor não pode ser negativo.';
    }
    if ((key == 'efficiency' || key == 'maxEff' ||
         key == 'euroEff' || key == 'effLoss') && parsed > 100) {
      return 'Máximo de 100%.';
    }
    return null;
  }

  Widget _buildTextField(String label, String ctrlKey) {
    final requiredKeys = type == 'modulo'
        ? _moduleRequired : _inverterRequired;
    final required = requiredKeys.contains(ctrlKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ctrl[ctrlKey],
        decoration: _inputDecoration(required ? '$label *' : label),
        keyboardType: _textFields.contains(ctrlKey)
            ? TextInputType.text
            : const TextInputType.numberWithOptions(
                decimal: true, signed: true),
        validator: (v) => _validateEquipmentField(ctrlKey, v),
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
    setState(() => _isLoadingAi = true);
    try {
      // A execução é explícita: somente o arquivo selecionado é enviado.
      // IAService lê PDF em memória e devolve listas tipadas completas.
      final result = await IAService().extractEquipmentData(file.path!);
      if (!mounted) return;
      setState(() {
        _pendingAiModels
          ..clear()
          ..addAll(result.modules)
          ..addAll(result.inverters);
        _totalAiModels = _pendingAiModels.length;
        _savedAiModels = 0;
        _loadCurrentAiModel();
      });
      _loadManufacturers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_pendingAiModels.length} modelo(s) identificado(s). '
            'Confira cada registro antes de salvar.'),
      ));
    } catch (error) {
      if (!mounted) return;
      _showError('Falha na leitura do PDF: $error');
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  void _loadCurrentAiModel() {
    if (_pendingAiModels.isEmpty) return;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveAndNext() async {
    if (_isSaving || _isLoadingAi) return;
    if (!_formKey.currentState!.validate()) {
      _showError('Revise os campos obrigatórios e os números informados.');
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

    setState(() => _isSaving = true);
    try {
      final catalog = EquipmentCatalog(getIt<Isar>());
      if (type == 'modulo') {
        await catalog.addModule(PvModule(
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
        ));
      } else {
        await catalog.addInverter(Inverter(
          manufacturer: brand,
          modelName: model,
          inverterType: _invType,
          nominalPowerKw: number('nomPowerKw'),
          maxInputPowerKw: number('maxInPowerKw'),
          maxEfficiency: number('maxEff') / 100,
          euroEfficiency: number('euroEff') / 100,
          mpptCount: integer('mpptCount'),
          maxInputVoltage: number('maxInVolts'),
          nominalVoltageDc: number('nomVoltsDc'),
          startVoltage: number('startVolts'),
          minMpptVoltage: number('minMpptVolts'),
          maxMpptVoltage: number('maxMpptVolts'),
          maxInputCurrentPerMppt: number('maxInCurrPerMppt'),
          maxShortCircuitCurrent: number('maxIsc'),
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
        ));
      }
      if (!mounted) return;
      if (_pendingAiModels.isNotEmpty) {
        setState(() {
          _pendingAiModels.removeAt(0);
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