import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/tickets_repository.dart';
import '../../data/models/ticket_model.dart';
import '../../../clients/data/models/client_model.dart';

// States
abstract class TicketsState extends Equatable {
  const TicketsState();
  @override
  List<Object> get props => [];
}

class TicketsInitial extends TicketsState {}

class TicketsLoading extends TicketsState {}

class TicketsLoaded extends TicketsState {
  final List<Ticket> tickets;
  const TicketsLoaded(this.tickets);
  @override
  List<Object> get props => [tickets];
}

class TicketsError extends TicketsState {
  final String message;
  const TicketsError(this.message);
  @override
  List<Object> get props => [message];
}

class TicketsCubit extends Cubit<TicketsState> {
  final TicketsRepository _repository;

  TicketsCubit(this._repository) : super(TicketsInitial());

  Future<void> loadTickets({String? status}) async {
    try {
      emit(TicketsLoading());
      final tickets = await _repository.getTickets(status: status);
      emit(TicketsLoaded(tickets));
    } catch (e) {
      emit(TicketsError(e.toString()));
    }
  }

  Future<void> createTicket(Ticket ticket, {Client? newClient}) async {
    try {
      emit(TicketsLoading());
      if (newClient != null) {
        await _repository.createTicketWithNewClient(ticket, newClient);
      } else {
        await _repository.createTicket(ticket);
      }
      loadTickets();
    } catch (e) {
      emit(TicketsError(e.toString()));
    }
  }

  Future<void> updateTicketStatus(String id, String status,
      {String? solution, String? note}) async {
    try {
      await _repository.updateTicketStatus(id, status,
          solution: solution, note: note);
      loadTickets();
    } catch (e) {
      emit(TicketsError(e.toString()));
    }
  }

  Future<Ticket?> getTicketById(String id) async {
    try {
      return await _repository.getTicketById(id);
    } catch (e) {
      return null;
    }
  }
}
