import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/presentation/auth_controller.dart';

/// Settings / profile hub. Settings entries gated by show_* flags.
class MorePlaceholderPage extends ConsumerWidget {
  const MorePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final showSettings = auth.showAnySettings;
    final loggingOut = auth.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user.name.isEmpty ? user.email : user.name),
              subtitle: Text(
                [
                  user.email,
                  if (user.role != null) user.role!,
                ].join(' · '),
              ),
            ),
          if (showSettings) ...[
            const Divider(),
            if (auth.show5sAuditSettings)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('5S Audit settings'),
                subtitle: const Text('Grades, types, sections, questions'),
                onTap: () => context.push(AppRoutes.fiveSSettings),
              ),
            if (auth.showActionPlanSettings || auth.show5sAuditSettings)
              ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: const Text('Action plan settings'),
                subtitle: const Text('Due-day defaults by priority'),
                onTap: () => context.push(AppRoutes.actionPlanSettings),
              ),
          ],
          const Divider(),
          ListTile(
            leading: loggingOut
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            title: const Text('Sign out'),
            enabled: !loggingOut,
            onTap: loggingOut
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
