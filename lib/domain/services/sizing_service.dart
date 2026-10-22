class SizingService {
  // PR (Performance Ratio) padrão de 77% para perdas do sistema
  static const double _performanceRatio = 0.77; 
  // Ganho bifacial sugerido para altura de 0.15m (ex: 5%)
  static const double _bifacialGain = 1.05; 

  static double calculateSuggestedPower({
    required double targetConsumption,
    required double averageHsp,
    bool isBifacial = false,
  }) {
    // Produção mensal de 1W instalado
    // 1W * HSP * 30 dias * PR
    double productionPerWatt = 1 * averageHsp * 30 * _performanceRatio;
    
    if (isBifacial) {
      productionPerWatt *= _bifacialGain;
    }

    // Retorna a potência total necessária em Watts (Wp)
    // Dividimos o consumo (Wh) pela produção por watt
    return (targetConsumption * 1000) / productionPerWatt;
  }
}