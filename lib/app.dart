import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'repositories/brand_repository.dart';
import 'repositories/car_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/in_memory_car_repository.dart';
import 'repositories/in_memory_client_repository.dart';
import 'repositories/network_simulator.dart';
import 'state/car_list_notifier.dart';
import 'state/client_list_notifier.dart';
import 'state/lookup_notifier.dart';

/// Собирает зависимости приложения. Вынесено из main, чтобы тесты могли
/// подставить свою имитацию сети и начальный адрес.
Widget buildApp({NetworkSimulator? network, String initialLocation = '/cars'}) {
  final net = network ?? NetworkSimulator();
  final carRepository = InMemoryCarRepository(net);
  final clientRepository = InMemoryClientRepository(
    net,
    carsOf: carRepository.countByClient,
  );
  final brandRepository = InMemoryBrandRepository(net);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: net),
      // Репозитории объявлены через интерфейс: в ПР4 их заменят реализации
      // поверх API, и ни один экран при этом не изменится.
      Provider<CarRepository>.value(value: carRepository),
      Provider<ClientRepository>.value(value: clientRepository),
      Provider<BrandRepository>.value(value: brandRepository),
      ChangeNotifierProvider(
        create: (context) => CarListNotifier(context.read<CarRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            ClientListNotifier(context.read<ClientRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) => LookupNotifier(
          context.read<BrandRepository>(),
          context.read<ClientRepository>(),
        )..load(),
      ),
    ],
    child: AutoServiceApp(
      router: createRouter(initialLocation: initialLocation),
    ),
  );
}

class AutoServiceApp extends StatelessWidget {
  const AutoServiceApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Автосервис',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F5FAD)),
        useMaterial3: true,
      ),
      // Подписи стандартных виджетов (подсказки, диалоги) — по-русски.
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Широкую таблицу можно прокрутить вбок, перетащив мышью.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      routerConfig: router,
    );
  }
}
