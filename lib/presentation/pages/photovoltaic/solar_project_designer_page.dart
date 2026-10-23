import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import '../../../core/injection/injection.dart';
import '../../../domain/entities/inverter.dart';
import '../../../domain/entities/pv_module.dart';
import '../../../domain/entities/solar_array.dart';
import '../../../domain/entities/solar_project.dart';
import '../../../domain/entities/solar_scenario.dart';
import '../../../domain/entities/solar_system.dart';
import '../../../domain/services/solar_reference_service.dart';
import '../../../domain/enums/cell_technology.dart';
import '../../bloc/solar_hsp_bloc.dart';
import '../../bloc/solar_hsp_state.dart';
import '../../widgets/photovoltaic/project/add_scenario_modal.dart';
import '../../widgets/photovoltaic/project/project_summary_header.dart';
import '../../widgets/photovoltaic/project/sizing_suggestion_card.dart';
import '../../widgets/photovoltaic/project/solar_system_card.dart';
import 'quote_details_page.dart';

class SolarProjectDesignerPage extends StatefulWidget {
  final SolarProject project;
  const SolarProjectDesignerPage({super.key, required this.project});

  @override
  State<SolarProjectDesignerPage> createState() => _SolarProjectDesignerPageState();
}

class _SolarProjectDesignerPageState extends State<SolarProjectDesignerPage> {
  List<SolarScenario> configuredScenarios = [];
  List<SolarSystem> systems = [];
  List<PvModule> allModules = [];
  List<String> manufacturers = [];
  String? selectedInverterManufacturer;
  Inverter? selectedInverter;
  List<Inverter> allInverters = [];

  @override
  void initState() {
    super.initState();

    _loadInitialData();

    final placeholderModule = PvModule(
      manufacturer: "Referência",
      modelName: "Padrão 1W",
      powerWp: 1,
      cellTechnology: CellTechnology.topcon,
      efficiency: 22.8,
      vOc: 46.2,
      iSc: 16.71,
      vMp: 38.6,
      iMp: 15.94,
      tempCoefVoc: -0.3,
      tempCoefIsc: 0.045,
      tempCoefPmax: -0.3,
      length: 2382,
      width: 1134,
      weight: 32.6,
      isBifacial: false,
    );

    // Criamos um cenário com esse módulo
    final placeholderScenario = SolarScenario(
      id: "placeholder",
      module: placeholderModule,
      inclination: 0, // Plano horizontal para pegar o HSP puro
      azimuth: 0, 
      city: widget.project.city, 
      state: widget.project.state,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SolarHspBloc>().add(
          CalculateHspEvent(
            widget.project.latitude, 
            widget.project.longitude, 
            [placeholderScenario],
          ),
        );
      }
    });
  }

  void _showInverterPicker() {
    // Reinicia as seleções temporárias ao abrir
    selectedInverterManufacturer = null;
    selectedInverter = null;

    // Extrai fabricantes únicos de inversores
    final inverterManufacturers = allInverters.map((i) => i.manufacturer).toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder para atualizar o modal internamente
          builder: (context, setModalState) {
            // Filtra os modelos baseados no fabricante selecionado
            final filteredInverters = allInverters
                .where((i) => i.manufacturer == selectedInverterManufacturer)
                .toList();

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Configurar Novo Sistema", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  
                  // 1. SELEÇÃO DE FABRICANTE
                  const Text("Fabricante do Inversor", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedInverterManufacturer,
                    hint: const Text("Selecione o fabricante"),
                    items: inverterManufacturers.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedInverterManufacturer = val;
                        selectedInverter = null; // Reseta o modelo se mudar o fabricante
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 2. SELEÇÃO DE MODELO (Só aparece se o fabricante for escolhido)
                  if (selectedInverterManufacturer != null) ...[
                    const Text("Modelo do Inversor", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    DropdownButton<Inverter>(
                      isExpanded: true,
                      value: selectedInverter,
                      hint: const Text("Selecione o modelo"),
                      items: filteredInverters.map((inv) => 
                        DropdownMenuItem(value: inv, child: Text("${inv.modelName} (${inv.nominalPowerKw}kW)"))
                      ).toList(),
                      onChanged: (val) {
                        setModalState(() => selectedInverter = val);
                      },
                    ),
                  ],

                  const Spacer(),

                  // BOTÃO DE CONFIRMAÇÃO
                  ElevatedButton(
                    onPressed: selectedInverter == null ? null : () {
                      setState(() {
                        systems.add(SolarSystem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: "Sistema ${systems.length + 1}",
                          inverter: selectedInverter!,
                          arrays: [],
                        ));
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text("CRIAR SISTEMA"),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _onCalculatePressed() {
    // 1. Validamos se existe pelo menos um sistema com módulos
    if (systems.isEmpty || systems.every((s) => s.arrays.isEmpty)) {
      setState(() {
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adicione um inversor e pelo menos um grupo de módulos!")),
      );
      return; // Agora o return acontece APÓS limpar os dados
    }
    
    widget.project.systems = systems;

    // 2. Criamos uma lista única de cenários para o BLoC calcular
    // O BLoC precisa de List<SolarScenario> para processar a radiação
    final List<SolarScenario> scenariosToCalculate = [];

    for (var system in systems) {
      for (var array in system.arrays) {
        scenariosToCalculate.add(SolarScenario(
          id: array.solarScenario.id,
          module: array.solarScenario.module,
          inclination: array.solarScenario.inclination,
          azimuth: array.solarScenario.azimuth, 
          city: widget.project.city, 
          state: widget.project.state,
          albedo: array.solarScenario.albedo,
          distanceToGround: array.solarScenario.distanceToGround,
          orientation: array.solarScenario.orientation,
          quantityPvModule: array.solarScenario.quantityPvModule,
          obstacle: array.solarScenario.obstacle
        ));
      }
    }

    // 3. Disparamos o BLoC com todos os cenários de todos os sistemas
    context.read<SolarHspBloc>().add(CalculateHspEvent(
          widget.project.latitude,
          widget.project.longitude,
          scenariosToCalculate,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Calculando geração de todos os sistemas...")),
    );
  }
  
  void _showAddArrayModal(SolarSystem system) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal suba com o teclado
      backgroundColor: Colors.white, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // O AddScenarioModal que você enviou já tem seu próprio Padding e ScrollView
        return FractionallySizedBox(
          heightFactor: 0.9, // Ocupa 90% da tela para evitar bugs de visualização
          child: AddScenarioModal(
            city: widget.project.city,
            state: widget.project.state,
            availableModules: allModules,
            manufacturers: manufacturers,
            currentScenarioCount: system.arrays.length,
            defaultLatitude: widget.project.latitude,
            onScenariosAdded: (newScenarios) {
              setState(() {
                for (var scenario in newScenarios) {
                  system.arrays.add(SolarArray(
                    solarScenario: scenario,
                    solarScenarioResult: null,
                  ));
                }
              });

              _onCalculatePressed();
            },
          ),
        );
      },
    );
  }
  
  Future<void> _loadInitialData() async {
    final isar = getIt<Isar>();
    
    final modules = await isar.pvModules.where().findAll();
    final inverters = await isar.inverters.where().findAll();

    setState(() {
      allModules = modules;
      allInverters = inverters;
      manufacturers = modules.map((m) => m.manufacturer).toSet().toList();
      if (inverters.isNotEmpty) selectedInverter = inverters.first;
    });
  }
  
  Widget _buildOrcamentoPage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailsPage(project: widget.project),
            ),
          );
        },
        icon: const Icon(Icons.calculate),
        label: const Text(
          "DETALHAR ORÇAMENTO",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarHspBloc, SolarHspState>(
      // O listener observa as mudanças de estado
      listener: (context, state) {
        if (state is SolarHspSuccess) {
          setState(() {
            SolarReferenceService.updateProjectReference(widget.project, state.result);
            final isPlaceholder = state.result.results.any((r) => r.id == 'placeholder');
            if (!isPlaceholder) {
              // Um resultado atrasado nunca deve substituir dados de outro array.
              final byId = {for (final result in state.result.results) result.id: result};
              for (final system in systems) {
                for (final array in system.arrays) {
                  array.solarScenarioResult = byId[array.solarScenario.id];
                }
              }
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Projeto: ${widget.project.clientName}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [            
              ProjectSummaryHeader(project: widget.project),

              const SizedBox(height: 20),

              // Agora o lastCalculationResult que o Listener salvou é passado para cá
              SizingSuggestionCard(
                project: widget.project, 
                onDetailsTap: () {},
              ),

              const SizedBox(height: 20),
              const Divider(),

              if (systems.isEmpty) ...[
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Agora, adicione os inversores e módulos abaixo:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                ...systems.map((s) => SolarSystemCard(
                  system: s,
                  referenceHorizontalHsp: widget.project.referenceHspHorizontal?.annualAverage,
                  onDeleteSystem: (){
                    setState(() => systems.remove(s));
                    _onCalculatePressed();
                  },
                  onAddArray: () => _showAddArrayModal(s),
                  onRemoveArray: (array){
                    setState(() => s.arrays.remove(array));
                    _onCalculatePressed();
                  },
                  onMpptChanged: (arrayAlvo, novoIndice) {
                    setState(() { arrayAlvo.mpptIndex = novoIndice;});
                    _onCalculatePressed();
                  },
                )),
              ],

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _showInverterPicker,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("ADICIONAR NOVO INVERSOR (SISTEMA)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              ),

              if (systems.isNotEmpty && systems.any((s) => s.arrays.isNotEmpty)) ...[
                const Divider(height: 40),
                _buildOrcamentoPage(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}