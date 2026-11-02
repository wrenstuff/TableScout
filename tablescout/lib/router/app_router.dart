import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/pages/login_page.dart';
import 'package:tablescout/pages/signup_page.dart';
import 'package:tablescout/widgets/nav_bar.dart';
import 'package:tablescout/pages/password_recovery_page.dart';
import 'package:tablescout/pages/recover_code_page.dart';

class AppRouter {
  final SessionManager sessionManager;

  late final GoRouter router;

  AppRouter(this.sessionManager) {
    router = GoRouter(
      initialLocation: '/login',

      //Re-evaluate routes when session changes
      refreshListenable: sessionManager,

      redirect: (context, state) {
        final isLoggedIn = sessionManager.isLoggedIn;
        final location = state.matchedLocation;

        final isLoggingIn = location == '/login';
        final isSigningUp = location == '/signup';
        final isPasswordRecovery = location == '/password-recovery';
        final isRecoverCode = location == '/recover-code';


        
        if(!isLoggedIn && !isLoggingIn && !isSigningUp && !isPasswordRecovery && !isRecoverCode) {
          return '/login';
        }

        if (isLoggedIn && (isLoggingIn || isSigningUp || isPasswordRecovery || isRecoverCode)) {
          return '/app';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/login',
          pageBuilder:(context, state) => const NoTransitionPage(
            child: LoginPage(),
          ),
        ),

        GoRoute(
          path: '/signup',
          pageBuilder:(context, state) => const NoTransitionPage(
            child: SignupPage(),
          ),
        ),

        GoRoute(
          path: '/app',
          pageBuilder:(context, state) => const NoTransitionPage(
            child: NavBar(),
          ),
        ),
        GoRoute(
          path: '/password-recovery',
          pageBuilder:(context, state) => const NoTransitionPage(
            child: PasswordRecoveryPage(),
          ),
        ),
        GoRoute(
          path: '/recover-code',
          pageBuilder:(context, state) => const NoTransitionPage(
            child: RecoverCodePage(),
          ),
        )
      ],

      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The requrested page could not be found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(
                  sessionManager.isLoggedIn ? '/app' : '/login', 
                ),
                child: const Text('return to safety'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}