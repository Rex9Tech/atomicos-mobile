/// One speaker-labeled turn streamed from SpeechLiveChannel ("diarized").
///
/// The backend sends only the turns not yet delivered for each diarization
/// window, so lists of these grow append-only for the recording session.
class LiveSpeakerSegment {
  const LiveSpeakerSegment({
    required this.speaker,
    required this.text,
    this.start = 0,
    this.end = 0,
  });

  final String speaker;
  final String text;
  final double start;
  final double end;

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text': text,
        'start': start,
        'end': end,
      };

  factory LiveSpeakerSegment.fromJson(Map<dynamic, dynamic> json) {
    return LiveSpeakerSegment(
      speaker: json['speaker']?.toString() ?? 'Speaker',
      text: json['text']?.toString() ?? '',
      start: _seconds(json['start']),
      end: _seconds(json['end']),
    );
  }

  static double _seconds(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
