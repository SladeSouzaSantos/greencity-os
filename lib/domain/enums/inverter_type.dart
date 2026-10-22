enum InverterType {
  string("Inversor de String"),
  microInverter("Microinversor"),
  optimizer("Otimizador");

  final String label;
  const InverterType(this.label);
}