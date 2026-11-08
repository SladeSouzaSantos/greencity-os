import 'package:flutter/material.dart';
import '../../../../domain/entities/solar_system.dart';
import '../../../../domain/entities/solar_array.dart';
import '../../../../domain/solar3d/solar3d_optical_correction.dart';

class SolarSystemCard extends StatelessWidget {
  final SolarSystem system;
  final VoidCallback onDeleteSystem;
  final VoidCallback onAddArray;
  final Function(SolarArray) onRemoveArray;
  final Function(SolarArray, int) onMpptChanged;
  final Solar3dOpticalCorrection? opticalCorrection;

  const SolarSystemCard({
    super.key,
    required this.system,
    required this.onDeleteSystem,
    required this.onAddArray,
    required this.onRemoveArray,
    required this.onMpptChanged,
    this.opticalCorrection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // Cabeçalho do Inversor          
          ListTile(
            tileColor: Colors.blueGrey.withValues(alpha: 0.1),
            title: Text(
              system.inverter.manufacturer, 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(system.inverter.modelName),
                Text("Potência instalada: ${system.totalSystemPower/1000} kWp"),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), 
              onPressed: onDeleteSystem,
            ),
          ),
          
          // Lista de Arranjos (Telhados)
          if (system.arrays.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Nenhum módulo adicionado a este inversor.", 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            ...system.arrays.map((array) => _buildArrayTile(array)),

          // The original SolarArray MPPT remains the registered
          // connection. In the 3D study, each physical panel may have its
          // own hypothetical MPPT of THIS inverter.
          if (opticalCorrection?.groupsBySystemMppt[system.id] != null) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text('Distribuição óptica experimental 3D',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final entry in (opticalCorrection!
                .groupsBySystemMppt[system.id]!.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key))))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MPPT ${entry.key} · '
                    '${entry.value.moduleCount} placa(s) · '
                    '${(entry.value.powerWp / 1000).toStringAsFixed(3)} kWp · '
                    'HSP óptico médio: '
                    '${(List<double>.generate(12, (m) =>
                      entry.value.baselineMonthlyHsp[m] *
                        entry.value.retentionMonthly[m])
                        .reduce((a, b) => a + b) / 12).toStringAsFixed(2)}',
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('O MPPT alterado no 3D vale apenas para '
                'a estimativa óptica; a configuração elétrica '
                'original não foi modificada. Verifique strings, '
                'tensão e corrente antes de instalar.'),
            ),
          ],

          // Botão de Ação
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton.icon(
              onPressed: onAddArray,
              icon: const Icon(Icons.add),
              label: const Text("ADICIONAR MÓDULOS A ESTE INVERSOR"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hspBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // Widget interno para cada grupo de placas (Arranjo)
  Widget _buildArrayTile(SolarArray array) {
    final bool isIndividual = array.solarScenario.id.contains("(Placa");
    
    // Simulação de onde os dados viriam. 
    // Substitua pelas propriedades reais do seu objeto de resultado (Ex: array.result.hspReal)
    debugPrint("array.solarScenario: ${array.solarScenarioResult?.shadowLossPercentage}");
    String? rawPercentage = array.solarScenarioResult?.shadowLossPercentage;

  // 2. Só tentamos o parse se a String não for nula
    double perdaSombreamento = 0.0;

    if (rawPercentage != null) {
      perdaSombreamento = double.tryParse(
        rawPercentage.replaceAll('%', '').trim()
      ) ?? 0.0;
    }

    double hspIndividual = array.solarScenarioResult?.averageHspReal ?? 0.0;
    double hspEfetivo = system.getEffectiveHspForArray(array);
    // Cálculo de "perda por incompatibilidade" (mismatch)
    double mismatchLoss = hspIndividual > 0 
        ? (1 - (hspEfetivo / hspIndividual)) * 100 
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isIndividual ? Icons.wb_shade_outlined : Icons.wb_sunny_outlined, 
          color: isIndividual ? Colors.blueGrey : Colors.orange
        ),
        title: Text(
          isIndividual 
            ? "Módulo ${array.solarScenario.id.split('Placa ').last.split(')').first} - ${array.solarScenario.module.modelName}"
            : "${array.solarScenario.module.modelName} - ${array.solarScenario.quantityPvModule} un.",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inclinação: ${array.solarScenario.inclination}° | Azimute: ${array.solarScenario.azimuth}°",
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              "Potência: ${(array.totalPowerWp / 1000).toStringAsFixed(3)} kWp",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 8),  
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // HSP INDIVIDUAL
                _hspBadge("HSP Local: ${hspIndividual.toStringAsFixed(2)}h", Colors.grey),
                const SizedBox(width: 8),
                
                // HSP EFETIVO (O QUE VALE NO CÁLCULO)
                _hspBadge(
                  "HSP Real: ${hspEfetivo.toStringAsFixed(2)}h", 
                  mismatchLoss > 1 ? Colors.orange.shade800 : Colors.green
                ),
              ],
            ), 
            const SizedBox(height: 4),          
            Text(
              "Perda no HSP base (sem obstáculos 3D): "
              "${perdaSombreamento.toStringAsFixed(1)}%",
              style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: perdaSombreamento > 0
                      ? Colors.redAccent : Colors.grey.shade700),
            ),
            if (opticalCorrection != null)
              const Text(
                'Sombreamento 3D incluído separadamente na geração '
                'corrigida; veja o resumo por MPPT abaixo.',
                style: TextStyle(fontSize: 11),
              ),
            if (mismatchLoss > 1) 
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "⚠ Redução de HSP por agrupamento do MPPT: ${mismatchLoss.toStringAsFixed(1)}% (aproximação óptica, não perda elétrica I-V)",
                style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade100)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true, // Garante que não vai estourar o layout
                  isDense: true,    // Deixa mais compacto
                  icon: const Icon(Icons.cable, size: 16, color: Colors.blue),
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                  value: array.mpptIndex <= system.inverter.mpptCount 
                      ? array.mpptIndex 
                      : 1, // Prevenção de erro caso o inversor mude
                  // Cria a lista de opções baseada na capacidade do inversor atual
                  items: List.generate(
                    system.inverter.mpptCount, 
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text("Conectado ao MPPT ${index + 1}"),
                    ),
                  ),
                  onChanged: (novoMppt) {
                    if (novoMppt != null && novoMppt != array.mpptIndex) {
                      // Dispara o callback para a tela pai atualizar o estado
                      onMpptChanged(array, novoMppt);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
          onPressed: () => onRemoveArray(array),
        ),
      ),
    );
  }
}