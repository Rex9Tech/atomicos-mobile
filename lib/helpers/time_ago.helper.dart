// lib/helpers/time_ago.helper.dart

/// Short relative-time label used by notification surfaces ("5m ago").
String formatTimeAgo(DateTime dateTime, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final d = dateTime.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
