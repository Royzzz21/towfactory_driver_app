import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/api_exception.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._repository) : super(const ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<RefreshChats>(_onRefreshChats);
  }

  final ChatRepository _repository;

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    await _fetch(emit);
  }

  Future<void> _onRefreshChats(
    RefreshChats event,
    Emitter<ChatState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<ChatState> emit) async {
    try {
      final result = await _repository.getMyChats();
      emit(ChatLoaded(result.data));
    } catch (e) {
      emit(ChatError(ApiException.cleanMessage(e)));
    }
  }
}
