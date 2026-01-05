import 'package:flutter/material.dart';
import 'dart:async';

import '../utils/theme.dart';

class GsocCountdown extends StatefulWidget {
  const GsocCountdown({super.key});

  @override
  State<GsocCountdown> createState() => _GsocCountdownState();
}

class _GsocCountdownState extends State<GsocCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  // Approximate GSoC 2026 start date (usually early March)
  final DateTime _gsocDate = DateTime(2026, 3, 1);

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    setState(() {
      _remaining = _gsocDate.difference(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'GSoC 2026 Countdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeUnit(context, days.toString(), 'Days'),
                _buildTimeUnit(context, hours.toString().padLeft(2, '0'), 'Hours'),
                _buildTimeUnit(
                    context, minutes.toString().padLeft(2, '0'), 'Mins'),
                _buildTimeUnit(
                    context, seconds.toString().padLeft(2, '0'), 'Secs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(BuildContext context, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
