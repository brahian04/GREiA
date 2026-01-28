import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/clients/data/client_repository.dart';
import 'features/clients/presentation/cubit/clients_cubit.dart';
import 'features/tickets/data/tickets_repository.dart';
import 'features/tickets/presentation/cubit/tickets_cubit.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // Features - Auth
  sl.registerFactory(() => AuthCubit(sl()));
  sl.registerLazySingleton(() => AuthRepository(sl()));

  // Features - Clients
  sl.registerFactory(() => ClientsCubit(sl()));
  sl.registerLazySingleton(() => ClientRepository(sl()));

  // Features - Tickets
  sl.registerFactory(() => TicketsCubit(sl()));
  sl.registerLazySingleton(() => TicketsRepository(sl()));

  // External
  sl.registerLazySingleton(() => Supabase.instance.client);
}
