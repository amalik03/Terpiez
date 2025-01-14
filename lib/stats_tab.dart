import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/user_state_model.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, model, child) => Scaffold(
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
            child: Center(
              child: Text(
                "Statistics",
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
            child: Text(
              "Terpiez Captured: ${model.terpiezCount}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
            child: Text(
              "Days Active: ${model.daysActive}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 100.0, 15.0, 0.0),
            child: Center(
              child: Text(
                "User: ${model.userId}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
