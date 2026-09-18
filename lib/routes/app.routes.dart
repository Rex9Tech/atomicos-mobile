// lib/routes/app_routes.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rexone_mobile/config/config.dart';
import 'package:rexone_mobile/routes/guard.routes.dart';
import 'package:rexone_mobile/routes/server.routes.dart';

import '../modules/ai/ai.dart';
import '../modules/atom_create/atom_create.dart';
import '../modules/atom_details/atom_details.dart';
import '../modules/auth/auth.dart';
import '../modules/calendar/calendar.dart';
import '../modules/home/home.dart';
import '../modules/live_activity/live_activity.dart';
import '../modules/search/search.dart';
import '../modules/payment/payment.dart';
import '../modules/profile/profile.dart';
import '../modules/setting/setting.dart';
import '../modules/notification/notification.dart';
import '../modules/permission/permission.dart';
import '../modules/splash/splash.dart';

class AppRoutes {
  // ===== SERVER ROUTES =====
  static const server = ServerRoutes;

  // ===== PUBLIC ROUTES (No Auth Required) =====
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String signinPassword = '/signin-password';
  static const String signupPasswordCreate = '/signup-password-create';
  static const String signupPasswordConfirm = '/signup-password-confirm';
  static const String signupInfo = '/signup-info';
  static const String confirmEmail = '/confirm-email';
  static const String forgotPassword = '/forgot-password';

  // ===== PROTECTED ROUTES (Auth Required) =====
  static const String home = '/home';
  static const String atomCreate = '/atom-create';
  static const String atomDetail = '/atom-detail';
  static const String calendar = '/calendar';
  static const String settings = '/settings';
  static const String payment = '/payment';
  static const String checkout = '/checkout';
  static const String ai = '/ai';
  static const String liveActivity = '/live-activity';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String permissionOnboarding = '/permission-onboarding';

  // ===== PUBLIC NAVIGATION =====
  static void toSplash() => Get.offAllNamed(splash);
  static void toAuth() => Get.offAllNamed(auth);
  static void toSignInPassword() => Get.toNamed(signinPassword);
  static void toSignUpPasswordCreate() => Get.toNamed(signupPasswordCreate);
  static void toSignUpPasswordConfirm() => Get.toNamed(signupPasswordConfirm);
  static void toSignUpInfo({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    Get.toNamed(
      signupInfo,
      arguments: {
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }

  static void toConfirmEmail({required String email}) {
    Get.toNamed(confirmEmail, arguments: {'email': email});
  }

  static void toForgotPassword() => Get.toNamed(forgotPassword);

  // ===== PROTECTED NAVIGATION =====
  static void toHome() => Get.offAllNamed(home);
  static void toAtomCreate({String mode = 'import'}) =>
      Get.toNamed(atomCreate, arguments: {'mode': mode});
  static void toAtomCreateShare({required String text}) =>
      Get.toNamed(atomCreate, arguments: {'mode': 'share', 'share_text': text});
  static void toAtomCreateFile({required String path}) =>
      Get.toNamed(atomCreate, arguments: {'mode': 'import', 'share_file': path});
  /// Opens atom details. Pass [replace] to swap the current screen out of the
  /// stack — after a recording finishes, so Back returns to where the
  /// recording started instead of the (now finished) recording sheet.
  static void toAtomDetail({required String atomId, bool replace = false}) {
    final arguments = {'atom_id': atomId};
    if (replace) {
      Get.offNamed(atomDetail, arguments: arguments);
      return;
    }
    Get.toNamed(atomDetail, arguments: arguments);
  }
  static void toCalendar() => Get.toNamed(calendar);
  static void toSettings() => Get.toNamed(settings);
  static void toPayment() => Get.toNamed(payment);
  static void toCheckout({required String url}) =>
      Get.toNamed(checkout, arguments: {'url': url});
  static void toAi({
    String mode = 'auto',
    String? atomId,
    String? atomTitle,
  }) => Get.toNamed(
    ai,
    arguments: {
      'mode': mode,
      if (atomId != null && atomId.isNotEmpty) 'atom_id': atomId,
      if (atomTitle != null && atomTitle.isNotEmpty) 'atom_title': atomTitle,
    },
  );
  static void toLiveActivity() => Get.toNamed(liveActivity);

  /// Dedicated search screen; the fade keeps the eye on the search bar, which
  /// morphs across via its hero tag.
  static void toSearch() => Get.toNamed(search);
  static void toProfile() => Get.toNamed(profile);
  static void toNotifications() => Get.toNamed(notifications);
  static void toPermissionOnboarding() => Get.toNamed(permissionOnboarding);

  /// Resolves and routes a notification or deep link.
  ///
  /// - Links matching internal stacked routes (Payment, AI, Settings, Home, Notifications)
  ///   keep the user inside the app and route to the corresponding native screen.
  /// - Links not matching any mobile stacked routes (e.g. external websites, web-only admin paths)
  ///   are launched in the external system browser via [url_launcher].
  static Future<void> handleNotificationLink(String? rawLink) async {
    if (rawLink == null) return;
    final link = rawLink.trim();
    if (link.isEmpty) return;

    try {
      final uri = Uri.tryParse(link);
      final hasScheme =
          uri != null && (uri.isScheme('http') || uri.isScheme('https'));
      final path = hasScheme ? uri.path.toLowerCase() : link.toLowerCase();

      final normalizedPath = (path.length > 1 && path.endsWith('/'))
          ? path.substring(0, path.length - 1)
          : path;

      // 1. Payment & Billing (keep in app without leaving or opening checkout webview)
      if (_matchesPaymentRoute(normalizedPath)) {
        toPayment();
        return;
      }

      // 2. AI / Chat
      if (_matchesAiRoute(normalizedPath)) {
        toAi();
        return;
      }

      // 3. Settings & Profile
      if (_matchesSettingsRoute(normalizedPath)) {
        toSettings();
        return;
      }

      // 4. Notifications
      if (_matchesNotificationsRoute(normalizedPath)) {
        toNotifications();
        return;
      }

      // 5. Home / Root
      if (normalizedPath == '/' || normalizedPath == home) {
        toHome();
        return;
      }

      // 6. Any other registered mobile page in AppRoutes
      if (normalizedPath.startsWith('/')) {
        final matchesRegistered = pages.any(
          (p) => p.name.toLowerCase() == normalizedPath,
        );
        if (matchesRegistered) {
          Get.toNamed(normalizedPath);
          return;
        }
      }

      // 7. Unmatched link -> launch in external browser
      final targetUri = hasScheme
          ? uri
          : Uri.tryParse(
              '${_getWebBaseUrl()}${normalizedPath.startsWith('/') ? normalizedPath : '/$normalizedPath'}',
            );

      if (targetUri != null) {
        final launched = await launchUrl(
          targetUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          debugPrint('⚠️ Could not launch external URL: $targetUri');
        }
        return;
      }

      debugPrint('⚠️ Unhandled notification link: $link');
    } catch (e) {
      debugPrint('❌ Error routing notification link: $e');
    }
  }

  static bool _matchesPaymentRoute(String path) {
    return path == payment ||
        path.startsWith('/payment') ||
        path.startsWith('/checkout') ||
        path.startsWith('/pricing') ||
        path.startsWith('/subscription') ||
        path.startsWith('/transaction') ||
        path.startsWith('/invoice');
  }

  static bool _matchesAiRoute(String path) {
    return path == ai || path.startsWith('/ai') || path.startsWith('/chat');
  }

  static bool _matchesSettingsRoute(String path) {
    return path == settings ||
        path.startsWith('/settings') ||
        path.startsWith('/profile') ||
        path.startsWith('/account');
  }

  static bool _matchesNotificationsRoute(String path) {
    return path == notifications || path.startsWith('/notification');
  }

  static String _getWebBaseUrl() {
    final api = AppConfig.apiBaseUrl;
    if (api.contains('localhost:3000')) {
      return 'http://localhost:4000';
    } else if (api.contains('10.0.2.2:3000')) {
      return 'http://10.0.2.2:4000';
    } else if (api.contains('api.')) {
      return api.replaceFirst('api.', '');
    }
    return 'https://rexone.org';
  }


  static final pages = [
    // Public Pages
    GetPage(
      name: splash,
      page: () => const SplashPage(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(name: auth, page: () => AuthPage()),
    GetPage(name: signinPassword, page: () => const SignInPasswordPage()),
    GetPage(
      name: signupPasswordCreate,
      page: () => const SignUpPasswordCreatePage(),
    ),
    GetPage(
      name: signupPasswordConfirm,
      page: () => const SignUpPasswordConfirmPage(),
    ),
    GetPage(name: signupInfo, page: () => const SignUpInfoPage()),
    GetPage(name: confirmEmail, page: () => const ConfirmEmailPage()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordPage()),

    // Protected Pages
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: search,
      page: () => const SearchPage(),
      binding: BindingsBuilder(() {
        // Built eagerly (like HomeController) so onInit runs in the binding
        // phase, not during the page's first build.
        Get.put(AtomSearchController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 260),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: atomCreate,
      page: () => const AtomCreatePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AtomCreateController>(() => AtomCreateController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: atomDetail,
      page: () => const AtomDetailsPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AtomDetailsController>(() => AtomDetailsController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: calendar,
      page: () => const CalendarPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CalendarController>(() => CalendarController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: settings,
      page: () => const SettingPage(),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: payment,
      page: () => const PaymentPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PaymentController>(() => PaymentController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: checkout,
      page: () => const CheckoutWebViewPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CheckoutController>(() => CheckoutController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: ai,
      page: () => const AiPage(),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: liveActivity,
      page: () => const LiveActivityPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LiveActivityController>(() => LiveActivityController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: profile,
      page: () => const ProfilePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NotificationController>(() => NotificationController());
      }),
      middlewares: [GuardRoutes()],
    ),
    GetPage(
      name: permissionOnboarding,
      page: () => const PermissionOnboardingPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PermissionOnboardingController>(
          () => PermissionOnboardingController(),
        );
      }),
      middlewares: [GuardRoutes()],
    ),
  ];

  static final notFound = GetPage(
    name: '/404',
    page: () => const HomePage(),
    middlewares: [GuardRoutes()],
  );
}
