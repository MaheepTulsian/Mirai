import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../widgets/roadmap_card.dart';
import 'roadmap_detail_screen.dart';

class RoadmapsScreen extends StatefulWidget {
  const RoadmapsScreen({super.key});

  @override
  State<RoadmapsScreen> createState() => _RoadmapsScreenState();
}

class _RoadmapsScreenState extends State<RoadmapsScreen> {
  @override
  void initState() {
    super.initState();
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('roadmaps');
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return StreamBuilder(
      stream: firebaseService.getRoadmaps(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No roadmaps available'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final roadmap = snapshot.data![index];
            return RoadmapCard(
              roadmap: roadmap,
              onTap: () {
                analytics.logRoadmapOpen(roadmap.name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoadmapDetailScreen(roadmap: roadmap),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
