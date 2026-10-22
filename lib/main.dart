import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/datasources/solar_seed_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greencity_os/core/injection/injection.dart';
import 'package:greencity_os/presentation/bloc/solar_hsp_bloc.dart';
import 'package:greencity_os/presentation/pages/photovoltaic/solar_home_page.dart';
import 'presentation/pages/database/database_page.dart';
import 'presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await configureDependencies();
  
  final isar = getIt<Isar>();
  
  await isar.writeTxn(() => isar.clear());

  await SolarSeedData.seed(isar);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreencityOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // A Home agora é a tela de seleção (Dimensionamento vs Banco)
      home: const HomePage(), 
      
      // Definindo rotas para facilitar a navegação
      routes: {
        '/projects': (context) => BlocProvider(
          create: (context) => getIt<SolarHspBloc>(),
          child: const SolarHomePage(),
        ),
        '/database': (context) => const DatabasePage(),
      },
    );
  }
}