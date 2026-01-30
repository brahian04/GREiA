import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/ai_service.dart';

// --- STATE ---
abstract class AiState extends Equatable {
  const AiState();
  @override
  List<Object?> get props => [];
}

class AiInitial extends AiState {}

class AiLoading extends AiState {}

class AiLoaded extends AiState {
  final String response;
  final String? action;
  final Map<String, dynamic>? actionData;

  const AiLoaded(this.response, {this.action, this.actionData});

  @override
  List<Object?> get props => [response, action, actionData];
}

class AiError extends AiState {
  final String message;
  const AiError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- CUBIT ---
class AiCubit extends Cubit<AiState> {
  final AiService _service;

  AiCubit(this._service) : super(AiInitial());

  Future<void> sendMessage(String message, {String? context}) async {
    emit(AiLoading());
    try {
      final result = await _service.sendMessage(message, context: context);
      emit(AiLoaded(result.reply,
          action: result.action, actionData: result.actionData));
    } catch (e) {
      emit(AiError(e.toString()));
    }
  }
}
