import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/client_model.dart';

class ClientRepository {
  final SupabaseClient _supabase;

  ClientRepository(this._supabase);

  Future<List<Client>> getClients() async {
    final response = await _supabase
        .from('clients')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Client.fromJson(e)).toList();
  }

  Future<void> createClient(Client client) async {
    await _supabase.from('clients').insert(client.toJson());
  }

  Future<void> updateClient(String id, Map<String, dynamic> updates) async {
    await _supabase.from('clients').update(updates).eq('id', id);
  }

  // Búsqueda simple por nombre
  Future<List<Client>> searchClients(String query) async {
    final response = await _supabase
        .from('clients')
        .select()
        .ilike('full_name', '%$query%')
        .order('full_name');

    return (response as List).map((e) => Client.fromJson(e)).toList();
  }
}
