import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greencity_os/domain/entities/solar_project.dart';
import 'package:greencity_os/presentation/pages/photovoltaic/solar_project_designer_page.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/home/location_selector_hub.dart';

import '../../bloc/solar_hsp_bloc.dart';

class SolarHomePage extends StatefulWidget {
  const SolarHomePage({super.key});

  @override
  State<SolarHomePage> createState() => _SolarHomePageState();
}

class _SolarHomePageState extends State<SolarHomePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _docController = TextEditingController();
  final _consumptionController = TextEditingController();
  final _latController = TextEditingController(text: "-5.8125");
  final _lonController = TextEditingController(text: "-35.1875");

  Map<String, dynamic> locations = {};
  String? selectedState = "RN";
  String? selectedCity = "Natal";

  bool useSafetyMargin = true; // Os 25% de folga começam ativos

  @override
  void initState() {
    super.initState();
    _loadLocations(); // Carrega os dados ao iniciar
  }

  void _proceedToDesigner() {
    // Dispara a validação de todos os campos do formulário
    if (_formKey.currentState!.validate()) {
      if (selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecione uma cidade")),
        );
        return;
      }

      final consumptionText = _consumptionController.text.replaceAll(',', '.');

      final project = SolarProject(
        clientName: _nameController.text.trim(),
        document: _docController.text.trim(),
        city: selectedCity!,
        state: selectedState!,
        latitude: double.tryParse(_latController.text) ?? 0.0,
        longitude: double.tryParse(_lonController.text) ?? 0.0,
        monthlyConsumption: double.parse(consumptionText),
        useSafetyMargin: useSafetyMargin,
      );

      final solarBloc = context.read<SolarHspBloc>();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: solarBloc, // Repassa o Bloc "vivo" para a próxima tela
            child: SolarProjectDesignerPage(project: project),
          ),
        ),
      );
    }
  }

  Future<void> _loadLocations() async {
    final String response = await rootBundle.loadString('assets/localidades.json');
    final data = await json.decode(response);
    setState(() {
      locations = data;
      // Se por algum motivo o RN não existir no JSON, você pode tratar aqui
      if (!locations.containsKey(selectedState)) {
        selectedState = locations.keys.first;
        selectedCity = (locations[selectedState] as Map).keys.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Projeto Solar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Vincula a chave ao formulário
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Localização da Instalação", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              
              LocationSelectorHub(
                locations: locations,
                selectedState: selectedState,
                selectedCity: selectedCity,
                latController: _latController,
                lonController: _lonController,
                onLocationChanged: (state, city, lat, lon) {
                  setState(() {
                    selectedState = state;
                    selectedCity = city;
                    if (lat != null) _latController.text = lat.toString();
                    if (lon != null) _lonController.text = lon.toString();
                  });
                },
              ),

              const Divider(height: 40),

              const Text("Dados do Cliente", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              
              // Campo Nome com Validação
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nome do Cliente *",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome do cliente é obrigatório';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _docController,
                decoration: const InputDecoration(
                  labelText: "CPF/CNPJ (Opcional)",
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 30),

              const Text("Demanda Energética", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              
              // Campo Consumo com Validação
              TextFormField(
                controller: _consumptionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: "Consumo Médio Mensal (kWh) *",
                  suffixText: "kWh",
                  prefixIcon: Icon(Icons.bolt),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o consumo mensal';
                  }
                  final n = double.tryParse(value.replaceAll(',', '.'));
                  if (n == null || n <= 0) {
                    return 'Informe um valor numérico válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Adicionar 25% de folga"),
                value: useSafetyMargin,
                onChanged: (val) => setState(() => useSafetyMargin = val),
              ),

              const SizedBox(height: 80),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _proceedToDesigner,
                child: const Text("GERAR DIAGNÓSTICO", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}