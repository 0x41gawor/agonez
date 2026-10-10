import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers.dart';

class RecordedScreen extends ConsumerWidget {
  const RecordedScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });
  final String workoutId;
  final String workoutName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider(workoutId)).value;
    final synced = workout?.status == 'finalized';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(
                synced ? Icons.check_circle : Icons.phone_android,
                color: synced ? AgonezColors.success : AgonezColors.warning,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                '$workoutName recorded',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 14),
              Text(
                synced
                    ? 'Synced and finalised.'
                    : 'Saved on this phone — it will be finalised when you’re back online.',
                style: TextStyle(
                  color: synced ? AgonezColors.success : AgonezColors.warning,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref.invalidate(contextProvider);
                  context.go('/home');
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
