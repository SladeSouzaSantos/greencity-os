enum GridConnection {
  monophasic("Monofásico"), // Monofásico 220V
  biphasic("Bifásico"),   // Bifásico
  triphasic("Trifásico");  // Trifásico 380V/220V

  final String label;

  const GridConnection(this.label);
}