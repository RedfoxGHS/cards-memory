import 'package:flutter/material.dart';

class PracticeSummaryScreen extends StatelessWidget {
  final int correct;
  final int wrong;
  final int total;

  const PracticeSummaryScreen({
    super.key,
    required this.correct,
    required this.wrong,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : ((correct / total) * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pct >= 70 ? Icons.emoji_events : Icons.self_improvement,
                size: 80,
                color: pct >= 70 ? Colors.amber : Colors.blueGrey,
              ),
              const SizedBox(height: 16),
              Text(
                '$pct% de acerto',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(label: 'Acertos', value: correct, color: Colors.green),
                  const SizedBox(width: 16),
                  _StatChip(label: 'Erros', value: wrong, color: Colors.red),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}
