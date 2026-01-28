import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../tickets/presentation/cubit/tickets_cubit.dart';
import '../../../tickets/presentation/widgets/tickets_list_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GREiA Taller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<AuthCubit>().signOut();
            },
          ),
        ],
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go('/');
          }
        },
        child: BlocProvider(
          key: _refreshKey, // Forzamos recreación al cambiar la key
          create: (context) => sl<TicketsCubit>(), // Proveer el Cubit aquí
          child: const TicketsListView(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan_btn',
            onPressed: () {
              context.push('/scanner').then((_) {
                setState(() => _refreshKey = UniqueKey());
              });
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'new_btn',
            onPressed: () {
              context.push('/tickets/new').then((_) {
                setState(() => _refreshKey = UniqueKey());
              });
            },
            label: const Text('Nuevo Servicio'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
