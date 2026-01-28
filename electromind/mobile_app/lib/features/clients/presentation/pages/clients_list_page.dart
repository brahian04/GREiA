import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/clients_cubit.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  @override
  void initState() {
    super.initState();
    // Cargar clientes al iniciar la pantall
    context.read<ClientsCubit>().loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/clients/new');
        },
        child: const Icon(Icons.person_add),
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          if (state is ClientsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ClientsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is ClientsLoaded) {
            final clients = state.clients;
            if (clients.isEmpty) {
              return const Center(child: Text('No hay clientes registrados.'));
            }
            return ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  leading: CircleAvatar(
                      child: Text(client.fullName[0].toUpperCase())),
                  title: Text(client.fullName),
                  subtitle: Text(client.phone ?? 'Sin teléfono'),
                  onTap: () {
                    // TODO: Ver detalle o seleccionar
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
