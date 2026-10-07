// lib/routes/home.resume.observer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/home/home.dart';

import 'app.routes.dart';

/// Refreshes the home surface whenever it becomes the visible route again
/// (returning from the create / details / molecule flows). A safety net so
/// home items stay current even when a socket event was missed while the
/// user was elsewhere.
class HomeResumeObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _refreshIfHome(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _refreshIfHome(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _refreshIfHome(newRoute);
  }

  void _refreshIfHome(Route<dynamic>? route) {
    if (route?.settings.name != AppRoutes.home) return;
    if (!Get.isRegistered<HomeController>()) return;

    // Deferred a frame: observer callbacks run mid-navigation, and the
    // refresh mutates Rx state the home page is watching.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<HomeController>()) return;
      Get.find<HomeController>().onHomeVisible();
    });
  }
}
