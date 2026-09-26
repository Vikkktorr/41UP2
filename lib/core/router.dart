import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/car_query.dart';
import '../models/client_details.dart';
import '../models/client_query.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../screens/car_detail_screen.dart';
import '../screens/car_list_screen.dart';
import '../screens/client_detail_screen.dart';
import '../screens/client_list_screen.dart';
import '../screens/not_found_screen.dart';
import '../state/detail_notifier.dart';
import '../widgets/app_shell.dart';

GoRouter createRouter({String initialLocation = '/cars'}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    redirect: (context, state) => state.uri.path == '/' ? '/cars' : null,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/cars',
            // Условия отбора берутся из адреса — аналог @RequestParam.
            builder: (context, state) => CarListScreen(
              query: CarQuery.fromQueryParameters(state.uri.queryParameters),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id']!);
                  if (id == null) {
                    return NotFoundScreen(location: state.uri.toString());
                  }
                  // Состояние карточки живёт, пока открыт экран.
                  return ChangeNotifierProvider(
                    key: ValueKey('car-$id'),
                    create: (context) => DetailNotifier<Car>(
                      () => context.read<CarRepository>().findById(id),
                    )..load(),
                    child: CarDetailScreen(id: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => ClientListScreen(
              query: ClientQuery.fromQueryParameters(state.uri.queryParameters),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id']!);
                  if (id == null) {
                    return NotFoundScreen(location: state.uri.toString());
                  }
                  return ChangeNotifierProvider(
                    key: ValueKey('client-$id'),
                    create: (context) => DetailNotifier<ClientDetails>(
                      () => _loadClient(context, id),
                    )..load(),
                    child: ClientDetailScreen(id: id),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<ClientDetails?> _loadClient(BuildContext context, int id) async {
  final clients = context.read<ClientRepository>();
  final cars = context.read<CarRepository>();
  final client = await clients.findById(id);
  if (client == null) return null;
  final page = await cars.find(CarQuery(clientId: id, size: 50));
  return ClientDetails(client: client, cars: page.items);
}
