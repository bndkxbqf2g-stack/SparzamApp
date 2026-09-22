import 'package:flutter/material.dart';

import 'route_recommendation.dart';

class RouteRecommendationCard extends StatelessWidget {
  const RouteRecommendationCard({
    super.key,
    required this.info,
    required this.travelLabel,
    required this.mobilityLabel,
  });

  final RouteRecommendationInfo info;
  final String travelLabel;
  final String mobilityLabel;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(info.detail),
              const SizedBox(height: 8),
              Text(
                '$mobilityLabel · geschätzte Wegezeit $travelLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}
