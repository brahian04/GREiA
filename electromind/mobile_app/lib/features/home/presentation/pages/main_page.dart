import 'package:flutter/material.dart';
import 'package:electromind_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:electromind_app/features/clients/presentation/pages/clients_list_page.dart';
import 'package:electromind_app/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:electromind_app/features/inventory/presentation/pages/inventory_page.dart';

import 'package:electromind_app/features/ai/presentation/widgets/ai_assistant_modal.dart';

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
      builder: (context) => AiAssistantModal(
        initialContext: _getContextForIndex(_selectedIndex),
      ),
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
