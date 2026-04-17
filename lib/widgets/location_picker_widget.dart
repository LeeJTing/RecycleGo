import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/services/station_service.dart';
import 'package:recycle_go/models/RecycleStations.dart';

class LocationPickerWidget extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;
  final Function(RecycleStation selectedStation) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late Future<List<StationWithDistance>> _stationsFuture;
  RecycleStation? _selectedStation;

  @override
  void initState() {
    super.initState();
    _stationsFuture = StationService.getNearestStations(
      widget.userLatitude,
      widget.userLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 20, color: theme.primary),
              const SizedBox(width: 8),
              Text('Select Pickup Location', style: TextDesign.label()),
            ],
          ),
        ),

        // Loading / Error / Stations List
        FutureBuilder<List<StationWithDistance>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: theme.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.error.withOpacity(0.3)),
                ),
                child: Text(
                  'Error loading pickup locations',
                  style: TextDesign.smallText(color: theme.error),
                ),
              );
            }

            final stations = snapshot.data ?? [];

            if (stations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No pickup locations available',
                  style: TextDesign.smallText(color: Colors.grey[600]),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.primary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stations.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: theme.primary.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final stationWithDist = stations[index];
                  final station = stationWithDist.station;
                  final isSelected =
                      _selectedStation?.stationId == station.stationId;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStation = station;
                      });
                      widget.onLocationSelected(station);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primary.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          // Radio button
                          Radio<String>(
                            value: station.stationId,
                            groupValue: _selectedStation?.stationId,
                            onChanged: (value) {
                              setState(() {
                                _selectedStation = station;
                              });
                              widget.onLocationSelected(station);
                            },
                            activeColor: theme.primary,
                          ),
                          const SizedBox(width: 8),

                          // Station details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Station name + distance
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        station.stationName,
                                        style: TextDesign.normalText(
                                          color: isSelected
                                              ? theme.primary
                                              : Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        stationWithDist.distanceText,
                                        style: TextDesign.smallText(
                                          color: theme.primary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Address
                                Text(
                                  station.address,
                                  style: TextDesign.smallText(
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        // Show selected station info
        if (_selectedStation != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: theme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup at',
                        style: TextDesign.smallText(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _selectedStation!.stationName,
                        style: TextDesign.normalText(color: theme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
