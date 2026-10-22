import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GreenCity Solar")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHomeCard(
              context,
              icon: Icons.calculate,
              title: "Novo Dimensionamento",
              subtitle: "Calcular projeto e gerar PDF",
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/projects'), // Sua rota de projetos
            ),
            const SizedBox(height: 20),
            _buildHomeCard(
              context,
              icon: Icons.storage,
              title: "Banco de Dados",
              subtitle: "Gerenciar Módulos e Inversores",
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/database'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Row(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}