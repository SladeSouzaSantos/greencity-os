enum CellTechnology {
  alBSF("p-Poly (Standard)", 0.60, "AL_BSF"),
  perc("p-Mono PERC", 0.70, "PERC"),
  topcon("n-Mono TOPCon", 0.80, "TOPCON"),
  hjt("Heterojunção (n-type)", 0.90, "HJT");

  final String label;
  final double bifacialityFactor;
  final String apiKey; // A chave que o servidor espera

  const CellTechnology(this.label, this.bifacialityFactor, this.apiKey);
}