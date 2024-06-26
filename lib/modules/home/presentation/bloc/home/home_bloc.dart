import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../core/error/error.dart';
import '../../../../../core/services/local_storage.dart';
import '../../../../../core/utils/helpers.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/home_usecases.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeUseCase _homeUseCase;
  final LocalStorage _localStorage;
  late OverlayEntry loader;
  late Debouncer debouncer;
  HomeBloc({
    required HomeUseCase homeUseCase,
    required LocalStorage localStorage,
  })  : _homeUseCase = homeUseCase,
        _localStorage = localStorage,
        debouncer = Debouncer(),
        super(const _Initial()) {
    loader = Overloading.instance.overLayEntry();
    on<_Init>(_init);
    on<_GetBookNew>(_getBookNew);
    on<_RefreshBooks>(_refreshBooks);
    on<_Invalidate>(_invalidate);
    on<_Search>(_search);
    on<_GetBookSearh>(_getBookSerch);
    on<_RemoveHistory>(_removeHistory);
  }

  late ScrollController scrollController;
  int limit = 20;
  int offset = 0;

  void _invalidate(_Invalidate event, Emitter<HomeState> emit) {
    emit(state.copyWith(failure: null));
  }

  Future<void> refreshList() async {
    add(const _RefreshBooks());
  }

  Future<void> _init(_Init event, Emitter<HomeState> emit) async {
    final historyList = await _localStorage.getHistoryList();
    emit(state.copyWith(historyList: historyList));

    add(const _GetBookNew());
    _initScrollController();
  }

  Future<void> _refreshBooks(
      _RefreshBooks event, Emitter<HomeState> emit) async {
    add(const _GetBookNew());
  }

  void _initScrollController() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      bool scrollEnd = scrollController.position.pixels ==
          scrollController.position.maxScrollExtent;
      if (scrollEnd && !state.isDone) {
        add(const _GetBookNew(isLoading: false, isDone: true));
      }
    });
  }

  void scrollUp() {
    const double start = 0;
    // scrollController.jumpTo(start);
    scrollController.animateTo(
      start,
      duration: const Duration(seconds: 1),
      curve: Curves.easeIn,
    );
  }

  Future<void> _getBookNew(_GetBookNew event, Emitter<HomeState> emit) async {
    offset++;
    emit(state.copyWith(isLoading: event.isLoading, isDone: event.isDone));
    final either = await _homeUseCase.getBookNew();
    switch (either) {
      case Left(value: Failure failure):
        emit(state.copyWith(failure: failure, isLoading: false, isDone: false));
      case Right(value: List<BookEntity> books):
        emit(state.copyWith(
          books: books,
          isLoading: false,
          isDone: false,
        ));
    }
  }

  Future<void> _removeHistory(
      _RemoveHistory event, Emitter<HomeState> emit) async {
    final historyList = await _localStorage.getHistoryList();
    historyList.remove(event.history);
    _localStorage.saveHistoryList(historyList);
    emit(state.copyWith(historyList: historyList));
  }

  Future<void> _getBookSerch(
      _GetBookSearh event, Emitter<HomeState> emit) async {
    final historyList = state.historyList.toList();
    final newList = <String>[];

    final isExist = historyList.contains(event.search);
    debugPrint('lista: ${historyList.length}');

    if (!isExist) {
      if (state.historyList.length < 5) {
        newList.insert(0, event.search);
        newList.addAll(historyList);
      } else {
        newList.insert(0, event.search);
        historyList.removeLast();
        newList.addAll(historyList);
      }
    } else {
      if (state.historyList.length < 5) {
        newList.insert(0, event.search);
        historyList.remove(event.search);
        newList.addAll(historyList);
      } else {
        newList.insert(0, event.search);
        historyList.remove(event.search);
        newList.addAll(historyList);
      }
    }
    _localStorage.saveHistoryList(newList);

    emit(state.copyWith(
      isLoading: true,
      historyList: newList,
    ));

    final either = await _homeUseCase.getBookSearch(event.search);
    switch (either) {
      case Left(value: Failure failure):
        emit(state.copyWith(failure: failure, isLoading: false));
      case Right(value: List<BookEntity> books):
        emit(state.copyWith(
          searchBooks: books,
          isLoading: false,
          searchResult: event.search,
        ));
    }
  }

  Future<void> _search(_Search event, Emitter<HomeState> emit) async {
    debouncer.execute(() {
      if (event.search.isNotEmpty) {
        add(_GetBookSearh(search: event.search));
      } else {
        add(const _GetBookNew());
      }
    });
  }
}

class Debouncer {
  Timer? timer;

  void execute(VoidCallback action) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 500), action);
  }
}
