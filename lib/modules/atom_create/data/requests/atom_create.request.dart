import 'package:rexone_mobile/constants/constants.dart';

class AtomFromNoteRequest {
  final String title;
  final String note;
  final String? categoryId;

  const AtomFromNoteRequest({
    required this.title,
    required this.note,
    this.categoryId,
  });

  Map<String, dynamic> toJson() => {
    AtomKeys.title: title,
    AtomKeys.note: note,
    if (categoryId != null && categoryId!.isNotEmpty)
      CategoryKeys.categoryId: categoryId,
  };
}

class AtomFromUrlRequest {
  final String? title;
  final String url;
  final String? categoryId;

  const AtomFromUrlRequest({
    this.title,
    required this.url,
    this.categoryId,
  });

  Map<String, dynamic> toJson() => {
    if (title != null && title!.isNotEmpty) AtomKeys.title: title,
    AtomKeys.url: url,
    if (categoryId != null && categoryId!.isNotEmpty)
      CategoryKeys.categoryId: categoryId,
  };
}

class AtomFromAssetRequest {
  final String? title;
  final String assetId;
  final String? categoryId;
  final String? language;

  const AtomFromAssetRequest({
    this.title,
    required this.assetId,
    this.categoryId,
    this.language,
  });

  Map<String, dynamic> toJson() => {
    if (title != null && title!.isNotEmpty) AtomKeys.title: title,
    AtomKeys.assetId: assetId,
    if (categoryId != null && categoryId!.isNotEmpty)
      CategoryKeys.categoryId: categoryId,
    if (language != null && language!.isNotEmpty) AtomKeys.language: language,
  };
}

class AtomFromShareRequest {
  final String? title;
  final String text;
  final String? url;
  final String? categoryId;

  const AtomFromShareRequest({
    this.title,
    required this.text,
    this.url,
    this.categoryId,
  });

  Map<String, dynamic> toJson() => {
    if (title != null && title!.isNotEmpty) AtomKeys.title: title,
    AtomKeys.text: text,
    if (url != null && url!.isNotEmpty) AtomKeys.url: url,
    if (categoryId != null && categoryId!.isNotEmpty)
      CategoryKeys.categoryId: categoryId,
  };
}
