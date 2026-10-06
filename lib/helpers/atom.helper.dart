// lib/helpers/atom.helper.dart
//
// Shared atom presentation helpers — one source of truth for how atoms'
// dates, durations, sources and statuses render across surfaces (home/search
// cards and the inline rows under expanded molecules on home).
import 'package:flutter/material.dart';
import 'package:rexone_mobile/design/design.dart';

/// Icon for an atom's source (note/url/share/asset/meeting).
IconData atomSourceIcon(String source) {
  switch (source.toLowerCase()) {
    case 'url':
      return Design.icons.link;
    case 'share':
      return Design.icons.shareIos;
    case 'asset':
      return Design.icons.attachment;
    case 'meeting':
      return Design.icons.mic;
    default:
      return Design.icons.note;
  }
}

/// "Oct 6" — short month + day in local time ('' when unparsable).
String atomShortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

/// "06:30" — 24-hour local time ('' when unparsable).
String atomShortTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// "24s" / "2m" / "1h 5m" — compact duration ('' when none).
String atomCompactDuration(int? secs) {
  if (secs == null || secs <= 0) return '';
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '${secs}s';
}

/// Capitalized status label ("completed" → "Completed"; empty → "Draft").
String atomStatusLabel(String status) {
  if (status.isEmpty) return 'Draft';
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}
