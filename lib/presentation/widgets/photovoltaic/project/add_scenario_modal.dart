import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../domain/entities/pv_module.dart';
import '../../../../../domain/entities/solar_scenario.dart';
import '../../../../../domain/enums/ground_type.dart';
import '../../../../../domain/enums/module_orientation.dart';
import '../../../../domain/entities/obstacle_config.dart';
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
  final distanceToGroundController = TextEditingController(text: "0.015");
  final arrayCountController = TextEditingController(text: "1");
  
  final obsHeightController = TextEditingController(text: "0.0");
  final obsDistanceController = TextEditingController(text: "5.0");
  final obsWidthController = TextEditingController(text: "0.0");
  final obsAzimuthController = TextEditingController(text: "0");
  final quantityController = TextEditingController(text: "1");

  final _formKey = GlobalKey<FormState>();

  ModuleOrientation selectedOrientation = ModuleOrientation.portrait;
  GroundType selectedGround = GroundType.grass;
  bool hasObstacle = true;
  String arrayDirection = "Direita";
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

  // Métodos de Ajuda (Helper Dialogs) movidos para dentro da classe
  void _showObstacleHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Como medir a distância?"),
        content: const Text("Meça do obstáculo até a borda mais próxima do painel. Não meça até o centro."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _showAzimuthHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Azimute do Obstáculo"),
        content: const Text("Aponte a bússola do celular para o centro do obstáculo a partir do local da instalação."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _confirmAndAdd() {
    List<SolarScenario> newScenarios = [];
    int scenarioBaseIndex = widget.currentScenarioCount + 1;

    double larguraModuloEmMetros = (selectedOrientation == ModuleOrientation.portrait 
      ? modalSelectedModule!.width 
      : modalSelectedModule!.length);
  
    if (larguraModuloEmMetros > 100) { // Se for maior que 100, certamente está em mm
      larguraModuloEmMetros /= 1000;
    }
    
    double passo = larguraModuloEmMetros + 0.03; // 0.03m = 3cm de grampo/espaço

    double dBase = double.tryParse(obsDistanceController.text) ?? 0.0;
    double azBase = double.tryParse(obsAzimuthController.text) ?? 0.0;
    
    int totalParaGerar = int.tryParse(quantityController.text) ?? 1;

    int loops = hasObstacle ? totalParaGerar : 1;

    for (int i = 0; i < loops; i++) {
      double dNova = dBase;
      double azNovo = azBase;

      if (hasObstacle && i > 0) {
        double deslocamento = i * passo;
        
        // Convertemos o Azimute do Obstáculo para radianos
        double radBase = azBase * (pi / 180);
        
        // Coordenadas Polares -> Cartesianas (Referência: Placa 1)
        // x: Leste-Oeste, y: Norte-Sul
        double xBase = dBase * sin(radBase);
        double yBase = dBase * cos(radBase);

        // O array se move para a Direita ou Esquerda
        // Importante: "Direita" em relação a quem olha para as placas de frente (Norte)
        double multiplicador = (arrayDirection == "Direita") ? 1 : -1;
        
        // O deslocamento da placa altera a posição RELATIVA do obstáculo
        // Se a placa anda para a direita, o obstáculo "anda" para a esquerda no eixo X
        double xNovo = xBase - (deslocamento * multiplicador);
        
        // Nova Distância e Novo Azimute (Polares novamente)
        dNova = sqrt(pow(xNovo, 2) + pow(yBase, 2));
        
        // atan2 retorna o ângulo correto em todos os quadrantes
        azNovo = atan2(xNovo, yBase) * (180 / pi);
        
        // Normaliza para 0-360°
        if (azNovo < 0) azNovo += 360;
      }

      newScenarios.add(
        SolarScenario(
          id: hasObstacle 
              ? 'Cenário $scenarioBaseIndex (Placa ${i + 1}) @ ${azimuthController.text}°, ${inclinationController.text}°' 
              : 'Cenário $scenarioBaseIndex @ ${azimuthController.text}°, ${inclinationController.text}°',
          city: widget.city,
          state: widget.state,
          inclination: double.tryParse(inclinationController.text) ?? 0.0,
          azimuth: double.tryParse(azimuthController.text) ?? 0.0,
          albedo: selectedGround.albedo,
          distanceToGround: double.tryParse(distanceToGroundController.text) ?? 0.015,
          module: modalSelectedModule!,
          orientation: selectedOrientation,
          quantityPvModule: hasObstacle ? 1 : totalParaGerar,
          obstacle: hasObstacle ? ObstacleConfig(
            height: double.tryParse(obsHeightController.text) ?? 0.0,
            distance: dNova,
            azimuthReference: azNovo,
            width: double.tryParse(obsWidthController.text) ?? 0.0,
          ) : null,
        ),
      );
    }

    widget.onScenariosAdded(newScenarios);
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
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a inclinação' : null,
              ),
              SolarInputField(
                controller: azimuthController,
                label: 'Azimute (°)',
                icon: Icons.explore_outlined,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe o azimute' : null,
              ),
              SolarInputField(
                controller: distanceToGroundController,
                label: 'Distância do Solo (m)',
                icon: Icons.height,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a distância ao solo' : null,
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
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a quantidade';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Mínimo de 1 placa';
                  return null;
                },
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
              const Divider(height: 30),
              // Obstáculo
              SwitchListTile(
                title: const Text("Simular Sombreamento Individual?"),
                subtitle: const Text("Ative se houver árvores, prédios ou chaminés próximos ao arranjo."),
                value: hasObstacle,
                onChanged: (val) => setState(() => hasObstacle = val),
              ),
              if (hasObstacle) ...[
                const Divider(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Dados do Obstáculo e Arranjo",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ),                
                const SizedBox(height: 30),
                SolarInputField(
                  controller: obsHeightController,
                  label: 'Altura (m)',
                  icon: Icons.vertical_align_top,
                  validator: (v) => (hasObstacle && (v == null || v.isEmpty)) ? 'Informe a altura' : null,
                ),
                SolarInputField(
                  controller: obsWidthController,
                  label: 'Largura (m)',
                  icon: Icons.width_full,
                  validator: (v) => (hasObstacle && (v == null || v.isEmpty)) ? 'Informe a largura' : null,
                ),
                SolarInputField(
                  controller: obsAzimuthController,
                  label: 'Azimute do Obstáculo (°)',
                  icon: Icons.navigation,
                  onHelpTap: _showAzimuthHelp,
                  validator: (v) => (hasObstacle && (v == null || v.isEmpty)) ? 'Informe o azimute do obs.' : null,
                ),
                SolarInputField(
                  controller: obsDistanceController,
                  label: 'Distância (m)',
                  icon: Icons.space_bar,
                  onHelpTap: _showObstacleHelp,
                  validator: (v) => (hasObstacle && (v == null || v.isEmpty)) ? 'Informe a distância' : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: arrayDirection,
                    decoration: const InputDecoration(
                      labelText: 'Direção da Fileira (Fileira Cresce para:)',
                      helperText: "Define a posição das placas 2, 3... em relação à placa 1",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.multiple_stop), // Ícone de direção/movimento
                    ),
                    items: const [
                      DropdownMenuItem(value: "Direita", child: Text("Direita")),
                      DropdownMenuItem(value: "Esquerda", child: Text("Esquerda")),
                    ],
                    onChanged: (val) => setState(() => arrayDirection = val!),
                  ),
                ),                
                const SizedBox(height: 20),                
                const Text(
                  "* O sistema usará a quantidade definida acima para calcular o impacto do obstáculo em cada placa da fileira.",
                  style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text("* A 'Placa 1' é a referência. Meça a distância do centro do obstáculo até a borda desta primeira placa. As demais placas serão posicionadas automaticamente para a ${arrayDirection.toLowerCase()} a partir dela.",
                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
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