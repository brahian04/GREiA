import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/ticket_model.dart';
import 'models/ticket_history_model.dart';
import '../../clients/data/models/client_model.dart';

class TicketsRepository {
  final SupabaseClient _supabase;

  TicketsRepository(this._supabase);

  // Obtener tickets (opcionalmente filtrar por estado)
  Future<List<Ticket>> getTickets({String? status}) async {
    PostgrestFilterBuilder query =
        _supabase.from('tickets').select('*, clients(*)'); // Join con clients

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Ticket.fromJson(e)).toList();
  }

  Future<Ticket?> getTicketById(String id) async {
    final response = await _supabase
        .from('tickets')
        .select('*, clients(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Ticket.fromJson(response);
  }

  Future<void> createTicket(Ticket ticket) async {
    await _supabase.from('tickets').insert(ticket.toJson());
  }

  // Nueva función compuesta: Crear Cliente + Ticket en una transacción (o secuencia)
  Future<void> createTicketWithNewClient(Ticket ticket, Client client) async {
    String clientIdRaw = client.id;

    // 1. Validar si el cliente ya existe (por teléfono)
    if (client.phone != null && client.phone!.isNotEmpty) {
      final existingClients = await _supabase
          .from('clients')
          .select()
          .eq('phone', client.phone!)
          .limit(1);

      if ((existingClients as List).isNotEmpty) {
        // Usar cliente existente
        clientIdRaw = existingClients.first['id'];
        // Opcional: Actualizar datos del cliente si es necesario
      } else {
        // Crear nuevo si no existe
        await _supabase.from('clients').insert(client.toJson());
      }
    } else {
      // Sin teléfono, intentamos inserción directa (o validamos por email si tuviera)
      await _supabase.from('clients').insert(client.toJson());
    }

    // 2. Crear Ticket usando el ID confirmado (nuevo o existente)
    final ticketWithClient = Ticket(
      id: ticket.id,
      humanId: 0, // DB Generated
      clientId: clientIdRaw,
      deviceType: ticket.deviceType,
      brand: ticket.brand,
      model: ticket.model,
      serialNumber: ticket.serialNumber,
      problemDescription: ticket.problemDescription,
      status: ticket.status,
      priority: ticket.priority,
      createdAt: ticket.createdAt,
    );

    await _supabase.from('tickets').insert(ticketWithClient.toJson());
  }

  Future<void> updateTicketStatus(String id, String newStatus,
      {String? solution, String? note}) async {
    final Map<String, dynamic> updates = {'status': newStatus};
    if (solution != null) {
      updates['technical_solution'] = solution;
    }
    await _supabase.from('tickets').update(updates).eq('id', id);

    // Registrar en historial automáticamente
    try {
      await _supabase.from('ticket_history').insert({
        'ticket_id': id,
        'action_type': 'cambio_estado',
        'note': note ?? 'Estado actualizado a: ${newStatus.toUpperCase()}',
      });
    } catch (e) {
      // Ignoramos error de historial para no bloquear el flujo principal
    }
  }

  Future<List<TicketHistory>> getTicketHistory(String ticketId) async {
    final response = await _supabase
        .from('ticket_history')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => TicketHistory.fromJson(e)).toList();
  }
}
