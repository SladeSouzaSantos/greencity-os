import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/datasources/solar_seed_data.dart';
import 'data/datasources/souenergy_verified_seed.dart';
import 'data/repositories/equipment_catalog.dart';
import 'domain/entities/inverter.dart';
import 'domain/entities/pv_module.dart';
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
  
  // Nunca apague o catálogo na inicialização: os dados são persistentes.
  // O marcador impede que a remoção de todos os equipamentos volte a
  // popular o banco na próxima execução.
  final directory = await getApplicationDocumentsDirectory();
  final seedMarker = File(
    '${directory.path}${Platform.pathSeparator}.greencity_seed_v1',
  );
  if (!await seedMarker.exists()) {
    final existingModules = await isar.pvModules.count();
    final existingInverters = await isar.inverters.count();
    if (existingModules == 0 && existingInverters == 0) {
      await SolarSeedData.seed(isar);
    }
    // Também marca bases pré-existentes para nunca sobrescrever o catálogo.
    await seedMarker.writeAsString('initialized', flush: true);
  }
  
  // Complemento v2 importado uma única vez, preservando dados existentes.
  final verifiedMarker = File(
    directory.path + Platform.pathSeparator + '.greencity_souenergy_verified_v2',
  );
  if (!await verifiedMarker.exists()) {
    await EquipmentCatalog(isar).importMany(
      modules: SouEnergyVerifiedSeed.modules(),
      inverters: SouEnergyVerifiedSeed.inverters(),
    );
    await verifiedMarker.writeAsString('initialized', flush: true);
  }

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