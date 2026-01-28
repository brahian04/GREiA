import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/ai_service.dart';

// --- STATE ---
abstract class AiState extends Equatable {
  const AiState();
  @override
  List<Object> get props => [];
}

class AiInitial extends AiState {}

class AiLoading extends AiState {}

class AiLoaded extends AiState {
  final String response;
  const AiLoaded(this.response);
  @override
  List<Object> get props => [response];
}

class AiError extends AiState {
  final String message;
  const AiError(this.message);
  @override
  List<Object> get props => [message];
}

// --- CUBIT ---
class AiCubit extends Cubit<AiState> {
  final AiService _service;

  AiCubit(this._service) : super(AiInitial());

  Future<void> sendMessage(String message, {String? context}) async {
    emit(AiLoading());
    try {
      final reply = await _service.sendMessage(message, context: context);
      emit(AiLoaded(reply));
    } catch (e) {
      emit(AiError(e.toString()));
    }
  }
}
