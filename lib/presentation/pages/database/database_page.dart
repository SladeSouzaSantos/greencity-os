import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../../../core/injection/injection.dart';
import '../../../../domain/entities/pv_module.dart';
import '../../../../domain/entities/inverter.dart';
import '../../../../data/repositories/equipment_catalog.dart';
import '../../widgets/database/add_equipment_form.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Banco de Dados Solar"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny), text: "Módulos"),
            Tab(icon: Icon(Icons.inventory_2), text: "Inversores"),
          ],
        ),
      ),
      // O segredo está em isolar as listas em Widgets que não morrem ao trocar de aba
      body: TabBarView(
        controller: _tabController,
        children: const [
          ModuleListWidget(),
          InverterListWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: const Text("Adicionar"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEquipmentForm(
        initialType: _tabController.index == 0 ? 'modulo' : 'inversor',
      ),
    );
  }
}


void _editEquipment(BuildContext context, {PvModule? module, Inverter? inverter}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AddEquipmentForm(
      initialType: module == null ? 'inversor' : 'modulo',
      moduleToEdit: module,
      inverterToEdit: inverter,
    ),
  );
}

Future<void> _viewEquipment(
  BuildContext context, {PvModule? module, Inverter? inverter}
) async {
  final List<MapEntry<String, String>> rows;
  final String title;
  String optionalNum(num n, String suffix) =>
      n == 0 ? 'Não informado' : '$n $suffix';
  if (module != null) {
    title = 'Módulo ${module.manufacturer} ${module.modelName}';
    rows = [
      MapEntry('Fabricante', module.manufacturer),
      MapEntry('Modelo', module.modelName),
      MapEntry('Potência STC', '${module.powerWp} Wp'),
      MapEntry('Eficiência', '${module.efficiency}%'),
      MapEntry('Tecnologia', module.cellTechnology.name),
      MapEntry('Bifacial', module.isBifacial ? 'Sim' : 'Não'),
      MapEntry('Tier 1', module.isTier1 ? 'Sim' : 'Não'),
      MapEntry('Altura', '${module.length} mm'),
      MapEntry('Largura', '${module.width} mm'),
      MapEntry('Peso', optionalNum(module.weight, 'kg')),
      MapEntry('Voc', '${module.vOc} V'),
      MapEntry('Isc', '${module.iSc} A'),
      MapEntry('Vmp', '${module.vMp} V'),
      MapEntry('Imp', '${module.iMp} A'),
      MapEntry('Tensão máxima', '${module.maxSystemVoltage} V'),
      MapEntry('Coef. Pmax', '${module.tempCoefPmax} %/°C'),
      MapEntry('Coef. Voc', '${module.tempCoefVoc} %/°C'),
      MapEntry('Coef. Isc', '${module.tempCoefIsc} %/°C'),
      MapEntry('Temperatura mínima', '${module.minOperatingTemp} °C'),
      MapEntry('Temperatura máxima', '${module.maxOperatingTemp} °C'),
      MapEntry('Fusível máximo', '${module.fuseCurrent} A'),
      MapEntry('Garantia física', optionalNum(module.physicalWarranty, 'anos')),
      MapEntry('Garantia eficiência', optionalNum(module.efficiencyWarranty, 'anos')),
      MapEntry('Degradação final', optionalNum(module.efficiencyLoss, '%')),
    ];
  } else if (inverter != null) {
    title = 'Inversor ${inverter.manufacturer} ${inverter.modelName}';
    rows = [
      MapEntry('Fabricante', inverter.manufacturer),
      MapEntry('Modelo', inverter.modelName),
      MapEntry('Tipo', inverter.inverterType.name),
      MapEntry('Conexão', inverter.gridConnection.name),
      MapEntry('Híbrido', inverter.isHybrid ? 'Sim' : 'Não'),
      MapEntry('Potência nominal CA', '${inverter.nominalPowerKw} kW'),
      MapEntry('Potência recomendada CC', '${inverter.maxInputPowerKw} kW'),
      MapEntry('Eficiência máxima', '${inverter.maxEfficiency * 100}%'),
      MapEntry('Eficiência europeia', optionalNum(inverter.euroEfficiency * 100, '%')),
      MapEntry('MPPTs', '${inverter.mpptCount}'),
      const MapEntry('Limitação da versão',
        'Uma única corrente por MPPT é armazenada. Se os rastreadores '
        'tiverem limites diferentes, confira a ficha original antes '
        'do dimensionamento.'),
      MapEntry('Tensão máxima CC', '${inverter.maxInputVoltage} V'),
      MapEntry('Tensão nominal CC', '${inverter.nominalVoltageDc} V'),
      MapEntry('Tensão inicial', '${inverter.startVoltage} V'),
      MapEntry('MPPT mínimo', '${inverter.minMpptVoltage} V'),
      MapEntry('MPPT máximo', '${inverter.maxMpptVoltage} V'),
      MapEntry('Corrente máxima MPPT', '${inverter.maxInputCurrentPerMppt} A'),
      MapEntry('Corrente Isc máxima', '${inverter.maxShortCircuitCurrent} A'),
      MapEntry('Tensão nominal CA', '${inverter.nominalVoltageAc} V'),
      MapEntry('Corrente máxima CA', '${inverter.maxOutputCurrent} A'),
      MapEntry('Dimensões', inverter.dimensions),
      MapEntry('Peso', optionalNum(inverter.weight, 'kg')),
      MapEntry('Temperatura mínima', '${inverter.minOperatingTemp} °C'),
      MapEntry('Temperatura máxima', '${inverter.maxOperatingTemp} °C'),
      MapEntry('Proteção', inverter.protectionDegree),
      MapEntry('Garantia', optionalNum(inverter.warrantyYears, 'anos')),
    ];
  } else {
    return;
  }

  final edit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in rows)
                ListTile(
                  dense: true,
                  title: Text(row.key),
                  subtitle: Text(row.value.isEmpty ? 'Não informado' : row.value),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
      ],
    ),
  );
  if (edit == true && context.mounted) {
    _editEquipment(context, module: module, inverter: inverter);
  }
}

// --- WIDGET DE MÓDULOS COM KEEPALIVE ---
Future<void> _deleteEquipment(
  BuildContext context, {
  required bool module,
  required int id,
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remover equipamento?'),
      content: Text('Excluir $name do banco local? Esta operação não pode ser desfeita.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final catalog = EquipmentCatalog(getIt<Isar>());
    if (module) {
      await catalog.deleteModule(id);
    } else {
      await catalog.deleteInverter(id);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Equipamento removido com sucesso.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Falha ao remover: $error')),
    );
  }
}

class ModuleListWidget extends StatefulWidget {
  const ModuleListWidget({super.key});

  @override
  State<ModuleListWidget> createState() => _ModuleListWidgetState();
}

// AutomaticKeepAliveClientMixin impede que a aba seja destruída ao sair dela
class _ModuleListWidgetState extends State<ModuleListWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context); // Obrigatório para o KeepAlive
    final isar = getIt<Isar>();

    return StreamBuilder<List<PvModule>>(
      stream: isar.pvModules.where().watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final modules = [...snapshot.data!]
          ..sort((a, b) => '${a.manufacturer} ${a.modelName}'
              .compareTo('${b.manufacturer} ${b.modelName}'));
        if (modules.isEmpty) {
          return const Center(child: Text('Nenhum módulo cadastrado. Use Adicionar.'));
        }
        return ListView.builder(
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final m = modules[index];
            return ListTile(
              key: ValueKey('mod_${m.id}'),
              leading: const CircleAvatar(child: Icon(Icons.wb_sunny, size: 20)),
              title: Text(m.modelName),
              subtitle: Text("${m.manufacturer} - ${m.powerWp}Wp"),
              onTap: () => _viewEquipment(context, module: m),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Visualizar módulo',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _viewEquipment(context, module: m),
                  ),
                  IconButton(
                    tooltip: 'Editar módulo',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editEquipment(context, module: m),
                  ),
                  IconButton(
                    tooltip: 'Remover módulo',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteEquipment(
                      context,
                      module: true,
                      id: m.id,
                      name: '${m.manufacturer} ${m.modelName}',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- WIDGET DE INVERSORES COM KEEPALIVE ---
class InverterListWidget extends StatefulWidget {
  const InverterListWidget({super.key});

  @override
  State<InverterListWidget> createState() => _InverterListWidgetState();
}

class _InverterListWidgetState extends State<InverterListWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isar = getIt<Isar>();

    return StreamBuilder<List<Inverter>>(
      stream: isar.inverters.where().watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final inverters = [...snapshot.data!]
          ..sort((a, b) => '${a.manufacturer} ${a.modelName}'
              .compareTo('${b.manufacturer} ${b.modelName}'));
        if (inverters.isEmpty) {
          return const Center(child: Text('Nenhum inversor cadastrado. Use Adicionar.'));
        }
        return ListView.builder(
          itemCount: inverters.length,
          itemBuilder: (context, index) {
            final inv = inverters[index];
            return ListTile(
              key: ValueKey('inv_${inv.id}'),
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.inventory_2, size: 20, color: Colors.white)),
              title: Text("${inv.manufacturer} - ${inv.modelName}"),
              subtitle: Text("${inv.nominalPowerKw}kW"),
              onTap: () => _viewEquipment(context, inverter: inv),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Visualizar inversor',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _viewEquipment(context, inverter: inv),
                  ),
                  IconButton(
                    tooltip: 'Editar inversor',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editEquipment(context, inverter: inv),
                  ),
                  IconButton(
                    tooltip: 'Remover inversor',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteEquipment(
                      context,
                      module: false,
                      id: inv.id,
                      name: '${inv.manufacturer} ${inv.modelName}',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}