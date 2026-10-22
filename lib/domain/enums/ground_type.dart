enum GroundType {
  grass("Grama/Gramado", 0.20),
  sandySoil("Solo Arenoso", 0.25),
  newConcrete("Concreto Novo", 0.35),
  oldConcrete("Concreto Velho", 0.22),
  asphalt("Asfalto", 0.12),
  whiteGravel("Cascalho Branco", 0.50),
  whitePaint("Pintura Branca (Telhado)", 0.75),
  desertSolo("Solo Desértico", 0.30),
  snow("Neve (Fresta)", 0.80),
  denseVegetation("Vegetação Densa", 0.18);

  final String label;
  final double albedo;

  const GroundType(this.label, this.albedo);
}