import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/clients/presentation/pages/clients_list_page.dart';
import '../features/clients/presentation/pages/create_client_page.dart';
import '../features/clients/presentation/cubit/clients_cubit.dart';
import '../features/tickets/presentation/pages/create_ticket_page.dart';
import '../features/tickets/presentation/pages/ticket_detail_page.dart';
import '../features/tickets/presentation/cubit/tickets_cubit.dart';
import '../features/tickets/data/models/ticket_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../injection_container.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/tickets/presentation/pages/qr_scanner_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/tickets/new',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<TicketsCubit>(),
        child: const CreateTicketPage(),
      ),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => BlocProvider.value(
        value: sl<TicketsCubit>(), // Usa la instancia existente
        child: const QrScannerPage(),
      ),
    ),
    GoRoute(
      path: '/tickets/detail',
      builder: (context, state) {
        final ticket = state.extra as Ticket;
        return BlocProvider(
          key: ValueKey(ticket.id), // Ensure fresh provider if needed or reuse
          create: (context) => sl<TicketsCubit>(),
          child: TicketDetailPage(ticket: ticket),
        );
      },
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<ClientsCubit>(),
        child: const ClientsPage(),
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => BlocProvider(
            create: (context) => sl<
                ClientsCubit>(), // Reuse or new instance? New is fine for creation.
            child: const CreateClientPage(),
          ),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    // Basic Auth Guard
    final authState = sl<AuthCubit>().state;
    final isLoggingIn = state.uri.toString() == '/';

    if (authState is AuthAuthenticated && isLoggingIn) {
      return '/dashboard';
    }

    // Si no está autenticado y trata de ir a dashboard
    if (authState is! AuthAuthenticated && !isLoggingIn) {
      return '/';
    }

    return null;
  },
);
