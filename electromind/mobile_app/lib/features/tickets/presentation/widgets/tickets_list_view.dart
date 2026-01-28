import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ticket_model.dart';
import '../cubit/tickets_cubit.dart';
import 'ticket_card.dart';

class TicketsListView extends StatefulWidget {
  const TicketsListView({super.key});

  @override
  State<TicketsListView> createState() => _TicketsListViewState();
}

class _TicketsListViewState extends State<TicketsListView> {
  // Line 14
  String _searchQuery = '';
  String _filterType = 'Todos'; // Todos, Activos, Terminados

  @override
  void initState() {
    super.initState();
    context.read<TicketsCubit>().loadTickets();
  }

  List<Ticket> _filterTickets(List<Ticket> tickets) {
    return tickets.where((t) {
      // 1. Filtro de Texto
      final query = _searchQuery.toLowerCase();
      final matchesSearch = t.humanId.toString().contains(query) ||
          (t.client?.fullName.toLowerCase().contains(query) ?? false) ||
          (t.deviceType.toLowerCase().contains(query)) ||
          (t.brand.toLowerCase().contains(query)) ||
          (t.model.toLowerCase().contains(query));

      if (!matchesSearch) return false;

      // 2. Filtro de Estado
      if (_filterType == 'Todos') return true;

      final status = t.status.toLowerCase();
      if (_filterType == 'Activos') {
        return ['pendiente', 'revisión', 'revision', 'reparando']
            .contains(status);
      }
      if (_filterType == 'Terminados') {
        return ['terminado', 'entregado', 'cancelado'].contains(status);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controles de Búsqueda y Filtro
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color:
              Theme.of(context).scaffoldBackgroundColor, // Adaptable background
          child: Column(
            children: [
              // Buscador
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, equipo o ID...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  // fillColor uses Theme default or override
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              // Chips de Filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Activos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terminados'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de Resultados
        Expanded(
          child: BlocBuilder<TicketsCubit, TicketsState>(
            builder: (context, state) {
              if (state is TicketsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is TicketsError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is TicketsLoaded) {
                final filteredTickets = _filterTickets(state.tickets);

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron tickets',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TicketsCubit>().loadTickets();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      return TicketCard(
                        ticket: filteredTickets[index],
                        onTap: () {
                          context
                              .push('/tickets/detail',
                                  extra: filteredTickets[index])
                              .then((_) {
                            context.read<TicketsCubit>().loadTickets();
                          });
                        },
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterType = label);
      },
      backgroundColor: theme.cardColor,
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : (theme.dividerColor),
        ),
      ),
      showCheckmark: false,
    );
  }
}
