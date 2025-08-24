class SeriesPoint {
  final DateTime time;
  final double value;

  SeriesPoint(this.time, this.value);
}

class SeriesFetchResult {
  final List<SeriesPoint> points;
  final int? totalCount;
  SeriesFetchResult({required this.points, required this.totalCount});
}
