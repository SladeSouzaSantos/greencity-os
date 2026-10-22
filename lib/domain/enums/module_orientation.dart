enum ModuleOrientation {
  portrait,  // Retrato (em pé)
  landscape; // Paisagem (deitado)

  // Dica: Adicionar um getter para facilitar a exibição de nomes bonitos
  String get label => this == ModuleOrientation.portrait ? 'Retrato' : 'Paisagem';
}