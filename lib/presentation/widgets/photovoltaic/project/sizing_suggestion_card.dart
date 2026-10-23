import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/solar_climate.dart';
import '../../../../domain/entities/solar_project.dart';
import '../../../../domain/services/sizing_service.dart';
import '../../../bloc/solar_hsp_bloc.dart';
import '../../../bloc/solar_hsp_state.dart';

class SizingSuggestionCard extends StatelessWidget {
  final SolarProject project;
  final VoidCallback onDetailsTap;

  const SizingSuggestionCard({
    super.key, 
    required this.project, 
    required this.onDetailsTap,
  });

  Widget _buildGenerationProgress() {
    final double target = project.effectiveConsumption;
    final int current = project.totalAverageAnnualGeneration;
    final double percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Geração do Sistema Projetado", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${current.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} kWh", 
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade200,
              color: percent >= 1.0 ? Colors.green : Colors.blue,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 5),
            Text("${(percent * 100).toStringAsFixed(1)}% da meta atingida", style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, double mono, double bifi) {
    final climate = project.climate;
    final hsp = project.referenceHspHorizontal;

    return Card(
      clipBehavior: Clip.antiAlias, // Garante que o InkWell respeite as bordas
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Aqui você pode abrir um BottomSheet com o gráfico de HSP mensal no futuro
          _showClimateDetailsSheet(context);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "POTÊNCIA MÍNIMA SUGERIDA",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPowerInfo("Monofacial", mono),
                      Container(height: 40, width: 1, color: Colors.orange.shade200),
                      _buildPowerInfo("Bifacial", bifi),
                    ],
                  ),
                ],
              ),
            ),
            // RODAPÉ COM DADOS CLIMÁTICOS
            if (climate != null && hsp != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.shade100.withValues(alpha: 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          "HSP horizontal (GHI): ${hsp.annualAverage.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.thermostat, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          "Temp: ${_calculateYearlyMinTemp(climate).toStringAsFixed(0)}° / ${_calculateYearlyMaxTemp(climate).toStringAsFixed(0)}°C",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPowerInfo(String label, double watts) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          "${(watts / 1000).toStringAsFixed(2)} kWp",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showClimateDetailsSheet(BuildContext context) {
    final climate = project.climate;
    final hsp = project.referenceHspHorizontal;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Dados Ambientais de Referência", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Text("Cidade: ${project.city} - ${project.state}"),
              const SizedBox(height: 10),
              Text("HSP horizontal (GHI): ${hsp?.annualAverage.toStringAsFixed(2)} kWh/m²/dia"),
              Text("Fonte: ${project.hspDataSource ?? 'não informada pela API'}"),
              Text("Transposição dos arranjos: ${project.hspTranspositionModel ?? 'não informada'}"),
              Text("Temperatura máxima anual: ${_calculateYearlyMaxTemp(climate).toStringAsFixed(1)} °C"),
              Text("Temperatura média anual: ${_calculateAvgTemp(climate).toStringAsFixed(1)} °C"),
              Text("Temperatura mínima anual: ${_calculateYearlyMinTemp(climate).toStringAsFixed(1)} °C"),
              const SizedBox(height: 15),
              const Text("Estes dados são utilizados para o dimensionamento inicial e cálculo de perdas térmicas.",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  double _calculateAvgTemp(SolarClimate? climate) {
    if (climate == null || climate.tempAvgMonthly.isEmpty) return 0.0;

    // Definimos <double> explicitamente e começamos com 0.0
    final total = climate.tempAvgMonthly.fold<double>(
      0.0, 
      (sum, element) => sum + element
    );

    return total / 12;
  }
  
  double _calculateYearlyMaxTemp(SolarClimate? climate) {
    if (climate == null || climate.tempMaxMonthly.isEmpty) return 0.0;
    // Encontra o maior valor da lista
    return climate.tempMaxMonthly.reduce((curr, next) => curr > next ? curr : next);
  }

  double _calculateYearlyMinTemp(SolarClimate? climate) {
    if (climate == null || climate.tempMinMonthly.isEmpty) return 0.0;
    // Encontra o menor valor da lista
    return climate.tempMinMonthly.reduce((curr, next) => curr < next ? curr : next);
  }
 
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolarHspBloc, SolarHspState>(
      builder: (context, state) {
        // A referência é gerenciada pelo Listener da página, nunca pelo build.
        // Recalcular um módulo inclinado não altera o GHI horizontal da cidade.
        final reference = project.referenceHspHorizontal;
        if (reference == null) {
          if (state is SolarHspError) {
            return Text("Erro: ${state.message}", style: const TextStyle(color: Colors.red));
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final powerMono = SizingService.calculateSuggestedPower(
          targetConsumption: project.effectiveConsumption,
          averageHsp: reference.annualAverage,
          isBifacial: false,
        );
        final powerBifi = SizingService.calculateSuggestedPower(
          targetConsumption: project.effectiveConsumption,
          averageHsp: reference.annualAverage,
          isBifacial: true,
        );

        return Column(
          children: [
            _buildSuggestionCard(context, powerMono, powerBifi),
            _buildGenerationProgress(),
          ],
        );
      },
    );
  }
}