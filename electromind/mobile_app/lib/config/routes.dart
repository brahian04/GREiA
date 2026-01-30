import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';

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
import '../features/home/presentation/pages/main_page.dart';
import '../features/ai/presentation/pages/ai_assistant_page.dart';
// import '../features/ai/presentation/widgets/ai_assistant_modal.dart'; // No longer needed for model
import '../features/ai/domain/entities/chat_message.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainPage(),
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
      path: '/ai-chat',
      builder: (context, state) {
        String? ctx;
        List<ChatMessage>? msgs;

        if (state.extra is Map) {
          final data = state.extra as Map;
          ctx = data['context'] as String?;
          msgs = data['messages'] as List<ChatMessage>?;
        } else if (state.extra is String) {
          ctx = state.extra as String?;
        }

        return AiAssistantPage(initialContext: ctx, initialMessages: msgs);
      },
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
