import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/api_exception.dart';
import '../../../domain/repositories/conversation_repository.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc(this._repository) : super(const ConversationInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
  }

  final ConversationRepository _repository;

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(const ConversationLoading());
    await _fetch(emit);
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ConversationState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<ConversationState> emit) async {
    try {
      final list = await _repository.getMyConversations();
      emit(ConversationLoaded(list));
    } catch (e) {
      emit(ConversationError(ApiException.cleanMessage(e)));
    }
  }
}
