import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/walks_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../models/walk.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class WalkScreen extends StatefulWidget {
  final List<Dog> dogs;
  final WalksRepository repository;

  const WalkScreen({super.key, required this.dogs, required this.repository});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  late String _selectedDogId = widget.dogs.first.id;

  @override
  void initState() {
    super.initState();
    widget.repository.loadWalks(_selectedDogId);
  }

  void _selectDog(String dogId) {
    setState(() => _selectedDogId = dogId);
    widget.repository.loadWalks(dogId);
  }

  Future<void> _toggleRecording() async {
    final repo = widget.repository;
    if (repo.isRecording) {
      try {
        await repo.stopRecording(_selectedDogId);
      } catch (e) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveWalkFailed('$e'))),
        );
      }
    } else {
      await repo.startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final repo = widget.repository;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(l10n.walkTitle, style: AppText.display),
            const SizedBox(height: 18),
            Row(
              children: widget.dogs.map((dog) {
                final selected = dog.id == _selectedDogId;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: dog == widget.dogs.first ? 8 : 0),
                    child: OutlinedButton(
                      onPressed: repo.isRecording ? null : () => _selectDog(dog.id),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected ? dog.accent.withValues(alpha: 0.1) : Colors.white,
                        side: BorderSide(
                          color: selected ? dog.accent : AppColors.ink.withValues(alpha: 0.12),
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(dog.name, style: AppText.body),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _WalkMapCard(points: repo.currentPoints, pastWalks: repo.walks),
            const SizedBox(height: 12),
            if (repo.recordingError != null) ...[
              _LocationErrorBanner(error: repo.recordingError!),
              const SizedBox(height: 12),
            ],
            if (repo.isRecording) ...[
              _LiveStats(repository: repo),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: repo.isRecording ? AppColors.concernBorder : AppColors.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  repo.isRecording ? l10n.stopWalk : l10n.startWalk,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(l10n.recommendedCourses, style: AppText.eyebrow),
            const SizedBox(height: 10),
            _RecommendedCoursesSection(repository: repo),
            const SizedBox(height: 28),
            Text(l10n.walkHistory, style: AppText.eyebrow),
            const SizedBox(height: 10),
            _WalkHistoryList(repository: repo),
          ],
        );
      },
    );
  }
}

class _WalkMapCard extends StatelessWidget {
  final List<GeoPoint> points;
  final List<WalkRoute> pastWalks;

  const _WalkMapCard({required this.points, required this.pastWalks});

  @override
  Widget build(BuildContext context) {
    final activePoints = points.isNotEmpty
        ? points
        : (pastWalks.isNotEmpty ? pastWalks.first.points : const <GeoPoint>[]);

    if (activePoints.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: Icon(Icons.map_outlined, size: 40, color: AppColors.ink.withValues(alpha: 0.2)),
          ),
        ),
      );
    }

    final latLngs = activePoints.map((p) => LatLng(p.lat, p.lng)).toList();
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(initialCenter: latLngs.last, initialZoom: 16),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dogapp.flutter',
            ),
            PolylineLayer(
              polylines: [Polyline(points: latLngs, strokeWidth: 4, color: AppColors.marigold)],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latLngs.last,
                  width: 20,
                  height: 20,
                  child: const Icon(Icons.circle, color: AppColors.concernBorder, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStats extends StatelessWidget {
  final WalksRepository repository;

  const _LiveStats({required this.repository});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final km = repository.currentDistanceMeters / 1000;
    final duration = repository.currentDuration;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: l10n.distance, value: '${km.toStringAsFixed(2)} ${l10n.km}'),
          _Stat(label: l10n.duration, value: _formatDuration(duration)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 4),
        Text(value, style: AppText.mono),
      ],
    );
  }
}

class _LocationErrorBanner extends StatelessWidget {
  final Object error;

  const _LocationErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = error is LocationServiceException
        ? ((error as LocationServiceException).reason == LocationFailure.serviceDisabled
            ? l10n.locationServiceDisabled
            : l10n.locationPermissionDenied)
        : '$error';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.concernBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.concernBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, size: 18, color: AppColors.concernBorder),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppText.body)),
        ],
      ),
    );
  }
}

class _RecommendedCoursesSection extends StatelessWidget {
  final WalksRepository repository;

  const _RecommendedCoursesSection({required this.repository});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courses = repository.recommendedCourses();
    if (courses.isEmpty) {
      return Text(l10n.noRecommendationsYet, style: AppText.bodySoft);
    }
    return Column(
      children: courses
          .map((course) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route_outlined, size: 18, color: AppColors.inkSoft),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.walkedNTimes(course.walkCount), style: AppText.body),
                            Text(
                              '${(course.averageDistanceMeters / 1000).toStringAsFixed(2)} ${l10n.km}',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _WalkHistoryList extends StatelessWidget {
  final WalksRepository repository;

  const _WalkHistoryList({required this.repository});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (repository.isLoading && repository.walks.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (repository.error != null && repository.walks.isEmpty) {
      return Text(l10n.loadWalksFailed('${repository.error}'), style: AppText.bodySoft);
    }
    if (repository.walks.isEmpty) {
      return Text(l10n.noWalksYet, style: AppText.bodySoft);
    }
    return Column(
      children: repository.walks
          .map((walk) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 18, color: AppColors.inkSoft),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${walk.startedAt.month}/${walk.startedAt.day}', style: AppText.body),
                            Text(
                              '${(walk.distanceMeters / 1000).toStringAsFixed(2)} ${l10n.km} ・ '
                              '${walk.duration.inMinutes}${l10n.minutesShort}',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
