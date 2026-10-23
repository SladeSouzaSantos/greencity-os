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
              trailing: IconButton(
                tooltip: 'Remover módulo',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteEquipment(
                  context,
                  module: true,
                  id: m.id,
                  name: '${m.manufacturer} ${m.modelName}',
                ),
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
              trailing: IconButton(
                tooltip: 'Remover inversor',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteEquipment(
                  context,
                  module: false,
                  id: inv.id,
                  name: '${inv.manufacturer} ${inv.modelName}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}