/// Request/response keys for the Atom domain endpoints.
class AtomKeys {
  const AtomKeys._();

  static const atom = 'atom';
  static const title = 'title';
  static const atomId = 'atom_id';
  static const atomTitle = 'atom_title';
  static const meetingAt = 'meeting_at';
  static const source = 'source';
  static const status = 'status';
  static const durationSecs = 'duration_secs';
  static const participantsCount = 'participants_count';
  static const summaryBlocks = 'summary_blocks';
  static const transcriptSegments = 'transcript_segments';
  static const note = 'note';
  static const roomId = 'room_id';
  static const recordingStatus = 'recording_status';
  static const metadata = 'metadata';
  static const assets = 'assets';
  static const search = 'search';
  static const text = 'text';
  static const url = 'url';
  static const assetId = 'asset_id';
  static const language = 'language';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';

  // Asset sub-fields (nested under `assets`)
  static const name = 'name';
  static const type = 'type';
  static const format = 'format';
  static const sizeBytes = 'size_bytes';
}
