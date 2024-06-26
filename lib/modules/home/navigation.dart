import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inlaze/core/utils/extension/extension.dart';

import '../../config/routes/cubit/router_manager.dart';
import '../../core/services/analytic.dart';

class HomeNavigation extends Cubit<void> {
  HomeNavigation({required this.navigation}) : super(null);
  late RouterManager navigation;

  void pop() {
    navigation.pop();
  }

  void push(String route, {Object? extra}) {
    navigation.push(route, extra: extra);
  }

  void go(String route, {Object? extra}) {
    navigation.go(route, extra: extra);
  }

  void navigateCatDetails(
    String route, {
    required String? isbn13,
    required String heroTag,
  }) {
    Map<String, dynamic> params = {
      'isbn13': isbn13,
    };
    if (isWeb) {
      navigation.go('${route.toParamUrl(params)}', extra: {
        'heroTag': heroTag,
      });
    } else {
      navigation.push('${route.toParamUrl(params)}', extra: {
        'heroTag': heroTag,
      });
    }
  }
}
