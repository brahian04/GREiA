import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/client_repository.dart';
import '../../data/models/client_model.dart';

// States
abstract class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object> get props => [];
}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<Client> clients;
  const ClientsLoaded(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientsError extends ClientsState {
  final String message;
  const ClientsError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class ClientsCubit extends Cubit<ClientsState> {
  final ClientRepository _repository;

  ClientsCubit(this._repository) : super(ClientsInitial());

  Future<void> loadClients() async {
    try {
      emit(ClientsLoading());
      final clients = await _repository.getClients();
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> createClient(Client client) async {
    try {
      // Optimistic update or reload? Reload for simplicity.
      emit(ClientsLoading());
      await _repository.createClient(client);
      loadClients();
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }
}
