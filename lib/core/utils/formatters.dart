import 'package:intl/intl.dart';

String formatBytes(int bytes) {
  if (bytes >= 1000000000) {
    return '${(bytes / 1000000000).toStringAsFixed(2)} GB';
  }
  if (bytes >= 1000000) {
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1000) {
    return '${(bytes / 1000).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}

String formatTime(int millisSinceEpoch) =>
    DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch));

String formatDate(int millisSinceEpoch) =>
    DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch));

String formatRelative(int millisSinceEpoch) {
  final then = DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
  final diff = DateTime.now().difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 30) return '${diff.inDays} d ago';
  return formatDate(millisSinceEpoch);
}
