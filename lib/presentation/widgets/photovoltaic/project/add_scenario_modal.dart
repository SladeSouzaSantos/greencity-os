import 'package:flutter/material.dart';
import '../../../../domain/entities/pv_module.dart';
import '../../../../domain/entities/solar_scenario.dart';
import '../../../../domain/enums/ground_type.dart';
import '../../../../domain/enums/module_orientation.dart';
import '../../../../domain/services/hsp_input_validator.dart';
import 'solar_input_field.dart';

class AddScenarioModal extends StatefulWidget {
  final String city;
  final String state;
  final List<PvModule> availableModules;
  final List<String> manufacturers;
  final int currentScenarioCount;
  final double defaultLatitude;
  final Function(List<SolarScenario>) onScenariosAdded;

  final String? initialManufacturer;
  final PvModule? initialModule;

  const AddScenarioModal({
    super.key,
    required this.city,
    required this.state,
    required this.availableModules,
    required this.manufacturers,
    required this.currentScenarioCount,
    required this.defaultLatitude,
    required this.onScenariosAdded,
    this.initialManufacturer,
    this.initialModule,
  });

  @override
  State<AddScenarioModal> createState() => _AddScenarioModalState();
}

class _AddScenarioModalState extends State<AddScenarioModal> {
  late TextEditingController inclinationController;
  final azimuthController = TextEditingController(text: "0");
  final distanceToGroundController = TextEditingController(text: "0.15");
  final arrayCountController = TextEditingController(text: "1");
  
  final quantityController = TextEditingController(text: "1");

  final _formKey = GlobalKey<FormState>();

  ModuleOrientation selectedOrientation = ModuleOrientation.portrait;
  GroundType selectedGround = GroundType.grass;
  String? modalSelectedBrand;
  PvModule? modalSelectedModule;
  List<PvModule> modalFilteredModules = [];
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    // Inicializa a inclinação com base na latitude recebida
    inclinationController = TextEditingController(
      text: "${widget.defaultLatitude.abs().toInt()}",
    );

    if (widget.initialManufacturer != null) {
      modalSelectedBrand = widget.initialManufacturer;
      
      // Filtra os modelos da marca memorizada
      modalFilteredModules = widget.availableModules
          .where((m) => m.manufacturer == modalSelectedBrand)
          .toList();

      // Define o modelo memorizado
      modalSelectedModule = widget.initialModule;
    }
  }

  @override
  void dispose() {
    inclinationController.dispose();
    azimuthController.dispose();
    distanceToGroundController.dispose();
    arrayCountController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  /// HSP base remains free of legacy obstacles. Each new set of
  /// modules is one SolarArray; modules become individually editable in 3D.
  void _confirmAndAdd() {
    final count = int.parse(quantityController.text.trim());
    final scenario = SolarScenario(
      id: 'Cenário ${widget.currentScenarioCount + 1} @ '
          '${azimuthController.text}°, ${inclinationController.text}°',
      city: widget.city,
      state: widget.state,
      inclination: HspInputValidator.parseNumber(
          inclinationController.text)!,
      azimuth: HspInputValidator.parseNumber(azimuthController.text)!,
      albedo: selectedGround.albedo,
      distanceToGround: HspInputValidator.parseNumber(
          distanceToGroundController.text)!,
      module: modalSelectedModule!,
      orientation: selectedOrientation,
      quantityPvModule: count,
    );
    widget.onScenariosAdded([scenario]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey, // Vincula o formulário à chave global
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Novo Cenário',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SolarInputField(
                controller: inclinationController,
                label: 'Inclinação (°)',
                icon: Icons.architecture,
                validator: HspInputValidator.validateInclination,
              ),
              SolarInputField(
                controller: azimuthController,
                label: 'Azimute (°)',
                icon: Icons.explore_outlined,
                validator: HspInputValidator.validateAzimuth,
              ),
              SolarInputField(
                controller: distanceToGroundController,
                label: 'Altura do centro do módulo (m)',
                icon: Icons.height,
                validator: HspInputValidator.validateModuleCenterHeight,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<GroundType>(
                initialValue: selectedGround,
                validator: (v) => v == null ? 'Selecione o tipo de solo' : null,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Solo (Albedo)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.terrain),
                ),
                items: GroundType.values
                    .map((type) => DropdownMenuItem(
                        value: type, child: Text("${type.label} (${type.albedo})")))
                    .toList(),
                onChanged: (val) => setState(() => selectedGround = val!),
              ),
              const Divider(height: 30),
              const Text('Configuração do Módulo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: modalSelectedBrand,
                validator: (v) => v == null ? 'Selecione o fabricante' : null,
                hint: const Text("Fabricante"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.factory),
                ),
                items: widget.manufacturers
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (brand) {
                  setState(() {
                    modalSelectedBrand = brand;
                    modalFilteredModules = widget.availableModules
                        .where((m) => m.manufacturer == brand)
                        .toList();
                    modalSelectedModule = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<PvModule>(
                initialValue: modalSelectedModule,
                validator: (v) => v == null ? 'Selecione o modelo do módulo' : null,
                hint: const Text("Modelo do Módulo"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_input_component),
                ),
                items: modalFilteredModules
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text("${m.modelName} (${m.powerWp}Wp)")))
                    .toList(),
                onChanged: (module) => setState(() => modalSelectedModule = module),
              ),
              const SizedBox(height: 10),              
              SolarInputField(
                label: "Quantidade de Módulos",
                controller: quantityController, // Vinculando o controller
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  // Atualiza a variável interna para uso imediato se necessário
                  quantity = int.tryParse(val) ?? 1;
                },
                validator: HspInputValidator.validateQuantity,
              ),
              const SizedBox(height: 15),
              // Orientação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Orientação:"),
                  SegmentedButton<ModuleOrientation>(
                    segments: const [
                      ButtonSegment(
                          value: ModuleOrientation.portrait,
                          label: Text('Retrato'),
                          icon: Icon(Icons.stay_current_portrait)),
                      ButtonSegment(
                          value: ModuleOrientation.landscape,
                          label: Text('Paisagem'),
                          icon: Icon(Icons.stay_current_landscape)),
                    ],
                    selected: {selectedOrientation},
                    onSelectionChanged: (val) =>
                        setState(() => selectedOrientation = val.first),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'O HSP de referência será calculado sem obstáculos. '
                  'Adicione e posicione obstáculos na Análise 3D, '
                  'após configurar o inversor e os módulos.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              // Botão Confirmar
              ElevatedButton(
                onPressed: () {
                  // Valida todos os campos dentro do Form
                  if (_formKey.currentState!.validate()) {
                    _confirmAndAdd();
                  }
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}