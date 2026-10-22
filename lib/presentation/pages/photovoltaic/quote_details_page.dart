import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/injection/injection.dart';
import '../../../data/models/solar_quote_model.dart';
import '../../../domain/entities/solar_project.dart';
import '../../../domain/repositories/solar_repository.dart';

class QuoteDetailsPage extends StatefulWidget {
  final SolarProject project;

  const QuoteDetailsPage({super.key, required this.project});

  @override
  State<QuoteDetailsPage> createState() => _QuoteDetailsPageState();
}

class _QuoteDetailsPageState extends State<QuoteDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers Financeiros
  final _tarifaKwhController = TextEditingController(text: "0.99");
  final _tarifaTusdController = TextEditingController(text: "0.58283035");
  final _iluminacaoController = TextEditingController(text: "190.40");
  final _inflacaoController = TextEditingController(text: "4.0");
  final _usoRedeController = TextEditingController(text: "30");
  final _precoTotalController = TextEditingController();
  final _precoKitController = TextEditingController();

  @override
  void dispose() {
    _tarifaKwhController.dispose();
    _tarifaTusdController.dispose();
    _iluminacaoController.dispose();
    _inflacaoController.dispose();
    _usoRedeController.dispose();
    _precoTotalController.dispose();
    _precoKitController.dispose();
    super.dispose();
  }

  Future<void> _gerarEEnviarOrcamento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = SolarQuoteModel.fromProject(
        project: widget.project,
        precoTotal: double.parse(_precoTotalController.text.replaceAll(',', '.')),
        precoKit: double.parse(_precoKitController.text.replaceAll(',', '.')),
        tarifaKwh: double.parse(_tarifaKwhController.text.replaceAll(',', '.')),
        tarifaTusd: double.parse(_tarifaTusdController.text.replaceAll(',', '.')),
        ilumPublica: double.parse(_iluminacaoController.text.replaceAll(',', '.')),
        percentagemUsoRede: double.parse(_usoRedeController.text.replaceAll(',', '.')),
        inflacao: double.parse(_inflacaoController.text.replaceAll(',', '.')),
      );
      
      // 1. Obtém os bytes
      final List<int> pdfBytes = await getIt<SolarRepository>().generateQuotePDF(request);

      // 2. Salva o arquivo temporariamente
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/orcamento_${widget.project.clientName}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // 3. Abre o arquivo
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception("Não foi possível abrir o PDF: ${result.message}");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF gerado com sucesso!"), backgroundColor: Colors.green),
      );// Volta para a home ou lista de projetos

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao gerar PDF: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finalizar Orçamento"),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Gerando PDF e enviando dados..."),
            ],
          ))
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Parâmetros Financeiros"),
                  _buildInputRow(
                    _buildTextField("Tarifa kWh", _tarifaKwhController),
                    _buildTextField("Tarifa TUSD", _tarifaTusdController),
                  ),
                  _buildInputRow(
                    _buildTextField("Ilum. Pública", _iluminacaoController),
                    _buildTextField("Uso Rede (%)", _usoRedeController),
                  ),
                  _buildTextField("Inflação Anual (%)", _inflacaoController),
                  
                  const Divider(height: 40),
                  _buildSectionTitle("Preços de Venda (Obrigatórios)"),
                  _buildTextField(
                    "Preço Total de Venda (R\$)", 
                    _precoTotalController, 
                    isNullable: false, 
                    isMoney: true
                  ),
                  _buildTextField(
                    "Custo do Kit (R\$)", 
                    _precoKitController, 
                    isNullable: false, 
                    isMoney: true
                  ),
                  
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _gerarEEnviarOrcamento,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("GERAR PDF E FINALIZAR", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeaderInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cliente: ${widget.project.clientName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Local: ${widget.project.city} - ${widget.project.state}"),
            Text("Consumo: ${widget.project.monthlyConsumption} kWh/mês"),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildInputRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNullable = true, bool isMoney = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: isMoney ? "R\$ " : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) {
          if (!isNullable && (value == null || value.isEmpty)) {
            return "Campo obrigatório";
          }
          if (value != null && value.isNotEmpty) {
            final n = double.tryParse(value.replaceAll(',', '.'));
            if (n == null) return "Número inválido";
          }
          return null;
        },
      ),
    );
  }
}