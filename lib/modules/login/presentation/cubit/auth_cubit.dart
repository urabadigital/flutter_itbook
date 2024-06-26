import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/local_storage.dart';
import '../../data/models/models.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/login_usecases.dart';

part 'auth_state.dart';
part 'auth_cubit.freezed.dart';

class AuthCubit extends Cubit<AuthState> {
  final LocalStorage _localStorage;
  final LoginUseCase _loginUseCase;

  AuthCubit({
    required LocalStorage localStorage,
    required LoginUseCase loginUseCase,
  })  : _localStorage = localStorage,
        _loginUseCase = loginUseCase,
        super(const _Initial());

  void invalidate() {
    emit(state.copyWith(error: false));
  }

  bool validate(String username, String password) {
    if (username.isNotEmpty && password.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<String> getUserName() async {
    return await _localStorage.getUserLoginUserName();
  }

  Future<String> getPassword() async {
    return await _localStorage.getUserLoginPass();
  }

  Future<void> createUser(String username, String password) async {
    if (!validate(username, password)) {
      emit(state.copyWith(
        error: true,
        message: 'get_into'.tr(),
      ));
    } else {
      UserEntity? user = await _loginUseCase.findUserByName(username);
      if ((user?.name.isNotEmpty ?? false) &&
          (user?.password.isNotEmpty ?? false)) {
        emit(state.copyWith(error: true, message: 'existing_user'.tr()));
        return;
      } else {
        UserModel user = UserModel(name: username, password: password);
        final id = await _loginUseCase.insertUser(user);
        user =
            UserEntity(name: username, password: password, id: id) as UserModel;
        emit(state.copyWith(error: true, message: 'create_user'.tr()));
      }
    }
  }

  Future<void> login(String username, String password) async {
    if (!validate(username, password)) {
      emit(state.copyWith(
        error: true,
        message: 'get_into'.tr(),
      ));
      return;
    }
    UserEntity? user = await _loginUseCase.findUserByName(username);

    if ((user?.name.isEmpty ?? false) && (user?.password.isEmpty ?? false)) {
      emit(state.copyWith(error: true, message: 'not_found_user'.tr()));
      return;
    }

    if (user?.password == password) {
      _localStorage.saveUserLoginUserName(username);
      _localStorage.saveUserLoginPass(password);
      emit(state.copyWith(success: true));
    } else {
      emit(state.copyWith(error: true, message: 'invalid_credentials'.tr()));
    }
  }
}
