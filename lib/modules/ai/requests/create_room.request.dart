import 'package:rexone_mobile/constants/constants.dart';

class CreateRoomRequest {
  final String title;

  /// When set, the server reuses (or creates) this molecule's home room —
  /// one conversation per molecule.
  final String? categoryId;

  const CreateRoomRequest({required this.title, this.categoryId});

  Map<String, dynamic> toJson() => {
    AiKeys.title: title,
    if (categoryId != null && categoryId!.isNotEmpty)
      CategoryKeys.categoryId: categoryId,
  };
}
