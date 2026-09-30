// lib/locales/app_locales.dart

/// Centralized, namespaced translation keys matching rexone-web AppLocales.
/// Use with `'key'.tr` or `'key'.trParams({'email': ...})`.
class AppLocales {
  const AppLocales._();

  static const auth = _AuthLocales();
  static const common = _CommonLocales();
  static const setting = _SettingLocales();
  static const feedback = _FeedbackLocales();
  static const ai = _AiLocales();
  static const payment = _PaymentLocales();
  static const user = _UserLocales();
  static const notification = _NotificationLocales();
  static const update = _UpdateLocales();
  static const atom = _AtomLocales();
  static const calendar = _CalendarLocales();
  static const permission = _PermissionLocales();
  static const search = _SearchLocales();
  static const recording = _RecordingLocales();
  static const create = _CreateLocales();
  static const home = _HomeLocales();
  static const category = _CategoryLocales();
  static const audio = _AudioLocales();
  static const video = _VideoLocales();
  static const media = _MediaLocales();
}

class _CategoryLocales {
  const _CategoryLocales();

  final title = 'category.title';
  final manage = 'category.manage';
  final manageSub = 'category.manageSub';
  final nameHint = 'category.nameHint';
  final add = 'category.add';
  final empty = 'category.empty';
  final deleteTitle = 'category.deleteTitle';
  final deleteMessage = 'category.deleteMessage';
  final created = 'category.created';
  final deleted = 'category.deleted';
  final quickAdd = 'category.quickAdd';
  final none = 'category.none';
  final selectTitle = 'category.selectTitle';
  final updated = 'category.updated';
}

class _RecordingLocales {
  const _RecordingLocales();
  final liveMeeting = 'recording.liveMeeting';
  final end = 'recording.end';
  final noteFieldHint = 'recording.noteFieldHint';
  final transcriptPlaceholder = 'recording.transcriptPlaceholder';
  final badgeLive = 'recording.badgeLive';
  final badgeOff = 'recording.badgeOff';
  final transcriptOffline = 'recording.transcriptOffline';
  final transcriptMicNeeded = 'recording.transcriptMicNeeded';
  final transcriptOfflineRecording = 'recording.transcriptOfflineRecording';
  final transcriptUnavailable = 'recording.transcriptUnavailable';

  final endTitle = 'recording.end_title';
  final endMessage = 'recording.end_message';
  final endConfirm = 'recording.end_confirm';
}

class _SearchLocales {
  const _SearchLocales();

  final placeholder = 'search.placeholder';
  final emptyTitle = 'search.empty_title';
  final emptyMessage = 'search.empty_message';
}

class _AuthLocales {
  const _AuthLocales();

  final shared = const _AuthSharedLocales();
  final initial = const _AuthInitialLocales();
  final signInPasscode = const _AuthSignInPasscodeLocales();
  final signUpPasscodeCreate = const _AuthSignUpPasscodeCreateLocales();
  final signUpPasscodeConfirm = const _AuthSignUpPasscodeConfirmLocales();
  final signUpInfo = const _AuthSignUpInfoLocales();
  final confirmEmail = const _AuthConfirmEmailLocales();
  final forgotPasscode = const _AuthForgotPasscodeLocales();
}

class _AuthSharedLocales {
  const _AuthSharedLocales();

  final emailLabel = 'auth.shared.email_label';
  final emailHint = 'auth.shared.email_placeholder';
  final continueButton = 'auth.shared.continue';
  final useDifferentEmail = 'auth.shared.use_different_email';
  final passcodeLength = 'auth.shared.validation.passcode_length';
  final sessionExpired = 'auth.shared.session_expired';
  final sessionReplaced = 'auth.shared.session_replaced';
}

class _AuthInitialLocales {
  const _AuthInitialLocales();

  final title = 'auth.initial.title';
  final subtitle = 'auth.initial.description';
  final continueWithGoogle = 'auth.initial.continue_with_google';
  final or = 'auth.initial.or';
  final emailHelper = 'auth.initial.email_helper';
  final invalidEmail = 'auth.initial.validation.invalid_email';
  final checking = 'auth.initial.actions.checking';
  final googleFailure = 'auth.initial.errors.google_signin_failed';
  final googleTooManyAttempts = 'auth.initial.errors.google_too_many_attempts';
  final connectionFailed = 'auth.initial.errors.connection_failed';
  final goBack = 'auth.initial.actions.go_back';
}

class _AuthSignInPasscodeLocales {
  const _AuthSignInPasscodeLocales();

  final title = 'auth.signin_passcode.title';
  final heading = 'auth.signin_passcode.prompt';
  final subtitle = 'auth.signin_passcode.description';
  final passcodeLabel = 'auth.signin_passcode.field.label';
  final signingIn = 'auth.signin_passcode.actions.signing_in';
  final forgotPasscodeLink = 'auth.signin_passcode.links.forgot_passcode';
  final passcode6Digits = 'auth.signin_passcode.validation.passcode_6_digits';
  final attemptsRemaining = 'auth.signin_passcode.helper.attempts_remaining';
  final cooldownMessage = 'auth.signin_passcode.errors.too_many_attempts';
  final tryAgainIn = 'auth.signin_passcode.actions.try_again_in';
  final signInFailed = 'auth.signin_passcode.errors.signin_failed';
}

class _AuthSignUpPasscodeCreateLocales {
  const _AuthSignUpPasscodeCreateLocales();

  final title = 'auth.signup_passcode_create.title.signup';
  final heading = 'auth.signup_passcode_create.prompt.signup';
  final subtitle = 'auth.signup_passcode_create.description.signup';
  final googleHeading = 'auth.signup_passcode_create.google.heading';
  final googleSubtitle = 'auth.signup_passcode_create.google.subtitle';
  final instruction = 'auth.signup_passcode_create.instruction';
}

class _AuthSignUpPasscodeConfirmLocales {
  const _AuthSignUpPasscodeConfirmLocales();

  final title = 'auth.signup_passcode_confirm.title.signup';
  final heading = 'auth.signup_passcode_confirm.prompt.signup';
  final subtitle = 'auth.signup_passcode_confirm.description.signup';
  final confirm = 'auth.signup_passcode_confirm.actions.confirm';
  final changePasscode = 'auth.signup_passcode_confirm.actions.change_passcode';
  final passcodesMismatch =
      'auth.signup_passcode_confirm.validation.passcodes_mismatch';
  final sendingCode = 'auth.signup_passcode_confirm.actions.sending_code';
}

class _AuthSignUpInfoLocales {
  const _AuthSignUpInfoLocales();

  final title = 'auth.signup_info.title';
  final heading = 'auth.signup_info.prompt';
  final fullNameLabel = 'auth.signup_info.full_name.label';
  final fullNameHint = 'auth.signup_info.full_name.placeholder';
  final usernameLabel = 'auth.signup_info.username.label';
  final usernameHint = 'auth.signup_info.username.placeholder';
  final createAccountButton = 'auth.signup_info.actions.create_account';
  final creatingAccount = 'auth.signup_info.actions.creating_account';
  final enterFullName = 'auth.signup_info.validation.full_name_required';
  final fullNameMaxLength = 'auth.signup_info.validation.full_name_max_length';
  final fullNameForbiddenChars =
      'auth.signup_info.validation.full_name_forbidden';
  final usernameMinLength = 'auth.signup_info.validation.username_length';
  final usernameMaxLength = 'auth.signup_info.validation.username_max_length';
  final usernameCharset = 'auth.signup_info.validation.username_format';
  final registrationFailed = 'auth.signup_info.errors.registration_failed';
}

class _AuthConfirmEmailLocales {
  const _AuthConfirmEmailLocales();

  final title = 'auth.confirm_email.title';
  final heading = 'auth.confirm_email.prompt';
  final subtitle = 'auth.confirm_email.sent_to';
  final confirmCodeButton = 'auth.confirm_email.actions.verify_email';
  final verifying = 'auth.confirm_email.actions.verifying';
  final resendCode = 'auth.confirm_email.actions.resend';
  final resendCodeIn = 'auth.confirm_email.actions.resend_in';
  final enter6DigitCode = 'auth.confirm_email.validation.enter_6_digit_code';
  final verificationFailed = 'auth.confirm_email.errors.verification_failed';
  final sendCodeFailed = 'auth.confirm_email.errors.send_code_failed';
}

class _AuthForgotPasscodeLocales {
  const _AuthForgotPasscodeLocales();

  final title = 'auth.forgot_passcode.title';
  final subtitle = 'auth.forgot_passcode.description';
  final sendResetLink = 'auth.forgot_passcode.actions.send_reset_link';
  final sending = 'auth.forgot_passcode.actions.sending';
  final backToSignIn = 'auth.forgot_passcode.links.back_to_signin';
  final resetFailed = 'auth.forgot_passcode.errors.reset_failed';
}

class _CommonLocales {
  const _CommonLocales();

  final home = 'common.home';
  final welcomeHome = 'common.welcome_home';
  final loading = 'common.loading';
  final signOut = 'common.sign_out';
  final goBack = 'common.go_back';
  final submit = 'common.submit';
  final save = 'common.save';
  final cancel = 'common.cancel';
  final rename = 'common.rename';
  final delete = 'common.delete';
  final confirm = 'common.confirm';
  final error = 'common.error';
  final success = 'common.success';
  final warning = 'common.warning';
  final info = 'common.info';
  final exit = 'common.exit';
  final exitTitle = 'common.exit_title';
  final exitConfirm = 'common.exit_confirm';
  final connectionLost = 'common.connection_lost';
  final connectionRestored = 'common.connection_restored';
  final noInternet = 'common.no_internet';
}

class _SettingLocales {
  const _SettingLocales();

  final settings = 'settings.title';
  final theme = 'settings.theme';
  final language = 'settings.language';
  final account = 'settings.account';
  final logoutConfirmation = 'settings.logout_confirmation';
  final appInfo = 'settings.app_info';
  final confirmDelete = 'settings.confirm_delete';
  final confirmClear = 'settings.confirm_clear';
  final clearHistoryTitle = 'settings.clear_history_title';
  final clearHistoryConfirmMsg = 'settings.clear_history_confirm_msg';
  final deleteRoomTitle = 'settings.delete_room_title';
  final deleteRoomConfirmMsg = 'settings.delete_room_confirm_msg';
  final cancelSubTitle = 'settings.cancel_sub_title';
  final cancelSubConfirmMsg = 'settings.cancel_sub_confirm_msg';
}

class _FeedbackLocales {
  const _FeedbackLocales();

  final title = 'feedback.title';
  final description = 'feedback.description';
  final rateExperience = 'feedback.rate_experience';
  final tellUsMore = 'feedback.tell_us_more';
  final placeholder = 'feedback.placeholder';
  final submit = 'feedback.submit';
  final submitting = 'feedback.submitting';
  final successMessage = 'feedback.success_message';
}

class _AiLocales {
  const _AiLocales();
  final sourcePhotoSub = 'ai.sourcePhotoSub';
  final sourceFilesSub = 'ai.sourceFilesSub';
  final attachedFile = 'ai.attachedFile';
  final filePickerFailed = 'ai.filePickerFailed';
  final chooseContext = 'ai.chooseContext';
  final chooseContextSub = 'ai.chooseContextSub';
  final noAtomsHere = 'ai.noAtomsHere';
  final noAtomsHereSub = 'ai.noAtomsHereSub';
  final workWithAnswer = 'ai.workWithAnswer';
  final runActionHint = 'ai.runActionHint';
  final detailsTab = 'ai.detailsTab';
  final overview = 'ai.overview';
  final contextCards = 'ai.contextCards';
  final attachments = 'ai.attachments';
  final processingPanelSub = 'ai.processingPanelSub';
  final outputsReadySub = 'ai.outputsReadySub';
  final processingPreview = 'ai.processingPreview';
  final readyOpenDetails = 'ai.readyOpenDetails';
  final needsRetry = 'ai.needsRetry';
  final meetingNoteHint = 'ai.meetingNoteHint';
  final processingMeeting = 'ai.processingMeeting';
  final processingMeetingSub = 'ai.processingMeetingSub';
  final meetingReady = 'ai.meetingReady';
  final meetingReadySub = 'ai.meetingReadySub';
  final recordingPausedTitle = 'ai.recordingPausedTitle';
  final recordingPausedSub = 'ai.recordingPausedSub';
  final askTitle = 'ai.askTitle';
  final askSubtitle = 'ai.askSubtitle';
  final resultSummary = 'ai.resultSummary';
  final resultDecisions = 'ai.resultDecisions';
  final resultTasks = 'ai.resultTasks';
  final actionSummarySub = 'ai.actionSummarySub';
  final actionDecisionsSub = 'ai.actionDecisionsSub';
  final actionFusion = 'ai.actionFusion';
  final actionFusionSub = 'ai.actionFusionSub';
  final actionTasks = 'ai.actionTasks';
  final actionTasksSub = 'ai.actionTasksSub';
  final actionReport = 'ai.actionReport';
  final actionReportSub = 'ai.actionReportSub';
  final noTranscript = 'ai.noTranscript';
  final noTranscriptSub = 'ai.noTranscriptSub';
  final today = 'ai.today';
  final source = 'ai.source';
  final participants = 'ai.participants';
  final askAboutThisAtom = 'ai.askAboutThisAtom';
  final askAboutThisAtomSub = 'ai.askAboutThisAtomSub';
  final noAssets = 'ai.noAssets';
  final noAssetsSub = 'ai.noAssetsSub';
  final addMoreFiles = 'ai.addMoreFiles';
  final addMoreFilesSub1 = 'ai.addMoreFilesSub1';
  final addMoreFilesSub2 = 'ai.addMoreFilesSub2';
  final generatingOutputs = 'ai.generatingOutputs';
  final outputsReady = 'ai.outputsReady';
  final actionItems = 'ai.actionItems';
  final attachAsContext = 'ai.attachAsContext';

  final title = 'ai.title';
  final rooms = 'ai.rooms';
  final newChat = 'ai.new_chat';
  final defaultGreeting = 'ai.default_greeting';
  final messagesCount = 'ai.messages_count';
  final listen = 'ai.listen';
  final thinking = 'ai.thinking';
  final cancelListening = 'ai.cancel_listening';
  final typeMessage = 'ai.type_message';
  final send = 'ai.send';
  final composerHint = 'ai.composerHint';
  final retry = 'ai.retry';
  final searchAtomsHint = 'ai.searchAtomsHint';
  final attachSheetTitle = 'ai.attachSheetTitle';
  final sourceAtomSub = 'ai.sourceAtomSub';
  final usingAsContext = 'ai.usingAsContext';
  final selected = 'ai.selected';
  final processing = 'ai.processing';
  final clearHistory = 'ai.clear_history';

  // Voice / microphone
  final micPermissionTitle = 'ai.mic_permission_title';
  final micPermissionMessage = 'ai.mic_permission_message';
  final openSettings = 'ai.open_settings';

  // Ask composer source cards
  final askSourcePhoto = 'ai.ask_source_photo';
  final askSourceFiles = 'ai.ask_source_files';
  final askSourceAtom = 'ai.ask_source_atom';

  // AI chat
  final aiSendMessageFailed = 'ai.ai_send_message_failed';
  final aiResponseFailed = 'ai.ai_response_failed';
  final aiHistoryCleared = 'ai.ai_history_cleared';
  final aiClearHistoryFailed = 'ai.ai_clear_history_failed';
  final aiStartRecordingFailed = 'ai.ai_start_recording_failed';
  final aiTranscriptionFailed = 'ai.ai_transcription_failed';
  final aiTtsFailed = 'ai.ai_tts_failed';
  final aiTtsEmpty = 'ai.ai_tts_empty';
  final keyPoints = 'ai.key_points';
  final risks = 'ai.risks';
}

class _PaymentLocales {
  const _PaymentLocales();
  final plansPricing = 'payment.plansPricing';
  final choosePlan = 'payment.choosePlan';
  final choosePlanSub = 'payment.choosePlanSub';
  final noProducts = 'payment.noProducts';
  final orderHistory = 'payment.orderHistory';
  final claimed = 'payment.claimed';
  final expiring = 'payment.expiring';
  final ended = 'payment.ended';
  final claimNow = 'payment.claimNow';
  final renewsOn = 'payment.renewsOn';
  final accessUntil = 'payment.accessUntil';
  final subscribeAgain = 'payment.subscribeAgain';
  final buyAgain = 'payment.buyAgain';
  final purchasedOnce = 'payment.purchasedOnce';
  final purchasedTimes = 'payment.purchasedTimes';
  final buyNow = 'payment.buyNow';
  final paymentLabel = 'payment.paymentLabel';
  final paid = 'payment.paid';
  final checkout = 'payment.checkout';

  final title = 'payment.title';
  final subscriptions = 'payment.subscriptions';
  final purchases = 'payment.purchases';
  final upgradePlan = 'payment.upgrade_plan';
  final active = 'payment.active';
  final canceled = 'payment.canceled';
  final cancelSubscription = 'payment.cancel_subscription';
  final resumeSubscription = 'payment.resume_subscription';
  final subscribeNow = 'payment.subscribe_now';
  final successTitle = 'payment.success_title';
  final successDesc = 'payment.success_desc';
  final cancelTitle = 'payment.cancel_title';
  final cancelDesc = 'payment.cancel_desc';
  final promoCode = 'payment.promo_code';
  final promoCodeHint = 'payment.promo_code_hint';
  final apply = 'payment.apply';
  final remove = 'payment.remove';
  final couponApplied = 'payment.coupon_applied';
  final discount = 'payment.discount';
  final totalDue = 'payment.total_due';
  final claimFreeAccess = 'payment.claim_free_access';
  final proceedToCheckout = 'payment.proceed_to_checkout';
  final free = 'payment.free';
  final orderSummary = 'payment.order_summary';
  final discountApplied = 'payment.discount_applied';
  final accessGranted = 'payment.access_granted';
  final invalidCheckout = 'payment.invalid_checkout';
  final checkoutFailed = 'payment.checkout_failed';
  final cancelFailed = 'payment.cancel_failed';
  final resumeFailed = 'payment.resume_failed';
  final couponValidationFailed = 'payment.coupon_validation_failed';

  final iap = const _PaymentIapLocales();
}

class _PaymentIapLocales {
  const _PaymentIapLocales();

  final failed = 'payment.iap.failed';
  final verifySuccess = 'payment.iap.verify_success';
  final verifyFailed = 'payment.iap.verify_failed';
  final disabled = 'payment.iap.disabled';
  final storeUnavailable = 'payment.iap.store_unavailable';
  final productNotFound = 'payment.iap.product_not_found';
  final initiateFailed = 'payment.iap.initiate_failed';
  final restoringPurchases = 'payment.iap.restoring_purchases';
  final restoreFailed = 'payment.iap.restore_failed';
  final serviceUnavailable = 'payment.iap.service_unavailable';
}

class _UserLocales {
  const _UserLocales();

  final profile = 'user.profile';
  final changeAvatar = 'user.change_avatar';
  final avatarHint = 'user.avatar_hint';
  final selectImage = 'user.select_image';
  final uploadAvatar = 'user.upload_avatar';
  final takePhoto = 'user.take_photo';
  final chooseFromGallery = 'user.choose_from_gallery';
  final cameraPermissionTitle = 'user.camera_permission_title';
  final cameraPermissionMessage = 'user.camera_permission_message';
  final photosPermissionTitle = 'user.photos_permission_title';
  final photosPermissionMessage = 'user.photos_permission_message';
  final uploadAvatarFailed = 'user.upload_avatar_failed';
  final updateSuccess = 'user.update_success';
  final updateFailed = 'user.update_failed';
  final accountInfo = 'user.account_info';
  final roles = 'user.roles';
  final permissions = 'user.permissions';
}

class _UpdateLocales {
  const _UpdateLocales();

  final title = 'update.title';
  final message = 'update.message';
  final prompt = 'update.prompt';
  final update = 'update.update';
  final later = 'update.later';
}

class _NotificationLocales {
  const _NotificationLocales();

  final title = 'notification.title';
  final all = 'notification.all';
  final unread = 'notification.unread';
  final read = 'notification.read';
  final markAllAsRead = 'notification.mark_all_as_read';
  final markAsRead = 'notification.mark_as_read';
  final empty = 'notification.empty';
  final loadMore = 'notification.load_more';
  final deleted = 'notification.deleted';
  final deleteTitle = 'notification.delete_title';
  final deleteConfirm = 'notification.delete_confirm';
  final failedToLoad = 'notification.failed_to_load';
  final viewAll = 'notification.view_all';
  final today = 'notification.today';
  final yesterday = 'notification.yesterday';
  final webOnlyTitle = 'notification.web_only_title';
  final webOnlyMessage = 'notification.web_only_message';
  final webOnlyConfirm = 'notification.web_only_confirm';
  final externalTitle = 'notification.external_title';
  final externalMessage = 'notification.external_message';
  final externalConfirm = 'notification.external_confirm';
  final openLink = 'notification.open_link';
  final readMore = 'notification.read_more';
}

class _AtomLocales {
  const _AtomLocales();
  final inPlanner = 'atom.inPlanner';
  final addFilesHint = 'atom.addFilesHint';
  final nothingHere = 'atom.nothingHere';
  final pullToRetry = 'atom.pullToRetry';
  final setMeetingDate = 'atom.setMeetingDate';
  final setCategory = 'atom.setCategory';
  final addFiles = 'atom.addFiles';
  final name = 'atom.name';

  final title = 'atom.title';
  final summary = 'atom.summary';
  final transcript = 'atom.transcript';
  final note = 'atom.note';
  final assets = 'atom.assets';
  final noSummary = 'atom.no_summary';
  final noTranscript = 'atom.no_transcript';
  final noNote = 'atom.no_note';
  final noAssets = 'atom.no_assets';
  final loadFailed = 'atom.load_failed';
  final retry = 'atom.retry';
  final copiedToClipboard = 'atom.copied_to_clipboard';
  final copy = 'atom.copy';

  // Delete flow
  final deleteAtom = 'atom.delete_atom';
  final deleteTitle = 'atom.delete_title';
  final deleteConfirmMsg = 'atom.delete_confirm_msg';
  final deleted = 'atom.deleted';
  final deleteFailed = 'atom.delete_failed';
}

class _CalendarLocales {
  const _CalendarLocales();
  final pageHeader = 'calendar.pageHeader';
  final headerSub = 'calendar.headerSub';
  final metricVisible = 'calendar.metricVisible';
  final metricRange = 'calendar.metricRange';
  final metricDay = 'calendar.metricDay';
  final openLiveView = 'calendar.openLiveView';
  final rangeDay = 'calendar.rangeDay';
  final rangeWeek = 'calendar.rangeWeek';
  final rangeMonth = 'calendar.rangeMonth';
  final dayMon = 'calendar.dayMon';
  final dayTue = 'calendar.dayTue';
  final dayWed = 'calendar.dayWed';
  final dayThu = 'calendar.dayThu';
  final dayFri = 'calendar.dayFri';
  final daySat = 'calendar.daySat';
  final daySun = 'calendar.daySun';
  final monthSchedule = 'calendar.monthSchedule';
  final scheduleFor = 'calendar.scheduleFor';

  final title = 'calendar.title';
  final scheduleLoadFailed = 'calendar.schedule_load_failed';
  final noEvents = 'calendar.no_events';
  final scheduled = 'calendar.scheduled';

  // Device-calendar sync workflow
  final addedToCalendar = 'calendar.added_to_calendar';
  final removedFromCalendar = 'calendar.removed_from_calendar';
  final syncFailed = 'calendar.sync_failed';
  final noWritableCalendar = 'calendar.no_writable_calendar';
  final saveInCalendarApp = 'calendar.save_in_calendar_app';
  final updateDateTime = 'calendar.update_date_time';
  final changeCalendar = 'calendar.change_calendar';
  final removeFromCalendar = 'calendar.remove_from_calendar';
  final openCalendarApp = 'calendar.open_calendar_app';
  final chooseCalendar = 'calendar.choose_calendar';
}

class _PermissionLocales {
  const _PermissionLocales();

  final title = 'permission.title';
  final subtitle = 'permission.subtitle';
  final grantAll = 'permission.grant_all';
  final done = 'permission.done';
  final notificationTitle = 'permission.notification_title';
  final notificationMessage = 'permission.notification_message';
  final notificationEnable = 'permission.notification_enable';
}

class _CreateLocales {
  const _CreateLocales();
  final title = 'create.title';
  final heading = 'create.heading';
  final headingSub = 'create.headingSub';
  final import = 'create.import';
  final openAsk = 'create.openAsk';
  final uploading = 'create.uploading';
  final captureLive = 'create.captureLive';
  final captureLiveSub = 'create.captureLiveSub';
  final sharedPayload = 'create.sharedPayload';
  final readyToImport = 'create.readyToImport';
  final uploadFile = 'create.uploadFile';
  final uploadFileSub = 'create.uploadFileSub';
  final noteTitle = 'create.noteTitle';
  final noteSub = 'create.noteSub';
  final shareTitle = 'create.shareTitle';
  final shareSub = 'create.shareSub';
  final sharedItem = 'create.sharedItem';
  final noteDraft = 'create.noteDraft';
  final nextSteps = 'create.nextSteps';
  final generateSummary = 'create.generateSummary';
  final generateSummarySub = 'create.generateSummarySub';
  final extractTasks = 'create.extractTasks';
  final extractTasksSub = 'create.extractTasksSub';
  final chipAudio = 'create.chipAudio';
  final chipVideo = 'create.chipVideo';
  final chipDocuments = 'create.chipDocuments';
  final recordNow = 'create.recordNow';
  final recordNowSub = 'create.recordNowSub';
  final noteFromShare = 'create.noteFromShare';
  final noteFromShareSub = 'create.noteFromShareSub';
  final askAboutThis = 'create.askAboutThis';
  final askAboutThisSub = 'create.askAboutThisSub';
  final attachExisting = 'create.attachExisting';
  final attachExistingSub = 'create.attachExistingSub';
  final destination = 'create.destination';
  final destinationSub = 'create.destinationSub';
  final backendRoute = 'create.backendRoute';
  final backendRouteSub = 'create.backendRouteSub';
  final stagePreview = 'create.stagePreview';
  final stageChoose = 'create.stageChoose';
  final stageDraft = 'create.stageDraft';
  final draftRefineHint = 'create.draftRefineHint';
  final working = 'create.working';
  final modeRecord = 'create.modeRecord';
  final addNow = 'create.addNow';
  final uploadAndCreate = 'create.uploadAndCreate';
  final createFromShared = 'create.createFromShared';
  final continueLabel = 'create.continueLabel';
  final turnTasksIntoAtom = 'create.turnTasksIntoAtom';
  final saveNote = 'create.saveNote';
  final attachedFile = 'create.attachedFile';
  final tapToBrowse = 'create.tapToBrowse';
  final readyToUploadHint = 'create.readyToUploadHint';
  final pickFileHint = 'create.pickFileHint';
  final pasteSharedHint = 'create.pasteSharedHint';
  final noteFieldHint = 'create.noteFieldHint';
  final pickSourceHint = 'create.pickSourceHint';
  final sharedReviewHint = 'create.sharedReviewHint';
  final category = 'create.category';
}

class _HomeLocales {
  const _HomeLocales();
  final itemsCount = 'home.itemsCount';
  final greeting = 'home.greeting';
  final weekInAtoms = 'home.weekInAtoms';
  final recentAtoms = 'home.recentAtoms';
  final noAtoms = 'home.noAtoms';
  final noAtomsFilterSub = 'home.noAtomsFilterSub';
  final noAtomsEmptySub = 'home.noAtomsEmptySub';
  final newAtom = 'home.newAtom';
  final loadFailed = 'home.loadFailed';
  final loadFailedSub = 'home.loadFailedSub';
  final askAtom = 'home.askAtom';
  final newAtomSheetSub = 'home.newAtomSheetSub';
  final devTools = 'home.devTools';
  final debugContent = 'home.debugContent';
  final debugLoading = 'home.debugLoading';
  final debugEmpty = 'home.debugEmpty';
  final openCalendar = 'home.openCalendar';
  final openLiveActivity = 'home.openLiveActivity';
  final sendTestLog = 'home.sendTestLog';
  final testLogSent = 'home.testLogSent';
  final filterAll = 'home.filterAll';
  final filterNew = 'home.filterNew';
  final filterPersonal = 'home.filterPersonal';

}
class _MediaLocales {
  const _MediaLocales();

  final playlistTitle = 'media.playlist_title';
  final playlistSubtitle = 'media.playlist_subtitle';
  final playlistEmpty = 'media.playlist_empty';
  final playAll = 'media.play_all';
  final downloadAll = 'media.download_all';
  final downloadAllStarted = 'media.download_all_started';
  final downloadAllNone = 'media.download_all_none';
  final typeAudio = 'media.type_audio';
  final typeVideo = 'media.type_video';
  final typeImage = 'media.type_image';
  final typeAttachment = 'media.type_attachment';
  final noPlayableMedia = 'media.no_playable_media';
  final openUnsupported = 'media.open_unsupported';
  final openFailed = 'media.open_failed';
  final openNoViewer = 'media.open_no_viewer';
  final download = 'media.download';
  final downloading = 'media.downloading';
  final downloadProgress = 'media.download_progress';
  final downloadQueued = 'media.download_queued';
  final downloadPaused = 'media.download_paused';
  final pauseDownload = 'media.pause_download';
  final resumeDownload = 'media.resume_download';
  final processing = 'media.processing';
  final downloaded = 'media.downloaded';
  final downloadFailed = 'media.download_failed';
  final removeDownload = 'media.remove_download';
  final removeDownloadTitle = 'media.remove_download_title';
  final removeDownloadConfirm = 'media.remove_download_confirm';
  final cancelDownload = 'media.cancel_download';
  final cancelDownloadTitle = 'media.cancel_download_title';
  final cancelDownloadConfirm = 'media.cancel_download_confirm';
  final downloadTooMany = 'media.download_too_many';
  final downloadComplete = 'media.download_complete';
  final downloadCompleteNamed = 'media.download_complete_named';
  final notificationChannelName = 'media.notification_channel_name';
  final notificationChannelDescription =
      'media.notification_channel_description';
  final offlineEmptyTitle = 'media.offline_empty_title';
  final offlineEmptyMessage = 'media.offline_empty_message';
  final removeDownloadStorageConfirm = 'media.remove_download_storage_confirm';
  final removeDownloadWithSize = 'media.remove_download_with_size';
  final freedStorage = 'media.freed_storage';
  final downloadWithSize = 'media.download_with_size';
  final downloadedWithSize = 'media.downloaded_with_size';
}

class _AudioLocales {
  const _AudioLocales();

  final title = 'audio.title';
  final playAll = 'audio.play_all';
  final nowPlaying = 'audio.now_playing';
  final play = 'audio.play';
  final pause = 'audio.pause';
  final next = 'audio.next';
  final previous = 'audio.previous';
  final playlistSubtitle = 'audio.playlist_subtitle';
  final playbackFailed = 'audio.playback_failed';
  final close = 'audio.close';
  final empty = 'audio.empty';
  final lyrics = 'audio.lyrics';
  final lyricsLoading = 'audio.lyrics_loading';
  final lyricsUnavailable = 'audio.lyrics_unavailable';
  final lyricsLoadFailed = 'audio.lyrics_load_failed';
  final lyricsTrack = 'audio.lyrics_track';
}

class _VideoLocales {
  const _VideoLocales();

  final title = 'video.title';
  final playAll = 'video.play_all';
  final nowPlaying = 'video.now_playing';
  final play = 'video.play';
  final pause = 'video.pause';
  final next = 'video.next';
  final previous = 'video.previous';
  final playlistSubtitle = 'video.playlist_subtitle';
  final playbackFailed = 'video.playback_failed';
  final close = 'video.close';
  final empty = 'video.empty';
  final settings = 'video.settings';
  final playbackSpeed = 'video.playback_speed';
  final speedNormal = 'video.speed_normal';
  final volume = 'video.volume';
  final subtitles = 'video.subtitles';
  final subtitlesOff = 'video.subtitles_off';
  final subtitlesUnavailable = 'video.subtitles_unavailable';
  final captions = 'video.captions';
}
