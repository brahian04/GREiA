import 'package:flutter/material.dart';
import 'package:electromind_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:electromind_app/features/clients/presentation/pages/clients_list_page.dart';
import 'package:electromind_app/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:electromind_app/features/inventory/presentation/pages/inventory_page.dart';

import 'package:electromind_app/features/ai/presentation/widgets/ai_assistant_modal.dart';
import 'package:electromind_app/features/tickets/presentation/cubit/tickets_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AiAssistantPage(), // Electromind
    const InventoryPage(),
    const ClientsPage(),
  ];

  String _getContextForIndex(int index) {
    switch (index) {
      case 0:
        return 'Viendo el Dashboard de Tickets';
      case 1:
        return 'Home de la IA';
      case 2:
        return 'Viendo Inventario';
      case 3:
        return 'Gestionando Clientes';
      default:
        return 'Navegando en GREiA';
    }
  }

  void _openAiAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Calcular estadísticas en tiempo real desde el Cubit
        String systemContext = _getContextForIndex(_selectedIndex);

        final ticketsState = context.read<TicketsCubit>().state;
        if (ticketsState is TicketsLoaded) {
          final total = ticketsState.tickets.length;
          final pending =
              ticketsState.tickets.where((t) => t.status == 'pendiente').length;
          final inProgress = ticketsState.tickets
              .where((t) => ['revision', 'reparando'].contains(t.status))
              .length;
          final finished = ticketsState.tickets
              .where((t) => ['terminado', 'entregado'].contains(t.status))
              .length;

          systemContext += '\n\nESTADO ACTUAL DEL TALLER:\n'
              '- Tickets Totales: $total\n'
              '- Pendientes: $pending\n'
              '- En Proceso: $inProgress\n'
              '- Terminados/Entregados: $finished';
        }

        return AiAssistantModal(
          initialContext: systemContext,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: _selectedIndex == 1
          ? null
          : FloatingActionButton(
              heroTag: 'ai_main_fab',
              onPressed: _openAiAssistant,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .startFloat, // Izquierda para no tapar el (+)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_repair_service_outlined),
            selectedIcon: Icon(Icons.home_repair_service),
            label: 'Taller',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Electromind',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
        ],
      ),
    );
  }
}
