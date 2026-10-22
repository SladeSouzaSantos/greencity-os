import '../../domain/entities/solar_project.dart';

class SolarQuoteModel {
  final String nome;
  final String cpfCnpj;
  final String cidade;
  final String estado;
  final double consumoMedio;
  final double energiaGeradaMed;
  final Map<String, double> geracaoMensal;

  // Módulo
  final String fabricanteModulo;
  final String modeloModulo;
  final double dimensaoModuloAltura;
  final double dimensaoComprimento;
  final double dimensaoEspessura;
  final double pesoModulo;
  final double perdaEficienciaModulo;
  final int garantiaFisicaModulo;
  final int garantiaEficienciaModulo;
  final int potenciaModulo;
  final int numeroModulos;

  // Inversor
  final String fabricanteInversor;
  final String modeloInversor;
  final String dimensaoInversor;
  final double pesoInversor;
  final int garantiaInversor;
  final double potenciaInversor;
  final int numeroInversores;

  // Financeiro
  final double tarifaKwh;
  final double tarifaTusd;
  final double valorLimiteIluminacaoPublica;
  final double inflacao;
  final double percentagemUsoRede;
  final double precoTotal;
  final double precoKitFotovoltaico;

  SolarQuoteModel({
    required this.nome,
    required this.cpfCnpj,
    required this.cidade,
    required this.estado,
    required this.consumoMedio,
    required this.energiaGeradaMed,
    required this.geracaoMensal,
    required this.fabricanteModulo,
    required this.modeloModulo,
    required this.dimensaoModuloAltura,
    required this.dimensaoComprimento,
    required this.dimensaoEspessura,
    required this.pesoModulo,
    required this.perdaEficienciaModulo,
    required this.garantiaFisicaModulo,
    required this.garantiaEficienciaModulo,
    required this.potenciaModulo,
    required this.numeroModulos,
    required this.fabricanteInversor,
    required this.modeloInversor,
    required this.dimensaoInversor,
    required this.pesoInversor,
    required this.garantiaInversor,
    required this.potenciaInversor,
    required this.numeroInversores,
    required this.tarifaKwh,
    required this.tarifaTusd,
    required this.valorLimiteIluminacaoPublica,
    required this.inflacao,
    required this.percentagemUsoRede,
    required this.precoTotal,
    required this.precoKitFotovoltaico,
  });

  factory SolarQuoteModel.fromProject({
    required SolarProject project,
    required double precoTotal,
    required double precoKit,
    double tarifaKwh = 0.99,
    double tarifaTusd = 0.5828,
    double ilumPublica = 190.40,
    double percentagemUsoRede = 30.0,
    double inflacao = 4.0,
  }) {
    // Validação de segurança
    if (project.systems.isEmpty) throw Exception("O projeto não possui sistemas configurados.");

    final firstSystem = project.systems.first;
    final firstModule = firstSystem.arrays.first.solarScenario.module;
    final inverter = firstSystem.inverter;

    // Mapeamento dos 12 meses (Usando o getter totalMonthlyGeneration do SolarProject)
    final mesesNomes = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final geracaoCalculada = project.totalMonthlyGeneration; // Retorna List<int>
    
    Map<String, double> geracaoMap = {};
    for (int i = 0; i < 12; i++) {
      geracaoMap[mesesNomes[i]] = geracaoCalculada[i].toDouble();
    }

    // Soma total de módulos no projeto
    int totalModulos = project.systems.fold(0, (sum, sys) => 
      sum + sys.arrays.fold(0, (s, arr) => s + arr.solarScenario.quantityPvModule));

    return SolarQuoteModel(
      nome: project.clientName,
      cpfCnpj: project.document ?? "000.000.000-00",
      cidade: project.city,
      estado: project.state,
      consumoMedio: project.monthlyConsumption,
      // Usando o novo getter do projeto
      energiaGeradaMed: project.totalAverageAnnualGeneration.toDouble(), 
      geracaoMensal: geracaoMap,
      
      // Dados do Módulo
      fabricanteModulo: firstModule.manufacturer,
      modeloModulo: firstModule.modelName,
      dimensaoModuloAltura: firstModule.length / 1000,
      dimensaoComprimento: firstModule.width / 1000,
      dimensaoEspessura: 0.03, 
      pesoModulo: firstModule.weight,
      perdaEficienciaModulo: firstModule.efficiencyLoss,
      garantiaFisicaModulo: firstModule.physicalWarranty,
      garantiaEficienciaModulo: firstModule.efficiencyWarranty,
      potenciaModulo: firstModule.powerWp,
      numeroModulos: totalModulos,

      // Dados do Inversor (Sincronizado com a classe Inverter)
      fabricanteInversor: inverter.manufacturer,
      modeloInversor: inverter.modelName, // Corrigido de .model para .modelName
      dimensaoInversor: inverter.dimensions, // Corrigido de hardcoded para .dimensions
      pesoInversor: inverter.weight,
      garantiaInversor: inverter.warrantyYears, // Corrigido para .warrantyYears
      potenciaInversor: inverter.nominalPowerKw,
      numeroInversores: project.systems.length,

      // Financeiro
      tarifaKwh: tarifaKwh,
      tarifaTusd: tarifaTusd,
      valorLimiteIluminacaoPublica: ilumPublica,
      inflacao: inflacao,
      percentagemUsoRede: percentagemUsoRede,
      precoTotal: precoTotal,
      precoKitFotovoltaico: precoKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "nome": nome,
      "cpf_cnpj": cpfCnpj,
      "cidade": cidade,
      "estado": estado,
      "consumo_medio": consumoMedio,
      "energiaGeradaMed": energiaGeradaMed,
      "energiaGeradaJan": geracaoMensal['Jan'],
      "energiaGeradaFev": geracaoMensal['Fev'],
      "energiaGeradaMar": geracaoMensal['Mar'],
      "energiaGeradaAbr": geracaoMensal['Abr'],
      "energiaGeradaMai": geracaoMensal['Mai'],
      "energiaGeradaJun": geracaoMensal['Jun'],
      "energiaGeradaJul": geracaoMensal['Jul'],
      "energiaGeradaAgo": geracaoMensal['Ago'],
      "energiaGeradaSet": geracaoMensal['Set'],
      "energiaGeradaOut": geracaoMensal['Out'],
      "energiaGeradaNov": geracaoMensal['Nov'],
      "energiaGeradaDez": geracaoMensal['Dez'],
      "fabricanteModulo": fabricanteModulo,
      "modeloModulo": modeloModulo,
      "dimensaoModuloAltura": dimensaoModuloAltura,
      "dimensaoComprimento": dimensaoComprimento,
      "dimensaoEspessura": dimensaoEspessura,
      "pesoModulo": pesoModulo,
      "perdaEficienciaModulo": perdaEficienciaModulo,
      "garantiaFisicaModulo": garantiaFisicaModulo,
      "garantiaEficienciaModulo": garantiaEficienciaModulo,
      "potenciaModulo": potenciaModulo,
      "numeroModulos": numeroModulos,
      "fabricanteInversor": fabricanteInversor,
      "modeloInversor": modeloInversor,
      "dimensaoInversor": dimensaoInversor,
      "pesoInversor": pesoInversor,
      "garantiaInversor": garantiaInversor,
      "potenciaInversor": potenciaInversor,
      "numeroInversores": numeroInversores,
      "tarifa_kwh": tarifaKwh,
      "tarifaTUSD": tarifaTusd,
      "valorLimiteIluminacaoPublica": valorLimiteIluminacaoPublica,
      "inflacao": inflacao,
      "percentagemUsoRede": percentagemUsoRede,
      "precoTotal": precoTotal,
      "precoKitFotovoltaico": precoKitFotovoltaico,
    };
  }
}