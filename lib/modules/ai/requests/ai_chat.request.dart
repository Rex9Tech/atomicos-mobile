import 'package:rexone_mobile/constants/constants.dart';

class AiChatRequest {
  final String message;
  final String? roomId;
  final String? systemPrompt;

  /// Hidden context (attached atom digest, file name) that rides along with
  /// the question. Kept out of [message] so the chat UI only shows what the
  /// user actually typed.
  final String? context;

  const AiChatRequest({
    required this.message,
    this.roomId,
    this.systemPrompt,
    this.context,
  });

  Map<String, dynamic> toJson() => {
    ApiKeys.message: message,
    if (roomId != null && roomId!.isNotEmpty) AiKeys.roomId: roomId,
    if (systemPrompt != null && systemPrompt!.isNotEmpty)
      AiKeys.systemPrompt: systemPrompt,
    if (context != null && context!.isNotEmpty) AiKeys.context: context,
  };
}
