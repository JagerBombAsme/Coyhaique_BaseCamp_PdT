import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/providers/auth_provider.dart';

class AuthGatewayView extends ConsumerWidget {
  const AuthGatewayView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(authRepositoryProvider);

    return StreamBuilder<AuthState>(
      stream: repository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingView();
        }

        final session = repository.currentSession;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          if (session == null) {
            context.go('/auth');
          } else {
            context.go('/home');
          }
        });

        return const _AuthLoadingView();
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF211F22),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}