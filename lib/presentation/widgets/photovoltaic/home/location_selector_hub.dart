import 'package:flutter/material.dart';

class LocationSelectorHub extends StatelessWidget {
  final Map<String, dynamic> locations;
  final String? selectedState;
  final String? selectedCity;

  final TextEditingController latController;
  final TextEditingController lonController;

  final Function(String? state, String? city, double? lat, double? lon) onLocationChanged;

  const LocationSelectorHub({
    super.key,
    required this.locations,
    this.selectedState,
    this.selectedCity,
    required this.latController,
    required this.lonController,
    required this.onLocationChanged
  });

  @override
  Widget build(BuildContext context) {
    final states = locations.keys.toList()..sort();
    
    List<String> cities = [];
    
    if (selectedState != null && locations[selectedState] != null) {
      final stateData = locations[selectedState];
      // Acessa a chave 'cidades' que é uma Lista
      if (stateData['cidades'] is List) {
        final List<dynamic> cidadesList = stateData['cidades'];
        cities = cidadesList
            .map((c) => c['nome'].toString())
            .toList()
          ..sort();
      }
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, size: 18),
                SizedBox(width: 8),
                Text(
                  "Localização da Instalação",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Dropdown de Estado
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedState,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (newState) {
                      FocusScope.of(context).unfocus();
                      onLocationChanged(newState, null, null, null);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Dropdown de Cidade
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(selectedState),
                    initialValue: selectedCity,
                    hint: const Text("Cidades"),
                    disabledHint: const Text("Cidades"),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    // Só habilita se houver estado selecionado
                    items: cities.isEmpty 
                      ? null 
                      : cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (newCity) {
                      if (newCity != null && selectedState != null) {
                        // 1. Pegamos a lista de cidades uma única vez
                        final dynamic stateData = locations[selectedState];
                        final List<dynamic> cidadesList = stateData['cidades'] ?? [];
                        
                        // 2. Fazemos a busca de forma segura e rápida
                        try {
                          final cityData = cidadesList.firstWhere(
                            (c) => c['nome'] == newCity,
                            orElse: () => null,
                          );

                          if (cityData != null) {
                            // 3. Pegamos os valores garantindo que são doubles
                            final lat = double.tryParse(cityData['latitude'].toString());
                            final lon = double.tryParse(cityData['longitude'].toString());

                            onLocationChanged(selectedState, newCity, lat, lon);
                          }
                        } catch (e) {
                          debugPrint("Erro ao processar cidade: $e");
                        }
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: latController,
                    readOnly: selectedState != null, // Trava se houver cidade
                    style: TextStyle(color: selectedState != null ? Colors.grey : null),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.location_on, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lonController,
                    readOnly: selectedState != null, // Trava se houver cidade
                    style: TextStyle(color: selectedState != null ? Colors.grey : null),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.map, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            if (selectedCity != null && selectedState != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "Localidade selecionada com sucesso",
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.green[800], 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}