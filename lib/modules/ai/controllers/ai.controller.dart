// lib/modules/ai/controllers/ai.controller.dart
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../ai.dart';
import '../../home/home.dart';

class AiController extends GetxController {
  /// The live instance while the AI workspace page is open. The page owns its
  /// controller (not a GetX route registration) because GetX tears popped
  /// routes down lazily — a fast exit -> re-enter reused the dying instance
  /// and its disposal froze the composer (tester report). Socket events reach
  /// the page through this handle instead of Get.find.
  static AiController? active;

  final AiService _ai = Get.find<AiService>();
  final SpeechService _speech = Get.find<SpeechService>();
  final PermissionService _permissions = Get.find<PermissionService>();
  final RecordingService _recording = Get.find<RecordingService>();

  final RxList<AiMessageModel> messages = <AiMessageModel>[].obs;
  final RxList<AiRoomModel> rooms = <AiRoomModel>[].obs;

  final RxnString currentRoomId = RxnString();
  final RxString currentRoomTitle = AppLocales.ai.title.tr.obs;

  final RxBool isProcessing = false.obs;
  final RxnString activeTtsMessageId = RxnString();
  final RxBool isTtsLoading = false.obs;
  final RxString entryMode = 'auto'.obs;
  final RxString askStage = 'landing'.obs;
  final RxString recordingStage = 'idle'.obs;
  final RxnString currentRecordingId = RxnString();
  final RxnString currentRecordingAtomId = RxnString();
  final RxInt currentRecordingSeconds = 0.obs;
  DateTime? _recordingStartedAt;
  Timer? _recordingTicker;
  final RxnString askSelectedSource = RxnString();
  final RxnString askSubmittedPrompt = RxnString();
  final RxString askDraft = ''.obs;
  final RxString askActionTitle = 'Summary'.obs;
  final RxList<String> askActionLines = <String>[].obs;
  final Rxn<Map<String, dynamic>> askActionData = Rxn<Map<String, dynamic>>();
  final RxBool isRunningAskAction = false.obs;

  // ===== Context + attachments (real data, no placeholders) =====
  final HomeService _home = Get.find<HomeService>();
  final RxList<AtomModel> contextAtoms = <AtomModel>[].obs;
  final RxBool isLoadingContext = false.obs;
  final RxnString contextFilter = RxnString('All');
  final Rxn<AtomModel> contextAtom = Rxn<AtomModel>();
  final RxnString attachmentName = RxnString();
  final RxnString attachmentPath = RxnString();
  final searchContextController = TextEditingController();

  Timer? _processingWatchdog;
  int _processingPolls = 0;

  /// How much of an attached atom is sent to the model.
  static const int _contextCharLimit = 4000;

  /// Keeps replies structured so the chat can render them as markdown.
  static const String _markdownSystemPrompt =
      'Answer in markdown. Use short bold headings, bullet points for key '
      'points, and bold for names, numbers and decisions. Keep it concise.';

  bool _isSubmitting = false;
  String _textBeforeListen = '';
  Worker? _liveTextWorker;
  Worker? _playbackWorker;

  RxBool get isRecording => _speech.isListening;
  RxDouble get voiceLevel => _speech.voiceLevel;
  bool get isMeetingWorkspace => entryMode.value == 'meeting';
  bool get isDetailsMode => entryMode.value == 'details';
  bool get hasRecordingPreview =>
      recordingStage.value != 'idle' || _speech.isListening.value;
  bool get isRecordingPaused => recordingStage.value == 'paused';
  bool get isRecordingProcessing => recordingStage.value == 'processing';
  bool get isRecordingComplete => recordingStage.value == 'complete';
  bool get isAskMode {
    if (entryMode.value == 'ask') return true;
    if (entryMode.value == 'meeting' || entryMode.value == 'details') {
      return false;
    }
    final nonWelcome = messages.where((message) => message.id != 'welcome');
    if (nonWelcome.isEmpty) return true;
    return nonWelcome.length == 1 && nonWelcome.first.isUser;
  }

  bool get showAskAttachmentMenu => askStage.value == 'sources';
  bool get showAskSourceResults => askStage.value == 'source_results';
  bool get showAskResultPreview => askStage.value == 'prompt_result';

  // UI controllers — owned here so no StatefulWidget is needed in AiPage.
  final textController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    active = this;

    final args = Get.arguments;
    if (args is Map && args['mode'] != null) {
      entryMode.value = args['mode'].toString();
    }
    // Opened from an atom: pin that atom as conversation context, so
    // "Ask about this Atom" actually sends its content with the question.
    if (args is Map && args['atom_id'] != null) {
      final id = args['atom_id'].toString();
      if (id.isNotEmpty) {
        unawaited(_attachAtomContext(id));
      }
    }
    // Fallback for callers that only pass a title.
    if (args is Map && args['atom_title'] != null) {
      _seedQuestion(args['atom_title'].toString());
    }
    // Meeting workspace starts idle; the user taps the record control to start
    // a backend session (startRecording) + device mic.
    if (entryMode.value == 'meeting') {
      recordingStage.value = 'idle';
    }
    _playbackWorker = ever(_speech.isPlaying, (playing) {
      if (!playing && !isTtsLoading.value) {
        activeTtsMessageId.value = null;
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    loadRooms();
    loadHistory();
  }

  @override
  void onClose() {
    if (identical(active, this)) active = null;
    _liveTextWorker?.dispose();
    _playbackWorker?.dispose();
    _stopRecordingTicker();
    _stopProcessingWatchdog();
    unawaited(_speech.stopListening());
    unawaited(_speech.stopPlayback());
    textController.dispose();
    scrollController.dispose();
    searchContextController.dispose();
    super.onClose();
  }

  // ============================================================
  // SOCKET EVENT HANDLER (called by SocketController)
  // ============================================================

  /// Called by [SocketController] when an AI-related notification arrives.
  /// Reloads history only if the event belongs to the current room.
  Future<void> onSocketEvent(
    EWsEventType eventType,
    String? roomId, {
    String? messageId,
  }) async {
    switch (eventType) {
      case EWsEventType.ttsReady:
        if (roomId == null || roomId.isEmpty || roomId == currentRoomId.value) {
          await loadHistory(currentRoomId.value ?? roomId);
        }
        _clearTtsQueue(messageId);
      case EWsEventType.ttsFailed:
        _clearTtsQueue(messageId);
      case EWsEventType.aiResponseReady:
      case EWsEventType.aiResponseFailed:
        if (roomId == null || roomId.isEmpty || roomId == currentRoomId.value) {
          await loadHistory(currentRoomId.value);
        }
      default:
        return;
    }
  }

  void _clearTtsQueue(String? messageId) {
    if (messageId != null && activeTtsMessageId.value != messageId) return;
    isTtsLoading.value = false;
    if (!_speech.isPlaying.value) {
      activeTtsMessageId.value = null;
    }
  }

  // ============================================================
  // HISTORY & MESSAGES
  // ============================================================
  Future<void> loadHistory([String? roomId]) async {
    if (isMeetingWorkspace) {
      messages.clear();
      isProcessing.value = false;
      return;
    }

    try {
      final result = await _ai.getHistory(roomId: roomId);
      if (result.success) {
        if (result.records.isEmpty) {
          resetAskFlow();
          messages.assignAll([
            AiMessageModel(
              id: 'welcome',
              role: EChatRole.assistant.name,
              content: AppLocales.ai.defaultGreeting.tr,
              createdAt: AppDateTime.toUtcIso(DateTime.now())!,
            ),
          ]);
        } else {
          // Derive room context from the message data itself
          final rId = result.records.first.roomId;
          if (rId != null && rId.isNotEmpty) {
            currentRoomId.value = rId;
          }
          messages.assignAll(result.records);
        }

        isProcessing.value = result.records.any((m) => m.isProcessing);
        if (!isProcessing.value) _stopProcessingWatchdog();
        scrollToBottom();
      }
    } catch (e) {
      debugPrint('🤖 [AiController] Error loading history: $e');
    }
  }

  String _lastAssistantContent() {
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (!message.isUser && message.content.trim().isNotEmpty) {
        return message.content.trim();
      }
    }
    return '';
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isSubmitting || isProcessing.value) return;

    _isSubmitting = true;

    // Optimistic user message
    final optimisticMessage = AiMessageModel(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      role: EChatRole.user.name,
      content: clean,
      createdAt: AppDateTime.toUtcIso(DateTime.now())!,
    );

    messages.removeWhere((m) => m.id == 'welcome');
    messages.add(optimisticMessage);
    isProcessing.value = true;
    _startProcessingWatchdog();

    try {
      final context = _composeContext();
      final response = await _ai.chat(
        AiChatRequest(
          message: clean,
          roomId: currentRoomId.value,
          systemPrompt: _markdownSystemPrompt,
          context: context.isEmpty ? null : context,
        ),
      );
      if (response.success && response.data != null) {
        final message = response.data!;
        final roomId = response.meta?[AiKeys.roomId]?.toString() ??
            message.roomId;

        if (roomId != null && roomId.isNotEmpty) {
          currentRoomId.value = roomId;
        }

        final idx = messages.indexOf(optimisticMessage);
        final rawMessages = response.meta?[AiKeys.messages];
        if (rawMessages is List && rawMessages.isNotEmpty) {
          final parsed = rawMessages
              .whereType<Map>()
              .map((m) =>
                  AiMessageModel.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          if (idx != -1) {
            messages.removeAt(idx);
            messages.insertAll(idx, parsed);
          } else {
            messages.addAll(parsed);
          }
        } else {
          if (message.role == EChatRole.user.name) {
            if (idx != -1) {
              messages[idx] = message;
            } else {
              messages.add(message);
            }
          } else {
            messages.add(message);
          }
        }
        // Sent — the attachment has been delivered, keep the context for follow-ups.
        clearAskAttachment();
      } else {
        AppSnackbar.error(
          response.error ?? AppLocales.ai.aiSendMessageFailed.tr,
        );
        isProcessing.value = false;
        _stopProcessingWatchdog();
      }
    } catch (e) {
      AppSnackbar.error(AppLocales.ai.aiResponseFailed.tr);
      isProcessing.value = false;
      _stopProcessingWatchdog();
    } finally {
      _isSubmitting = false;
    }
  }

  /// Re-runs the last turn after a failure: drops the failed exchange locally
  /// and resends the same user prompt. No-op while another answer is in
  /// flight.
  Future<void> retryLastTurn() async {
    if (isProcessing.value || _isSubmitting) return;
    final userIndex = messages.lastIndexWhere((m) => m.isUser);
    if (userIndex < 0) return;
    final prompt = messages[userIndex].content;
    messages.removeRange(userIndex, messages.length);
    await sendMessage(prompt);
  }

  /// Hidden context sent alongside the question — attached atom digest and/or
  /// file name. Travels in its own field so the chat UI and stored history
  /// only ever show what the user actually typed.
  String _composeContext() {
    final parts = <String>[];
    final atom = contextAtom.value;
    if (atom != null) {
      final snippet = _contextSnippet(atom);
      parts.add('Context — "${atom.title}" (${atom.source}):\n$snippet');
    }
    final attachment = attachmentName.value;
    if (attachment != null && attachment.isNotEmpty) {
      parts.add('Attached file: $attachment');
    }
    return parts.join('\n\n');
  }

  /// Short, model-friendly digest of an atom used as conversation context:
  /// note, summary blocks and transcript, trimmed to a sane length.
  String _contextSnippet(AtomModel atom) {
    final parts = <String>[];
    final note = atom.note?.trim() ?? '';
    if (note.isNotEmpty) parts.add(note);
    for (final block in atom.summaryBlocks) {
      _collectStrings(block, parts);
    }
    for (final segment in atom.transcriptSegments) {
      _collectStrings(segment, parts);
    }
    // Attached documents (PDF/DOCX/text) ship their extracted text from the
    // backend — include it so the AI can read uploaded files too.
    for (final asset in atom.assets) {
      final text = asset.extractedText?.trim() ?? '';
      if (text.isNotEmpty) parts.add(text);
    }
    final text = parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (text.length <= _contextCharLimit) return text;
    return '${text.substring(0, _contextCharLimit)}…';
  }

  /// Loads the atom handed over by the details screen and pins it as context.
  /// The composer shows it as a chip and [_composeMessage] sends its content.
  Future<void> _attachAtomContext(String atomId) async {
    try {
      final result = await _home.getAtom(atomId);
      if (!result.success || result.data == null) return;
      contextAtom.value = result.data;
      _seedQuestion(result.data!.title);
    } catch (error) {
      debugPrint('🤖 [AiController] attachAtomContext error: $error');
    }
  }

  void _seedQuestion(String title) {
    if (title.isEmpty || textController.text.trim().isNotEmpty) return;
    final seeded = 'What are the key points in "$title"?';
    textController.text = seeded;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: seeded.length),
    );
  }

  // ===== Processing watchdog: never leave the composer stuck =====

  void _startProcessingWatchdog() {
    _stopProcessingWatchdog();
    _processingPolls = 0;
    _processingWatchdog = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!isProcessing.value) {
        timer.cancel();
        return;
      }
      _processingPolls++;
      if (_processingPolls > 6) {
        timer.cancel();
        isProcessing.value = false;
        AppSnackbar.warning(
          'Still working — pull down to refresh in a moment.',
        );
        return;
      }
      // The reply may have landed without a socket event reaching us.
      unawaited(loadHistory(currentRoomId.value));
    });
  }

  void _stopProcessingWatchdog() {
    _processingWatchdog?.cancel();
    _processingWatchdog = null;
  }

  /// Lets the user bail out of a stuck turn without leaving the UI blocked.
  void stopProcessing() {
    if (!isProcessing.value) return;
    isProcessing.value = false;
    _stopProcessingWatchdog();
  }

  // ============================================================
  // ROOM MANAGEMENT
  // ============================================================
  Future<void> loadRooms() async {
    try {
      final response = await _ai.getRooms();
      if (response.success) {
        rooms.assignAll(response.records);
      }
    } catch (e) {
      debugPrint('🤖 [AiController] Error loading rooms: $e');
    }
  }

  void selectRoom(AiRoomModel room) {
    entryMode.value = 'details';
    currentRoomId.value = room.id;
    currentRoomTitle.value = room.title;
    loadHistory(room.id);
  }

  Future<void> createNewRoom([String? title]) async {
    try {
      entryMode.value = 'ask';
      final roomTitle = title ?? AppLocales.ai.newChat.tr;
      final response = await _ai.createRoom(
        CreateRoomRequest(title: roomTitle),
      );
      if (response.success && response.data != null) {
        final newRoom = response.data!;
        rooms.insert(0, newRoom);
        selectRoom(newRoom);
      }
    } catch (e) {
      debugPrint('🤖 [AiController] Error creating room: $e');
    }
  }

  Future<void> renameRoom(String roomId, String newTitle) async {
    final clean = newTitle.trim();
    if (clean.isEmpty) return;
    try {
      final response = await _ai.renameRoom(roomId, clean);
      if (response.success) {
        final index = rooms.indexWhere((r) => r.id == roomId);
        if (index != -1) {
          rooms[index] = rooms[index].copyWith(title: clean);
        }
        if (currentRoomId.value == roomId) {
          currentRoomTitle.value = clean;
        }
      }
    } catch (e) {
      debugPrint('🤖 [AiController] Error renaming room: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await _ai.deleteRoom(roomId);
      if (response.success) {
        rooms.removeWhere((r) => r.id == roomId);
        if (currentRoomId.value == roomId) {
          currentRoomId.value = null;
          currentRoomTitle.value = AppLocales.ai.title.tr;
          loadHistory();
        }
      }
    } catch (e) {
      debugPrint('🤖 [AiController] Error deleting room: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final response = await _ai.clearHistory(roomId: currentRoomId.value);
      if (response.success) {
        loadHistory(currentRoomId.value);
        AppSnackbar.success(AppLocales.ai.aiHistoryCleared.tr);
      }
    } catch (e) {
      AppSnackbar.error(AppLocales.ai.aiClearHistoryFailed.tr);
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Design.timers.short,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void handleSend() {
    if (isRecording.value || activeTtsMessageId.value != null) return;
    final text = textController.text.trim();
    if (text.isEmpty || isProcessing.value) return;
    if (isMeetingWorkspace) {
      askDraft.value = text;
      _setInputText(text);
      return;
    }
    askSubmittedPrompt.value = text;
    askStage.value = 'prompt_result';
    askDraft.value = '';
    // A new turn clears the previous action result — actions are explicit now.
    askActionData.value = null;
    askActionLines.clear();
    textController.clear();
    sendMessage(text);
    scrollToBottom();
  }

  void toggleAskAttachmentMenu() {
    askStage.value = showAskAttachmentMenu ? 'landing' : 'sources';
  }

  void closeAskAttachmentMenu() {
    if (askStage.value != 'landing') {
      askStage.value = 'landing';
    }
  }

  /// Composer "+" menu: real capture paths only.
  /// Photo/Files pick an actual file; Add Atom opens the context picker.
  void selectAskAttachment(String label) {
    switch (label) {
      case 'Add Atom':
        openContextPicker();
        break;
      case 'Photo':
        unawaited(pickAskAttachment(imagesOnly: true));
        break;
      default:
        unawaited(pickAskAttachment());
        break;
    }
  }

  Future<void> pickAskAttachment({bool imagesOnly = false}) async {
    try {
      final file = await FilePickerPlatform.instance.pickFile(
        type: imagesOnly ? FileType.image : FileType.any,
      );
      if (file == null) return;
      attachmentName.value = file.name;
      attachmentPath.value = file.path;
      AppSnackbar.info(
        AppLocales.ai.attachedFile.trParams({'name': file.name}),
      );
    } catch (e) {
      AppSnackbar.error(AppLocales.ai.filePickerFailed.tr);
    }
  }

  void clearAskAttachment() {
    attachmentName.value = null;
    attachmentPath.value = null;
  }

  // ===== Context picker (real atoms, not a placeholder) =====

  void openContextPicker() {
    askStage.value = 'source_results';
    loadContextAtoms();
  }

  Future<void> loadContextAtoms([String? query]) async {
    isLoadingContext.value = true;
    try {
      final result = await _home.getAtoms(search: query, limit: 30);
      contextAtoms.assignAll(result.records);
    } catch (e) {
      debugPrint('🤖 [AiController] loadContextAtoms error: $e');
    } finally {
      isLoadingContext.value = false;
    }
  }

  void setContextFilter(String filter) {
    contextFilter.value = filter;
  }

  void attachContextAtom(AtomModel atom) {
    contextAtom.value = atom;
    AppSnackbar.success(
      AppLocales.ai.usingAsContext.trParams({'name': atom.title}),
    );
  }

  void clearContextAtom() {
    contextAtom.value = null;
  }

  /// Atoms for the picker after applying the source filter chip.
  List<AtomModel> get filteredContextAtoms {
    final filter = (contextFilter.value ?? 'All').toLowerCase();
    if (filter == 'all') return contextAtoms;
    return contextAtoms
        .where((atom) => _matchesContextFilter(atom, filter))
        .toList();
  }

  bool _matchesContextFilter(AtomModel atom, String filter) {
    final source = atom.source.toLowerCase();
    switch (filter) {
      case 'meetings':
        return source == 'meeting' || source == 'asset';
      case 'links':
        return source == 'url';
      case 'notes':
        return source == 'note' || source == 'share';
      default:
        return true;
    }
  }

  void applyPromptSuggestion(String prompt) {
    askStage.value = 'landing';
    askDraft.value = prompt;
    textController.value = TextEditingValue(
      text: prompt,
      selection: TextSelection.collapsed(offset: prompt.length),
    );
  }

  void updateAskDraft(String value) {
    askDraft.value = value;
  }

  void selectAskSearchResult(String source, {String? suggestedPrompt}) {
    askSelectedSource.value = source;
    askStage.value = 'landing';
    if (suggestedPrompt != null) {
      applyPromptSuggestion(suggestedPrompt);
    }
  }

  void resetAskFlow() {
    askStage.value = 'landing';
    askSelectedSource.value = null;
    askSubmittedPrompt.value = null;
    askDraft.value = '';
    askActionTitle.value = 'Summary';
    askActionLines.clear();
    askActionData.value = null;
    clearAskAttachment();
  }

  Future<void> runAskAction(String label, {String? prompt}) async {
    final promptText = prompt?.trim() ?? '';
    final submittedText = askSubmittedPrompt.value?.trim() ?? '';
    final draftText = askDraft.value.trim();
    final inputText = textController.text.trim();
    // Prefer what the assistant just said — actions operate on the answer.
    final lastReply = _lastAssistantContent();
    final sourceText = promptText.isNotEmpty
        ? promptText
        : lastReply.isNotEmpty
        ? lastReply
        : submittedText.isNotEmpty
        ? submittedText
        : draftText.isNotEmpty
        ? draftText
        : inputText;

    if (sourceText.isEmpty) {
      AppSnackbar.warning('Add a prompt before running an action');
      return;
    }

    askActionTitle.value = label;
    isRunningAskAction.value = true;
    askStage.value = 'prompt_result';

    try {
      late final ApiResponse<Map<String, dynamic>> response;
      switch (label.toLowerCase()) {
        case 'summary':
          response = await _ai.summarize(sourceText);
          break;
        case 'fusion with':
          response = await _ai.translate(sourceText);
          break;
        case 'generate tasks':
          response = await _ai.generateTasks(sourceText);
          break;
        case 'decisions':
          response = await _ai.extractDecisions(sourceText);
          break;
        default:
          response = await _ai.generateReport(sourceText);
          break;
      }

      if (!response.success) {
        AppSnackbar.error(response.error ?? response.message);
        return;
      }

      askActionData.value = response.data;

      final lines = _extractResultLines(response.data ?? const {});
      askActionLines.assignAll(
        lines.isEmpty
            ? ['No structured result was returned for this action yet.']
            : lines,
      );
    } catch (e) {
      AppSnackbar.error('Failed to run $label: $e');
    } finally {
      isRunningAskAction.value = false;
    }
  }

  void setRecordingStage(String value) {
    recordingStage.value = value;
  }

  void cycleRecordingStage() {
    switch (recordingStage.value) {
      case 'recording':
        pauseRecording();
        break;
      case 'paused':
        finishRecording();
        break;
      case 'processing':
        break;
      case 'complete':
        resetRecording();
        break;
      default:
        startRecording();
        break;
    }
  }

  // ============================================================
  // RECORDING SESSION (backend lifecycle)
  // ============================================================
  Future<void> startRecording() async {
    if (currentRecordingId.value != null) return;

    final result = await _recording.start(AppLocales.ai.title.tr);
    if (!result.success || result.data == null) {
      AppSnackbar.error(
        result.error ?? AppLocales.ai.aiStartRecordingFailed.tr,
      );
      return;
    }

    currentRecordingId.value = result.data!.id;
    currentRecordingAtomId.value = null;
    _recordingStartedAt = DateTime.now();
    currentRecordingSeconds.value = 0;
    _recordingSecondsTicker();

    await startListening();
    setRecordingStage('recording');
  }

  Future<void> pauseRecording() async {
    final id = currentRecordingId.value;
    if (id == null) return;

    await stopListening();
    _stopRecordingTicker();

    await _recording.updateRecording(
      id,
      status: 'paused',
      durationSecs: _elapsedSeconds(),
    );
    setRecordingStage('paused');
  }

  Future<void> resumeRecording() async {
    final id = currentRecordingId.value;
    if (id == null) return;

    await _recording.updateRecording(id, status: 'recording');
    _recordingStartedAt = DateTime.now().subtract(
      Duration(seconds: currentRecordingSeconds.value),
    );
    _recordingSecondsTicker();

    await startListening();
    setRecordingStage('recording');
  }

  Future<void> finishRecording() async {
    final id = currentRecordingId.value;
    if (id == null) return;

    await stopListening();
    _stopRecordingTicker();
    setRecordingStage('processing');

    final result = await _recording.finish(id, durationSecs: _elapsedSeconds());
    if (result.success && result.data != null) {
      final atomId = result.data!.atomId;
      currentRecordingAtomId.value = atomId;
      currentRecordingId.value = null;
      setRecordingStage('complete');
      if (atomId != null && atomId.isNotEmpty) {
        AppSnackbar.success('Recording saved');
        AppRoutes.toAtomDetail(atomId: atomId);
      }
    } else {
      AppSnackbar.error(result.error ?? AppLocales.ai.aiResponseFailed.tr);
      setRecordingStage('paused');
    }
  }

  void resetRecording() {
    currentRecordingId.value = null;
    currentRecordingAtomId.value = null;
    currentRecordingSeconds.value = 0;
    _recordingStartedAt = null;
    _stopRecordingTicker();
    setRecordingStage('idle');
  }

  void _recordingSecondsTicker() {
    _stopRecordingTicker();
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      currentRecordingSeconds.value = _elapsedSeconds();
    });
  }

  void _stopRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingTicker = null;
  }

  int _elapsedSeconds() {
    final startedAt = _recordingStartedAt;
    if (startedAt == null) return currentRecordingSeconds.value;
    return DateTime.now().difference(startedAt).inSeconds.clamp(0, 1 << 31);
  }

  // ============================================================
  // LIVE SPEECH
  // ============================================================
  Future<void> toggleListening() async {
    if (_speech.isListenSessionActive) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (isProcessing.value || activeTtsMessageId.value != null) return;

    _textBeforeListen = textController.text;
    _liveTextWorker?.dispose();
    _liveTextWorker = ever(_speech.liveText, _setInputText);

    final result = await _speech.startListening(seed: textController.text);
    if (result == ESpeechListenResult.started) {
      recordingStage.value = 'recording';
      return;
    }

    _liveTextWorker?.dispose();
    _liveTextWorker = null;

    switch (result) {
      case ESpeechListenResult.disconnected:
      case ESpeechListenResult.capturedOffline:
        AppSnackbar.error(AppLocales.ai.aiTranscriptionFailed.tr);
      case ESpeechListenResult.permissionDenied:
        await _permissions.promptMicrophoneSettings();
      case ESpeechListenResult.failed:
        AppSnackbar.error(AppLocales.ai.aiStartRecordingFailed.tr);
      case ESpeechListenResult.alreadyListening:
      case ESpeechListenResult.started:
        break;
    }
  }

  Future<void> stopListening() async {
    _liveTextWorker?.dispose();
    _liveTextWorker = null;
    await _speech.stopListening();
    if (recordingStage.value == 'recording') {
      recordingStage.value = 'paused';
    }
  }

  Future<void> cancelListening() async {
    await stopListening();
    _setInputText(_textBeforeListen);
    recordingStage.value = isDetailsMode ? 'idle' : 'recording';
  }

  void _setInputText(String text) {
    textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // ============================================================
  // TEXT-TO-SPEECH
  // ============================================================
  Future<void> speakMessage(AiMessageModel msg) async {
    if (activeTtsMessageId.value == msg.id && _speech.isPlaying.value) {
      await stopSpeaking();
      return;
    }

    await stopSpeaking();

    final audioUrl = msg.audioUrl;
    if (audioUrl != null) {
      activeTtsMessageId.value = msg.id;
      try {
        await _speech.playUrl(audioUrl);
      } catch (e) {
        debugPrint('🤖 [AiController] Error playing TTS: $e');
        AppSnackbar.error(AppLocales.ai.aiTtsFailed.tr);
        activeTtsMessageId.value = null;
      }
      return;
    }

    if (msg.content.trim().isEmpty) {
      AppSnackbar.error(AppLocales.ai.aiTtsEmpty.tr);
      return;
    }

    activeTtsMessageId.value = msg.id;
    isTtsLoading.value = true;

    try {
      final response = await _speech.textToSpeech(msg.id);
      if (!response.success) {
        AppSnackbar.error(response.error ?? response.message);
        activeTtsMessageId.value = null;
        isTtsLoading.value = false;
        return;
      }

      if (activeTtsMessageId.value != msg.id) {
        isTtsLoading.value = false;
        return;
      }

      if (response.message.isNotEmpty) {
        AppSnackbar.info(response.message);
      }
    } catch (e) {
      debugPrint('🤖 [AiController] Error queueing TTS: $e');
      AppSnackbar.error(AppLocales.ai.aiTtsFailed.tr);
      activeTtsMessageId.value = null;
      isTtsLoading.value = false;
    }
  }

  Future<void> stopSpeaking() async {
    await _speech.stopPlayback();
    isTtsLoading.value = false;
    activeTtsMessageId.value = null;
  }

  List<String> _extractResultLines(Map<String, dynamic> data) {
    final lines = <String>[];
    _collectStrings(data, lines);
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(6)
        .toList();
  }

  void _collectStrings(dynamic value, List<String> output) {
    if (value == null) return;
    if (value is String) {
      output.add(value);
      return;
    }
    if (value is num || value is bool) {
      output.add(value.toString());
      return;
    }
    if (value is List) {
      for (final item in value) {
        _collectStrings(item, output);
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.value is String) {
          output.add(entry.value.toString());
        } else {
          _collectStrings(entry.value, output);
        }
      }
    }
  }
}
