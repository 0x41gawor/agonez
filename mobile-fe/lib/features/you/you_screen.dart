import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider).value;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('You', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 28),
          const Text(
            'ACTIVE PLAN RUN',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AgonezColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('Selected on this phone'),
              subtitle: Text('Plan-run context is local in v1'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'WORKOUT',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AgonezColors.muted,
            ),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Haptics'),
            subtitle: const Text('Set confirmations and timer completion'),
          ),
          const ListTile(
            title: Text('Rest timer'),
            subtitle: Text('Uses absolute timestamps and survives restart'),
            trailing: Text('On'),
          ),
          const SizedBox(height: 22),
          const Text(
            'SYNC',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AgonezColors.muted,
            ),
          ),
          ListTile(
            leading: Icon(
              active == null || active.status == 'active'
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off,
              color: active == null || active.status == 'active'
                  ? AgonezColors.success
                  : AgonezColors.warning,
            ),
            title: Text(active == null ? 'Nothing pending' : active.status),
            subtitle: const Text('Device identity is installation-stable'),
            trailing: TextButton(
              onPressed: () async =>
                  (await ref.read(syncProvider.future)).synchronize(),
              child: const Text('Retry'),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Agonez Mobile'),
            subtitle: Text('1.0.0 · Android development build'),
          ),
        ],
      ),
    );
  }
}
