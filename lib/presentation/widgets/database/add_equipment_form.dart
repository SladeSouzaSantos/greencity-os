import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../../core/injection/injection.dart';
import '../../../core/services/ia_service.dart';
import '../../../data/models/ai_extraction_result_model.dart';
import '../../../domain/entities/inverter.dart';
import '../../../domain/entities/pv_module.dart';
import '../../../domain/enums/cell_technology.dart';
import '../../../domain/enums/grid_connection.dart';
import '../../../domain/enums/inverter_type.dart';

class AddEquipmentForm extends StatefulWidget {
  const AddEquipmentForm({super.key});

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

  List<dynamic> _pendingAiModels = [];
  bool _isLoadingAi = false;

  // [ADICIONADO] Lista para armazenar fabricantes que já existem no banco
  List<String> _existingManufacturers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadManufacturers(); // [ADICIONADO] Carrega fabricantes ao iniciar
  }

  // [ADICIONADO] Busca fabricantes no Isar dependendo do tipo selecionado
  Future<void> _loadManufacturers() async {
    final isar = getIt<Isar>();
    Set<String> manufacturers = {};

    if (type == 'modulo') {
      final modules = await isar.pvModules.where().findAll();
      manufacturers = modules.map((m) => m.manufacturer).toSet();
    } else {
      final inverters = await isar.inverters.where().findAll();
      manufacturers = inverters.map((i) => i.manufacturer).toSet();
    }

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
                onSelectionChanged: isProcessingQueue ? null : (val) => _onTypeChanged(val.first),
              ),
              const SizedBox(height: 20),

              if (!isProcessingQueue) _buildAIActions(),
              if (!isProcessingQueue) const Divider(height: 30),

              _buildSectionTitle("Informações Básicas"),
              
              // [MODIFICADO] Chamada do novo widget de Fabricante com Autocomplete
              _buildManufacturerField(),
              
              _buildTextField("Modelo", 'model'),
              
              if (type == 'modulo') ..._buildModuleFields(),
              if (type == 'inversor') ..._buildInverterFields(),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveAndNext,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55)),
                child: Text(isProcessingQueue ? "SALVAR E PRÓXIMO (${_pendingAiModels.length} na fila)" : "SALVAR NO BANCO"),
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
    setState(() {
      type = newType;
      _loadManufacturers();
    });
  }

  // [ADICIONADO] Widget de Fabricante usando Autocomplete
  Widget _buildManufacturerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) => Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _existingManufacturers.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _ctrl['brand']?.text = selection;
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            // Sincroniza o controller interno do Autocomplete com o nosso _ctrl['brand']
            // Isso é vital para quando a IA preenche o campo
            if (_ctrl['brand']!.text.isNotEmpty && textController.text != _ctrl['brand']!.text) {
              textController.text = _ctrl['brand']!.text;
            }

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: _inputDecoration("Fabricante"),
              onChanged: (value) {
                _ctrl['brand']?.text = value; // Garante que o valor digitado vá para o mapa de controllers
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
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
            onPressed: () => setState(() => _pendingAiModels.clear()),
            tooltip: "Cancelar Fila",
          )
      ],
    );
  }

  Widget _buildAIActions() {
    return _isLoadingAi
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton.icon(
            onPressed: _readDatasheetWithAI,
            icon: const Icon(Icons.document_scanner),
            label: const Text("Ler Datasheet com Gemini (IA)"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.purple.shade600,
              minimumSize: const Size.fromHeight(45),
            ),
          );
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
        initialValue: _modCellTech, // [MODIFICADO] initialValue para value para refletir mudanças da IA
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
    ];
  }

  List<Widget> _buildInverterFields() {
    return [
      const SizedBox(height: 10),

      DropdownButtonFormField<InverterType>(
        initialValue: _invType, // [MODIFICADO]
        decoration: _inputDecoration("Tipo de Inversor"),
        items: InverterType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
        onChanged: (val) => setState(() => _invType = val!),
      ),

      const SizedBox(height: 20),

      DropdownButtonFormField<GridConnection>(
        initialValue: _invGridConn, // [MODIFICADO]
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

  Widget _buildTextField(String label, String ctrlKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ctrl[ctrlKey],
        decoration: _inputDecoration(label),
        keyboardType: TextInputType.text,
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
    // 1. Abre o seletor de arquivos
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true, // IMPORTANTE: Para Web ou se o path falhar
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isLoadingAi = true);

    try {
      final String? filePath = result.files.single.path;
      
      if (filePath == null) {
        throw Exception("Não foi possível obter o caminho do arquivo.");
      }

      final iaService = getIt<IAService>();
      
      // [CORREÇÃO] Certifique-se que o nome do método é o mesmo do seu IAService
      // No seu arquivo está 'analyzeDatasheet'
      final extraction = await iaService.analyzeDatasheet(filePath);

      if (extraction == null) {
        throw Exception("A IA não retornou dados válidos.");
      }

      setState(() {
        // Como o seu analyzeDatasheet retorna Map<String, dynamic>, 
        // vamos converter para a fila ou preencher direto
        _pendingAiModels = [extraction]; 
        
        // Se a IA detectou que é um inversor (ex: campo power em kW), 
        // você pode precisar ajustar a lógica de 'type' aqui
        _loadCurrentAiModel();
        _loadManufacturers(); 
      });

    } catch (e) {
      debugPrint("Erro detalhado: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }
  
  void _loadCurrentAiModel() {
    if (_pendingAiModels.isEmpty) return;
    
    final data = _pendingAiModels.first;
    
    for (var c in _ctrl.values) { c.clear(); }
    _setDefaults();

    if (data is AiExtractedModule) {
      _ctrl['brand']?.text = data.manufacturer;
      _ctrl['model']?.text = data.modelName;
      _ctrl['powerWp']?.text = data.powerWp.toString();
      _ctrl['efficiency']?.text = data.efficiency.toString();
      _ctrl['vOc']?.text = data.vOc.toString();
      _ctrl['iSc']?.text = data.iSc.toString();
      _ctrl['vMp']?.text = data.vMp.toString();
      _ctrl['iMp']?.text = data.iMp.toString();
      _ctrl['length']?.text = data.length?.toString() ?? '';
      _ctrl['width']?.text = data.width?.toString() ?? '';
      _ctrl['weight']?.text = data.weight?.toString() ?? '';
      
      _modCellTech = _parseCellTechnology(data.cellTechnology);
      _modBifacial = data.isBifacial;
    } 
    else if (data is AiExtractedInverter) {
      _ctrl['brand']?.text = data.manufacturer;
      _ctrl['model']?.text = data.modelName;
      _ctrl['nomPowerKw']?.text = data.nominalPowerKw.toString();
      _ctrl['maxInPowerKw']?.text = data.maxInputPowerKw?.toString() ?? '';
      _ctrl['mpptCount']?.text = data.mpptCount?.toString() ?? '';
      _ctrl['maxInVolts']?.text = data.maxInputVoltage?.toString() ?? '';
      _ctrl['maxOutCurr']?.text = data.maxOutputCurrent?.toString() ?? '';
      _ctrl['maxEff']?.text = data.maxEfficiency?.toString() ?? '';
      _ctrl['weight']?.text = data.weight?.toString() ?? '';
      
      _invType = _parseInverterType(data.inverterType);
      _invGridConn = _parseGridConnection(data.gridConnection);
      _invHybrid = data.isHybrid;
    }
  }

  void _saveAndNext() async {
    if (_ctrl['brand']!.text.isEmpty || _ctrl['model']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha Fabricante e Modelo!")));
      return;
    }

    final isar = getIt<Isar>();

    double pDouble(String key) => double.tryParse(_ctrl[key]!.text.replaceAll(',', '.')) ?? 0.0;
    int pInt(String key) => int.tryParse(_ctrl[key]!.text) ?? 0;

    try {
      await isar.writeTxn(() async {
        if (type == 'modulo') {
          final m = PvModule(
            manufacturer: _ctrl['brand']!.text.trim(),
            modelName: _ctrl['model']!.text.trim(),
            powerWp: pInt('powerWp'),
            efficiency: pDouble('efficiency'),
            cellTechnology: _modCellTech,
            isBifacial: _modBifacial,
            isTier1: _modTier1,
            length: pDouble('length'),
            width: pDouble('width'),
            weight: pDouble('weight'),
            vOc: pDouble('vOc'),
            iSc: pDouble('iSc'),
            vMp: pDouble('vMp'),
            iMp: pDouble('iMp'),
            maxSystemVoltage: pDouble('maxSystemVoltage'),
            tempCoefVoc: pDouble('tempCoefVoc'),
            tempCoefIsc: pDouble('tempCoefIsc'),
            tempCoefPmax: pDouble('tempCoefPmax'),
            minOperatingTemp: pDouble('minOpTempMod'),
            maxOperatingTemp: pDouble('maxOpTempMod'),
            fuseCurrent: pDouble('fuseCurrent'),
            physicalWarranty: pInt('physWarranty'),
            efficiencyWarranty: pInt('effWarranty'),
            efficiencyLoss: pDouble('effLoss'),
          );
          await isar.pvModules.put(m);
        } else {
          final inv = Inverter(
            manufacturer: _ctrl['brand']!.text.trim(),
            modelName: _ctrl['model']!.text.trim(),
            inverterType: _invType,
            nominalPowerKw: pDouble('nomPowerKw'),
            maxInputPowerKw: pDouble('maxInPowerKw'),
            maxEfficiency: pDouble('maxEff'),
            euroEfficiency: pDouble('euroEff'),
            mpptCount: pInt('mpptCount'),
            maxInputVoltage: pDouble('maxInVolts'),
            nominalVoltageDc: pDouble('nomVoltsDc'),
            startVoltage: pDouble('startVolts'),
            minMpptVoltage: pDouble('minMpptVolts'),
            maxMpptVoltage: pDouble('maxMpptVolts'),
            maxInputCurrentPerMppt: pDouble('maxInCurrPerMppt'),
            maxShortCircuitCurrent: pDouble('maxIsc'),
            gridConnection: _invGridConn,
            maxOutputCurrent: pDouble('maxOutCurr'),
            nominalVoltageAc: pDouble('nomVoltsAc'),
            dimensions: _ctrl['dimensions']!.text,
            weight: pDouble('weight'),
            minOperatingTemp: pDouble('minOpTempInv'),
            maxOperatingTemp: pDouble('maxOpTempInv'),
            protectionDegree: _ctrl['protDegree']!.text,
            isHybrid: _invHybrid,
            warrantyYears: pInt('warrantyYrs'),
          );
          await isar.inverters.put(inv);
        }
      });

      // [ADICIONADO] Recarrega lista de fabricantes após salvar um novo
      await _loadManufacturers();

      if (_pendingAiModels.isNotEmpty) {
        _pendingAiModels.removeAt(0);
        if (_pendingAiModels.isNotEmpty) {
          setState(() => _loadCurrentAiModel());
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo! Reagendando próximo...")));
          return; 
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Equipamento(s) salvo(s) com sucesso!")));
      }
    } catch (e) {
      debugPrint("Erro ao salvar no banco: $e");
    }
  }

  CellTechnology _parseCellTechnology(String tech) {
    final lower = tech.toLowerCase();
    if (lower.contains('perc')) return CellTechnology.perc;
    if (lower.contains('n-type') || lower.contains('ntype') || lower.contains('topcon')) return CellTechnology.topcon;
    if (lower.contains('hjt')) return CellTechnology.hjt;
    return CellTechnology.topcon;
  }

  InverterType _parseInverterType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('micro')) return InverterType.microInverter;
    return InverterType.string;
  }

  GridConnection _parseGridConnection(String conn) {
    return conn.toLowerCase().contains('tri') ? GridConnection.triphasic : GridConnection.monophasic;
  }
}