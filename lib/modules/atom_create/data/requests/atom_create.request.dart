import 'package:rexone_mobile/constants/constants.dart';

class AtomFromNoteRequest {
  final String title;
  final String note;

  const AtomFromNoteRequest({required this.title, required this.note});

  Map<String, dynamic> toJson() => {
    AtomKeys.title: title,
    AtomKeys.note: note,
  };
}

class AtomFromUrlRequest {
  final String? title;
  final String url;

  const AtomFromUrlRequest({this.title, required this.url});

  Map<String, dynamic> toJson() => {
    if (title != null && title!.isNotEmpty) AtomKeys.title: title,
    AtomKeys.url: url,
  };
}

class AtomFromAssetRequest {
  final String? title;
  final String assetId;

  const AtomFromAssetRequest({this.title, required this.assetId});

  Map<String, dynamic> toJson() => {
    if (title != null && title!.isNotEmpty) AtomKeys.title: title,
    AtomKeys.assetId: assetId,
  };
}
