import 'package:flutter/material.dart';
import '../../../../domain/entities/solar_project.dart';

class ProjectSummaryHeader extends StatelessWidget {
  final SolarProject project;

  const ProjectSummaryHeader({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.location_on, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${project.city} - ${project.state}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Consumo alvo: ${project.effectiveConsumption.toStringAsFixed(0)} kWh/mês",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}