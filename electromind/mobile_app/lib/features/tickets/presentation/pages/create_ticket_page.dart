import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/ticket_model.dart';
import '../../../clients/data/models/client_model.dart';
import '../cubit/tickets_cubit.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();

  // Client Data
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();

  // Device Data
  String _deviceType = 'Smartphone';
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();

  void _saveTicket() {
    if (_formKey.currentState!.validate()) {
      final clientId = const Uuid().v4();

      final newClient = Client(
        id: clientId,
        fullName: _clientNameCtrl.text,
        phone: _clientPhoneCtrl.text,
        createdAt: DateTime.now(),
      );

      final newTicket = Ticket(
        id: const Uuid().v4(),
        humanId: 0,
        clientId: clientId,
        deviceType: _deviceType,
        brand: _brandCtrl.text,
        model: _modelCtrl.text,
        problemDescription: _problemCtrl.text,
        status: 'pendiente',
        priority: 'media',
        createdAt: DateTime.now(),
      );

      context
          .read<TicketsCubit>()
          .createTicket(newTicket, newClient: newClient);
      // El cierre de la pantalla se maneja en el BlocListener
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Servicio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sección Cliente
            const Text('Datos del Cliente',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _clientNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre Cliente',
                  prefixIcon: Icon(Icons.person),
                  counterText: ""),
              maxLength: 100,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (v.length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _clientPhoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Teléfono / WhatsApp',
                  prefixIcon: Icon(Icons.phone),
                  counterText: ""),
              keyboardType: TextInputType.phone,
              maxLength: 20,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (v.length < 7) return 'Número inválido';
                return null;
              },
            ),

            const Divider(height: 40),

            // Sección Dispositivo
            const Text('Datos del Dispositivo',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple)),
            DropdownButtonFormField<String>(
              value: _deviceType,
              items: ['Smartphone', 'Laptop', 'Tablet', 'TV', 'Consola', 'Otro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _deviceType = v!),
              decoration: const InputDecoration(labelText: 'Tipo de Equipo'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Marca', counterText: ""),
                    maxLength: 50,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Modelo', counterText: ""),
                    maxLength: 50,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _problemCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                  labelText: 'Descripción de la Falla',
                  alignLabelWithHint: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (v.length < 10)
                  return 'Sea más descriptivo (mín. 10 caracteres)';
                return null;
              },
            ),

            const SizedBox(height: 24),
            BlocConsumer<TicketsCubit, TicketsState>(
              listener: (context, state) {
                if (state is TicketsLoaded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('¡Servicio registrado con éxito! 🚀'),
                        backgroundColor: Colors.green),
                  );
                  context.pop();
                } else if (state is TicketsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: ${state.message}'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                if (state is TicketsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FilledButton.icon(
                  onPressed: _saveTicket, // Ya no hace pop inmediato
                  icon: const Icon(Icons.save),
                  label: const Text('REGISTRAR SERVICIO'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
