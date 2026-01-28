import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/client_model.dart';
import '../cubit/clients_cubit.dart';

class CreateClientPage extends StatefulWidget {
  const CreateClientPage({super.key});

  @override
  State<CreateClientPage> createState() => _CreateClientPageState();
}

class _CreateClientPageState extends State<CreateClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final newClient = Client(
        id: const Uuid()
            .v4(), // Client generated ID or let DB handle it? API prefers UUID.
        fullName: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        createdAt: DateTime.now(),
      );

      context.read<ClientsCubit>().createClient(newClient);
      // context.pop(); // Handled by listener
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<ClientsCubit, ClientsState>(
          listener: (context, state) {
            if (state is ClientsLoaded) {
              // Asumimos que si carga la lista es porque guardó exitosamente (loadClients se llama tras save)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Confirmado: Cliente Guardado'),
                    backgroundColor: Colors.green),
              );
              context.pop();
            } else if (state is ClientsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is ClientsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nombre Completo *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saveClient,
                    child: const Text('GUARDAR CLIENTE'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
