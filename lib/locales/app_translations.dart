// lib/locales/app_translations.dart
import 'package:get/get.dart';
import 'app_locales.dart';

/// Mirrors the web client's locales (en / my in `src/locales/*.json`).
/// Use with `'key'.tr` or `'key'.trParams({'email': ...})`.
class AppTranslations extends Translations {
  static const supportedLocales = {'en_US': 'English', 'my_MM': 'မြန်မာ'};

  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      // Common
      AppLocales.common.home: 'Home',
      AppLocales.common.welcomeHome: 'Welcome to AtomicOS!',
      AppLocales.common.loading: 'Loading...',
      AppLocales.common.signOut: 'Sign Out',
      AppLocales.common.goBack: 'Go Back',
      AppLocales.common.submit: 'Submit',
      AppLocales.common.save: 'Save',
      AppLocales.common.cancel: 'Cancel',
      AppLocales.common.rename: 'Rename',
      AppLocales.common.delete: 'Delete',
      AppLocales.common.confirm: 'Confirm',
      AppLocales.common.error: 'Error',
      AppLocales.common.success: 'Success',
      AppLocales.common.warning: 'Warning',
      AppLocales.common.info: 'Info',
      AppLocales.common.exit: 'Exit',
      AppLocales.common.exitTitle: 'Exit App',
      AppLocales.common.exitConfirm: 'Are you sure you want to exit the app?',
      AppLocales.common.connectionLost: 'Connection lost',
      AppLocales.common.connectionRestored: 'Connection is safe and sound',
      AppLocales.common.noInternet: 'No internet connection',

      // Auth Shared
      AppLocales.auth.shared.emailLabel: 'Email',
      AppLocales.auth.shared.emailHint: 'your@email.com',
      AppLocales.auth.shared.continueButton: 'Continue',
      AppLocales.auth.shared.useDifferentEmail: 'Use different email',
      AppLocales.auth.shared.passcodeLength: 'Passcode must be 6 digits',
      AppLocales.auth.shared.sessionExpired:
          'Your session has expired. Please sign in again.',
      AppLocales.auth.shared.sessionReplaced:
          'Your session was replaced by a newer sign in on this platform.',

      // Auth Initial
      AppLocales.auth.initial.title: 'Welcome to AtomicOS',
      AppLocales.auth.initial.subtitle:
          'Support dreams or make yours come true',
      AppLocales.auth.initial.continueWithGoogle: 'Continue with Google',
      AppLocales.auth.initial.or: 'or',
      AppLocales.auth.initial.emailHelper:
          'Enter your email to sign in or create an account',
      AppLocales.auth.initial.invalidEmail:
          'Please enter a valid email address. (e.g. example@domain.com)',
      AppLocales.auth.initial.checking: 'Checking...',
      AppLocales.auth.initial.googleFailure: 'Google authentication failed!',
      AppLocales.auth.initial.googleTooManyAttempts:
          'Too many attempts. Please wait @seconds seconds and try again.',
      AppLocales.auth.initial.connectionFailed:
          'Connection failed. Please try again.',
      AppLocales.auth.initial.goBack: 'Go Back',

      // Auth SignIn Passcode
      AppLocales.auth.signInPasscode.title: 'Sign In',
      AppLocales.auth.signInPasscode.heading: 'Enter your passcode',
      AppLocales.auth.signInPasscode.subtitle:
          'Enter your 6-digit passcode for @email',
      AppLocales.auth.signInPasscode.passcodeLabel: 'Passcode',
      AppLocales.auth.signInPasscode.signingIn: 'Signing in...',
      AppLocales.auth.signInPasscode.forgotPasscodeLink:
          'Forgot your passcode?',
      AppLocales.auth.signInPasscode.passcode6Digits:
          'Please enter 6-digit passcode',
      AppLocales.auth.signInPasscode.attemptsRemaining:
          'Attempts remaining before cooldown: @left/@total',
      AppLocales.auth.signInPasscode.cooldownMessage:
          'Too many incorrect passcode attempts. Please wait @seconds seconds.',
      AppLocales.auth.signInPasscode.tryAgainIn: 'Try again in @seconds⁠s',
      AppLocales.auth.signInPasscode.signInFailed:
          'Sign in failed. Please try again.',

      // Auth SignUp Passcode Create
      AppLocales.auth.signUpPasscodeCreate.title: 'Create Account',
      AppLocales.auth.signUpPasscodeCreate.heading: 'Create a passcode',
      AppLocales.auth.signUpPasscodeCreate.subtitle:
          "You'll use this 6-digit passcode to sign in",
      AppLocales.auth.signUpPasscodeCreate.googleHeading: 'One last step',
      AppLocales.auth.signUpPasscodeCreate.googleSubtitle:
          'Create and confirm a passcode to finish Google sign up',
      AppLocales.auth.signUpPasscodeCreate.instruction:
          'This will be used to quickly sign in to your account.',

      // Auth SignUp Passcode Confirm
      AppLocales.auth.signUpPasscodeConfirm.title: 'Confirm Passcode',
      AppLocales.auth.signUpPasscodeConfirm.heading: 'Confirm Passcode',
      AppLocales.auth.signUpPasscodeConfirm.subtitle:
          'Please confirm your passcode.',
      AppLocales.auth.signUpPasscodeConfirm.confirm: 'Confirm',
      AppLocales.auth.signUpPasscodeConfirm.changePasscode: 'Change Passcode',
      AppLocales.auth.signUpPasscodeConfirm.passcodesMismatch:
          'Passcodes do not match',
      AppLocales.auth.signUpPasscodeConfirm.sendingCode: 'Sending code...',

      // Auth SignUp Info
      AppLocales.auth.signUpInfo.title: 'Complete Profile',
      AppLocales.auth.signUpInfo.heading: 'Tell us about yourself',
      AppLocales.auth.signUpInfo.fullNameLabel: 'Full Name',
      AppLocales.auth.signUpInfo.fullNameHint: 'John Doe',
      AppLocales.auth.signUpInfo.usernameLabel: 'Username',
      AppLocales.auth.signUpInfo.usernameHint: 'john_doe',
      AppLocales.auth.signUpInfo.createAccountButton: 'Create Account',
      AppLocales.auth.signUpInfo.creatingAccount: 'Creating account...',
      AppLocales.auth.signUpInfo.enterFullName: 'Please enter your full name',
      AppLocales.auth.signUpInfo.fullNameMaxLength:
          'Full name cannot exceed 50 characters',
      AppLocales.auth.signUpInfo.fullNameForbiddenChars:
          'Full name cannot contain special characters (<, >, :, ;, ?)',
      AppLocales.auth.signUpInfo.usernameMinLength:
          'Username must be at least 3 characters',
      AppLocales.auth.signUpInfo.usernameMaxLength:
          'Username cannot exceed 30 characters',
      AppLocales.auth.signUpInfo.usernameCharset:
          'Username can only contain letters, numbers, and underscores',
      AppLocales.auth.signUpInfo.registrationFailed: 'Registration failed',

      // Auth Confirm Email
      AppLocales.auth.confirmEmail.title: 'Verify Email',
      AppLocales.auth.confirmEmail.heading: 'Verify your email',
      AppLocales.auth.confirmEmail.subtitle: 'We sent a 6-digit code to @email',
      AppLocales.auth.confirmEmail.confirmCodeButton: 'Verify Code',
      AppLocales.auth.confirmEmail.verifying: 'Verifying...',
      AppLocales.auth.confirmEmail.resendCode: 'Resend Code',
      AppLocales.auth.confirmEmail.resendCodeIn: 'Resend code in @seconds⁠s',
      AppLocales.auth.confirmEmail.enter6DigitCode: 'Please enter 6-digit code',
      AppLocales.auth.confirmEmail.verificationFailed: 'Verification failed',
      AppLocales.auth.confirmEmail.sendCodeFailed:
          'Failed to send verification code',

      // Auth Forgot Passcode
      AppLocales.auth.forgotPasscode.title: 'Forgot Passcode',
      AppLocales.auth.forgotPasscode.subtitle:
          'Enter your email and we will send you a link to reset your passcode.',
      AppLocales.auth.forgotPasscode.sendResetLink: 'Send Passcode Reset Link',
      AppLocales.auth.forgotPasscode.sending: 'Sending...',
      AppLocales.auth.forgotPasscode.backToSignIn: 'Back to Sign In',
      AppLocales.auth.forgotPasscode.resetFailed:
          'Failed to send reset instructions',

      // Settings
      AppLocales.setting.settings: 'Settings',
      AppLocales.setting.theme: 'Theme',
      AppLocales.setting.language: 'Language',
      AppLocales.setting.account: 'Account',
      AppLocales.setting.logoutConfirmation:
          'Are you sure you want to sign out?',
      AppLocales.setting.appInfo: 'App Info',
      AppLocales.setting.confirmDelete: 'Delete',
      AppLocales.setting.confirmClear: 'Clear',
      AppLocales.setting.clearHistoryTitle: 'Clear History',
      AppLocales.setting.clearHistoryConfirmMsg:
          'All messages in this conversation will be permanently deleted.',
      AppLocales.setting.deleteRoomTitle: 'Delete Room',
      AppLocales.setting.deleteRoomConfirmMsg:
          'This room and all its messages will be permanently deleted.',
      AppLocales.setting.cancelSubTitle: 'Cancel Subscription',
      AppLocales.setting.cancelSubConfirmMsg:
          'Your subscription will remain active until the end of the billing period.',

      // AI
      AppLocales.ai.title: 'AI Assistant',
      AppLocales.ai.rooms: 'Chat Rooms',
      AppLocales.ai.newChat: 'New Conversation',
      AppLocales.ai.defaultGreeting:
          "Hello! I'm your AI assistant. How can I help you today?",
      AppLocales.ai.messagesCount: '@count messages',
      AppLocales.ai.listen: 'Listen',
      AppLocales.ai.thinking: 'AI is thinking',
      AppLocales.ai.cancelListening: 'Cancel listening',
      AppLocales.ai.typeMessage: 'Type your message...',
      AppLocales.ai.send: 'Send',
      AppLocales.ai.composerHint: 'Message AtomicOS…',
      AppLocales.ai.retry: 'Retry',
      AppLocales.ai.searchAtomsHint: 'Search your atoms…',
      AppLocales.ai.attachSheetTitle: 'Attach to your message',
      AppLocales.ai.sourceAtomSub: 'Ask about one of your atoms',
      AppLocales.ai.usingAsContext: 'Using "@name" as context',
      AppLocales.ai.selected: 'Selected',
      AppLocales.ai.processing: 'AI is thinking...',
      AppLocales.ai.clearHistory: 'Clear History',
      AppLocales.ai.micPermissionTitle: 'Microphone access required',
      AppLocales.ai.micPermissionMessage:
          'Voice input needs microphone access. Open Settings to enable it for this app.',
      AppLocales.ai.openSettings: 'Open Settings',
      AppLocales.ai.askSourcePhoto: 'Photo',
      AppLocales.ai.askSourceFiles: 'Files',
      AppLocales.ai.askSourceAtom: 'Add Atom',
      AppLocales.ai.aiSendMessageFailed: 'Failed to send message',
      AppLocales.ai.aiResponseFailed: 'Failed to get AI response',
      AppLocales.ai.aiHistoryCleared: 'Chat history cleared',
      AppLocales.ai.aiClearHistoryFailed: 'Failed to clear history',
      AppLocales.ai.aiStartRecordingFailed: 'Failed to start recording',
      AppLocales.ai.aiTranscriptionFailed: 'Failed to transcribe audio',
      AppLocales.ai.aiTtsFailed: 'Failed to play speech',
      AppLocales.ai.aiTtsEmpty: 'Nothing to speak',
      AppLocales.ai.keyPoints: 'Key points',
      AppLocales.ai.actionItems: 'Action items',
      AppLocales.ai.risks: 'Risks',

      // Feedback
      AppLocales.feedback.title: 'Share Your Feedback',
      AppLocales.feedback.description:
          'We value your thoughts and ideas to help improve AtomicOS.',
      AppLocales.feedback.rateExperience: 'Rate your experience (1 - 10)',
      AppLocales.feedback.tellUsMore: "What's on your mind?",
      AppLocales.feedback.placeholder:
          'Tell us anything — bugs, suggestions, questions, or ideas. We triage automatically!',
      AppLocales.feedback.submit: 'Send Feedback',
      AppLocales.feedback.submitting: 'Submitting...',
      AppLocales.feedback.successMessage: 'Thank you for your feedback!',

      // Payment
      AppLocales.payment.title: 'Billing & Subscriptions',
      AppLocales.payment.subscriptions: 'Subscriptions',
      AppLocales.payment.transactions: 'Transactions',
      AppLocales.payment.upgradePlan: 'Upgrade Plan',
      AppLocales.payment.active: 'Active',
      AppLocales.payment.canceled: 'Canceled',
      AppLocales.payment.cancelSubscription: 'Cancel Subscription',
      AppLocales.payment.resumeSubscription: 'Resume Subscription',
      AppLocales.payment.subscribeNow: 'Subscribe Now',
      AppLocales.payment.successTitle: 'Payment Successful!',
      AppLocales.payment.successDesc:
          'Your payment has been processed and your features are active.',
      AppLocales.payment.cancelTitle: 'Payment Canceled',
      AppLocales.payment.cancelDesc:
          'Your payment was canceled. No charges were made.',

      // User
      AppLocales.user.profile: 'User Profile',
      AppLocales.user.changeAvatar: 'Change Avatar',
      AppLocales.user.avatarHint:
          'Upload a new profile picture (PNG, JPG, WebP supported)',
      AppLocales.user.selectImage: 'Choose Image',
      AppLocales.user.uploadAvatar: 'Upload Avatar',
      AppLocales.user.takePhoto: 'Take photo',
      AppLocales.user.chooseFromGallery: 'Choose from gallery',
      AppLocales.user.cameraPermissionTitle: 'Camera access required',
      AppLocales.user.cameraPermissionMessage:
          'Taking a profile photo needs camera access. Open Settings to enable it for this app.',
      AppLocales.user.photosPermissionTitle: 'Photo library access required',
      AppLocales.user.photosPermissionMessage:
          'Choosing a profile photo needs photo library access. Open Settings to enable it for this app.',
      AppLocales.user.uploadAvatarFailed: 'Could not upload profile photo',
      AppLocales.user.updateSuccess: 'Profile saved successfully',
      AppLocales.user.updateFailed: 'Could not update profile',
      AppLocales.user.accountInfo: 'Account Information',
      AppLocales.user.roles: 'Roles',
      AppLocales.user.permissions: 'Permissions',

      // Notification
      AppLocales.notification.title: 'Notifications',
      AppLocales.notification.all: 'All',
      AppLocales.notification.unread: 'Unread',
      AppLocales.notification.read: 'Read',
      AppLocales.notification.markAllAsRead: 'Mark all as read',
      AppLocales.notification.markAsRead: 'Mark as read',
      AppLocales.notification.empty: 'No notifications yet',
      AppLocales.notification.loadMore: 'Load more',
      AppLocales.notification.deleted: 'Notification deleted',
      AppLocales.notification.failedToLoad: 'Failed to load notifications',
      AppLocales.notification.viewAll: 'View all',
      AppLocales.notification.today: 'Today',
      AppLocales.notification.yesterday: 'Yesterday',

      // Update
      AppLocales.update.title: 'Update App?',
      AppLocales.update.message: 'A new version of the app is available.',
      AppLocales.update.prompt: 'Would you like to update it now?',
      AppLocales.update.update: 'UPDATE NOW',
      AppLocales.update.later: 'LATER',

      // Atom
      AppLocales.atom.title: 'Atom',
      AppLocales.atom.summary: 'Summary',
      AppLocales.atom.transcript: 'Transcripts',
      AppLocales.atom.note: 'Note',
      AppLocales.atom.assets: 'Assets',
      AppLocales.atom.noSummary: 'No summary yet',
      AppLocales.atom.noTranscript: 'No transcript yet',
      AppLocales.atom.noNote: 'No note',
      AppLocales.atom.noAssets: 'No assets',
      AppLocales.atom.loadFailed: "Couldn't load this atom",
      AppLocales.atom.retry: 'Retry',
      AppLocales.atom.copiedToClipboard: 'Copied to clipboard',
      AppLocales.atom.copy: 'Copy',

      // Calendar
      AppLocales.calendar.title: 'Planner',
      AppLocales.calendar.scheduleLoadFailed: "Couldn't load your schedule",
      AppLocales.calendar.noEvents: 'No events for the selected range',
      AppLocales.calendar.scheduled: 'Scheduled',

      // Permission
      AppLocales.permission.title: 'Permissions',
      AppLocales.permission.subtitle:
          'Allow access so you can record meetings, capture media, and attach files.',
      AppLocales.permission.grantAll: 'Grant all',
      AppLocales.permission.done: 'Done',
      AppLocales.permission.notificationTitle: 'Enable notifications',
      AppLocales.permission.notificationMessage:
          'Allow notifications so a recording keeps running in the background and you can pause or stop it from the notification.',
      AppLocales.permission.notificationEnable: 'Enable',

      // Search
      AppLocales.search.placeholder: 'Search atoms or meetings',
      AppLocales.search.emptyTitle: 'No result found!',
      AppLocales.search.emptyMessage:
          "The atom you're looking for doesn't exist. Try searching for another atom.",

      // Recording
      AppLocales.recording.endTitle: 'End recording?',
      AppLocales.recording.endMessage:
          'This stops the recording and turns the transcript into an atom. You can read and edit it afterwards.',
      AppLocales.recording.endConfirm: 'End & create atom',

      // AI workspace (ask + recording)
      AppLocales.ai.meetingNoteHint: 'Write a Meeting Note...',
      AppLocales.ai.processingMeeting: 'Processing meeting',
      AppLocales.ai.processingMeetingSub:
          'AtomicOS is building summary, transcript, and actions from the captured audio.',
      AppLocales.ai.meetingReady: 'Meeting ready',
      AppLocales.ai.meetingReadySub:
          'Preview generated outputs, then jump into the full details view.',
      AppLocales.ai.recordingPausedTitle: 'Recording paused',
      AppLocales.ai.recordingPausedSub:
          'Notes stay editable while the mic is paused. Resume when the meeting continues.',
      AppLocales.ai.askTitle: 'Ask AtomicOS',
      AppLocales.ai.askSubtitle:
          'Start with a question, attach context, and turn the answer into structured next steps.',
      AppLocales.ai.resultSummary: 'Summary',
      AppLocales.ai.resultDecisions: 'Decisions',
      AppLocales.ai.resultTasks: 'Tasks',
      AppLocales.ai.actionSummarySub:
          'Condense the answer into the shortest useful version',
      AppLocales.ai.actionDecisionsSub:
          'Pull out calls, approvals, and resolved questions',
      AppLocales.ai.actionFusion: 'Fusion with',
      AppLocales.ai.actionFusionSub:
          'Translate or reshape the answer for a different audience',
      AppLocales.ai.actionTasks: 'Generate tasks',
      AppLocales.ai.actionTasksSub:
          'Turn the response into concrete follow-up work',
      AppLocales.ai.actionReport: 'Generate analytic report',
      AppLocales.ai.actionReportSub:
          'Build a longer structured readout with sections',
      AppLocales.ai.noTranscript: 'No transcript yet',
      AppLocales.ai.noTranscriptSub:
          'Start recording or ask a question to generate content.',
      AppLocales.ai.today: 'Today',
      AppLocales.ai.source: 'Source',
      AppLocales.ai.participants: 'Participants',
      AppLocales.ai.askAboutThisAtom: 'Ask about this Atom',
      AppLocales.ai.askAboutThisAtomSub:
          'Open the AI workspace with this note as the current context.',
      AppLocales.ai.noAssets: 'No assets yet',
      AppLocales.ai.noAssetsSub:
          'Attachments and imported files will appear here.',
      AppLocales.ai.addMoreFiles: 'Add more files',
      AppLocales.ai.addMoreFilesSub1:
          'Upload and import previews will surface here next.',
      AppLocales.ai.addMoreFilesSub2:
          'Keep supporting documents connected to this atom.',
      AppLocales.ai.generatingOutputs: 'Generating outputs',
      AppLocales.ai.outputsReady: 'Outputs ready',
      AppLocales.ai.actionItems: 'Action items',
      AppLocales.ai.attachAsContext: 'Attach as context',
      AppLocales.ai.chooseContext: 'Choose context',
      AppLocales.ai.chooseContextSub:
          'Pick one of your atoms so AtomicOS answers with real context.',
      AppLocales.ai.noAtomsHere: 'No atoms here yet',
      AppLocales.ai.noAtomsHereSub:
          'Create an atom first, then attach it as context.',
      AppLocales.ai.workWithAnswer: 'Work with this answer',
      AppLocales.ai.runActionHint:
          'Run an action to generate a backend response preview.',
      AppLocales.ai.detailsTab: 'Details',
      AppLocales.ai.overview: 'Overview',
      AppLocales.ai.contextCards: 'Context cards',
      AppLocales.ai.attachments: 'Attachments',
      AppLocales.ai.processingPanelSub:
          'Transcript segments, summary blocks, and tasks are being prepared.',
      AppLocales.ai.outputsReadySub:
          'You can now review summary, transcript, note, and asset previews.',
      AppLocales.ai.processingPreview: 'Processing preview...',
      AppLocales.ai.readyOpenDetails: 'Ready. Open details.',
      AppLocales.ai.needsRetry: 'Needs retry',
      AppLocales.ai.thinking: 'AtomicOS is thinking…',

      // Create / details / calendar / recording (round 3)
      AppLocales.create.stagePreview: 'Preview',
      AppLocales.create.stageChoose: 'Choose',
      AppLocales.create.stageDraft: 'Draft',
      AppLocales.create.draftRefineHint:
          'Draft notes can be refined into summaries and task lists first.',
      AppLocales.create.working: 'Working...',
      AppLocales.create.modeRecord: 'Record',
      AppLocales.create.addNow: 'Add Now',
      AppLocales.create.uploadAndCreate: 'Upload and create',
      AppLocales.create.createFromShared: 'Create from shared text',
      AppLocales.create.continueLabel: 'Continue',
      AppLocales.create.turnTasksIntoAtom: 'Turn tasks into Atom',
      AppLocales.create.saveNote: 'Save note',
      AppLocales.create.pickSourceHint:
          'Pick a source above to bring it into your workspace.',
      AppLocales.create.sharedReviewHint:
          'Shared payloads can be reviewed before they are saved.',
      AppLocales.create.attachedFile: 'Attached file',
      AppLocales.create.tapToBrowse: 'Tap to browse device storage',
      AppLocales.create.readyToUploadHint:
          'Ready to upload and create an atom · tap to change',
      AppLocales.create.pickFileHint: 'Pick a file, image, video, or document',
      AppLocales.create.pasteSharedHint: 'Paste shared text here...',
      AppLocales.create.noteFieldHint: 'Type or paste a note...',
      AppLocales.atom.setMeetingDate: 'Set meeting date',
      AppLocales.atom.addFiles: 'Add files',
      AppLocales.atom.name: 'Atom name',
      AppLocales.calendar.rangeDay: 'Day',
      AppLocales.calendar.rangeWeek: 'Week',
      AppLocales.calendar.rangeMonth: 'Month',
      AppLocales.calendar.dayMon: 'MO',
      AppLocales.calendar.dayTue: 'TU',
      AppLocales.calendar.dayWed: 'WE',
      AppLocales.calendar.dayThu: 'TH',
      AppLocales.calendar.dayFri: 'FR',
      AppLocales.calendar.daySat: 'SA',
      AppLocales.calendar.daySun: 'SU',
      AppLocales.calendar.monthSchedule: 'Month schedule',
      AppLocales.calendar.scheduleFor: 'Schedule for @day',
      AppLocales.recording.noteFieldHint: 'Write a Meeting Note…',
      AppLocales.recording.transcriptPlaceholder:
          'Live transcript will appear here as you speak…',
      AppLocales.recording.badgeLive: 'LIVE',
      AppLocales.recording.badgeOff: 'OFF',
      AppLocales.recording.transcriptOffline:
          'Live transcript is offline — reconnect to stream it.',
      AppLocales.recording.transcriptMicNeeded:
          'Microphone permission is needed for the live transcript.',
      AppLocales.recording.transcriptOfflineRecording:
          'Live transcript is offline — the audio is still being recorded.',
      AppLocales.recording.transcriptUnavailable:
          'Live transcript is unavailable right now.',

      // Home + payment (round 4)
      AppLocales.home.greeting: 'Hello, @name!',
      AppLocales.home.weekInAtoms: 'Your week, in atoms',
      AppLocales.home.recentAtoms: 'Recent atoms',
      AppLocales.home.noAtoms: 'No Atoms found',
      AppLocales.home.noAtomsFilterSub: 'Try a different search or filter.',
      AppLocales.home.noAtomsEmptySub:
          'Create a new atom to populate this workspace.',
      AppLocales.home.newAtom: 'New Atom',
      AppLocales.home.loadFailed: 'Could not load your workspace',
      AppLocales.home.loadFailedSub: 'Check your connection and try again.',
      AppLocales.home.askAtom: 'Ask Atom',
      AppLocales.home.newAtomSheetSub:
          'Choose the fastest way to capture context into AtomicOS.',
      AppLocales.home.devTools: 'Dev tools',
      AppLocales.home.debugContent: 'Content',
      AppLocales.home.debugLoading: 'Loading',
      AppLocales.home.debugEmpty: 'Empty',
      AppLocales.home.openCalendar: 'Open Calendar',
      AppLocales.home.openLiveActivity: 'Open Live Activity',
      AppLocales.home.sendTestLog: 'Send manual test log',
      AppLocales.home.testLogSent: 'Test log sent to backend',
      AppLocales.home.filterAll: 'All',
      AppLocales.home.filterNew: 'New',
      AppLocales.home.filterPersonal: 'Personal',
      AppLocales.payment.plansPricing: 'Plans & Pricing',
      AppLocales.payment.choosePlan: 'Choose Your Plan',
      AppLocales.payment.choosePlanSub:
          'Select the option that works best for you',
      AppLocales.payment.noProducts: 'No products available right now.',
      AppLocales.payment.orderHistory: 'Order History',
      AppLocales.payment.claimed: 'Claimed',
      AppLocales.payment.expiring: 'Expiring',
      AppLocales.payment.ended: 'Ended',
      AppLocales.payment.claimNow: 'Claim Now',
      AppLocales.payment.renewsOn: 'Renews automatically on @date',
      AppLocales.payment.accessUntil: 'Access remains active until @date',
      AppLocales.payment.subscribeAgain: 'Subscribe Again',
      AppLocales.payment.buyAgain: 'Buy Again',
      AppLocales.payment.purchasedOnce: 'Purchased once',
      AppLocales.payment.purchasedTimes: 'Purchased @count times',
      AppLocales.payment.buyNow: 'Buy Now',
      AppLocales.payment.paymentLabel: 'Payment',
      AppLocales.payment.paid: 'Paid',
      AppLocales.payment.checkout: 'Checkout',
      AppLocales.ai.sourcePhotoSub: 'Attach a photo',
      AppLocales.ai.sourceFilesSub: 'Attach a file',
      AppLocales.ai.attachedFile: 'Attached @name',
      AppLocales.ai.filePickerFailed: 'Could not open the file picker',
      AppLocales.home.itemsCount: '@count items in this workspace',
      AppLocales.create.title: 'Create Atom',
      AppLocales.create.heading: 'Bring anything into AtomicOS',
      AppLocales.create.headingSub:
          'Upload media or turn shared text into a saved atom.',
      AppLocales.create.import: 'Import',
      AppLocales.create.openAsk: 'Open Ask AtomicOS',
      AppLocales.create.uploading: 'Uploading…',
      AppLocales.create.captureLive: 'Capture a live conversation',
      AppLocales.create.captureLiveSub:
          'AtomicOS records, transcribes and summarizes the session into a new atom.',
      AppLocales.create.sharedPayload: 'Shared payload',
      AppLocales.create.readyToImport: 'Ready to import',
      AppLocales.create.uploadFile: 'Upload a file',
      AppLocales.create.uploadFileSub: 'Audio, video, or documents',
      AppLocales.create.noteTitle: 'Note',
      AppLocales.create.noteSub: 'Type or paste your text',
      AppLocales.create.shareTitle: 'Share from another app',
      AppLocales.create.shareSub: 'From the system share sheet',
      AppLocales.create.sharedItem: 'Shared item',
      AppLocales.create.noteDraft: 'Note draft',
      AppLocales.create.nextSteps: 'Next steps',
      AppLocales.create.generateSummary: 'Generate summary',
      AppLocales.create.generateSummarySub: 'Create a clean executive version',
      AppLocales.create.extractTasks: 'Extract tasks',
      AppLocales.create.extractTasksSub: 'Turn the note into next actions',
      AppLocales.create.chipAudio: 'Audio',
      AppLocales.create.chipVideo: 'Video',
      AppLocales.create.chipDocuments: 'Documents',
      AppLocales.create.recordNow: 'Record Now',
      AppLocales.create.recordNowSub: 'Start capturing audio with AtomicOS',
      AppLocales.create.noteFromShare: 'Create note from share',
      AppLocales.create.noteFromShareSub:
          'Convert the raw text into a structured note',
      AppLocales.create.askAboutThis: 'Ask AtomicOS about this',
      AppLocales.create.askAboutThisSub:
          'Generate summary, decisions, and tasks',
      AppLocales.create.attachExisting: 'Attach to existing Atom',
      AppLocales.create.attachExistingSub:
          'Merge with a previous meeting workspace',
      AppLocales.create.destination: 'Destination',
      AppLocales.create.destinationSub: 'New atom from shared text',
      AppLocales.create.backendRoute: 'Backend route',
      AppLocales.create.backendRouteSub:
          'Creates via POST /v1/atoms/from-share',
      AppLocales.atom.inPlanner: 'In planner',
      AppLocales.atom.addFilesHint: 'Add files to support your meeting notes.',
      AppLocales.atom.nothingHere: 'Nothing here yet',
      AppLocales.atom.pullToRetry:
          'Pull to retry the detail request and restore this workspace.',
      AppLocales.calendar.pageHeader: 'Calendar',
      AppLocales.calendar.headerSub:
          'Review upcoming sessions, then jump straight into the live workspace.',
      AppLocales.calendar.metricVisible: 'Visible',
      AppLocales.calendar.metricRange: 'Range',
      AppLocales.calendar.metricDay: 'Day',
      AppLocales.calendar.openLiveView: 'Open live view',
      AppLocales.recording.liveMeeting: 'Live meeting',
      AppLocales.recording.end: 'End',
    },
    'my_MM': {
      // Common
      AppLocales.common.home: 'ပင်မ',
      AppLocales.common.welcomeHome: 'AtomicOS မှ ကြိုဆိုပါတယ်!',
      AppLocales.common.loading: 'လုပ်ဆောင်နေဆဲ...',
      AppLocales.common.signOut: 'ထွက်မည်',
      AppLocales.common.goBack: 'နောက်သို့',
      AppLocales.common.submit: 'တင်မည်',
      AppLocales.common.save: 'သိမ်းမည်',
      AppLocales.common.cancel: 'ပယ်ဖျက်',
      AppLocales.common.rename: 'အမည်ပြောင်းရန်',
      AppLocales.common.delete: 'ဖျက်မည်',
      AppLocales.common.confirm: 'အတည်ပြု',
      AppLocales.common.error: 'အမှား',
      AppLocales.common.success: 'အောင်မြင်သည်',
      AppLocales.common.warning: 'သတိပေးချက်',
      AppLocales.common.info: 'အချက်အလက်',
      AppLocales.common.exit: 'ထွက်မည်',
      AppLocales.common.exitTitle: 'အက်ပ်မှ ထွက်မည်',
      AppLocales.common.exitConfirm: 'ထွက်ရန် သေချာပါသလား?',
      AppLocales.common.connectionLost: 'အင်တာနက်လိုင်း ပြတ်တောက်သွားပါသည်',
      AppLocales.common.connectionRestored:
          'အင်တာနက်လိုင်း ပြန်လည်ကောင်းမွန်သွားပါပြီ',
      AppLocales.common.noInternet: 'အင်တာနက်လိုင်း မရှိပါ',

      // Auth Shared
      AppLocales.auth.shared.emailLabel: 'အီးမေးလ်',
      AppLocales.auth.shared.emailHint: 'your@email.com',
      AppLocales.auth.shared.continueButton: 'ဆက်လုပ်မည်',
      AppLocales.auth.shared.useDifferentEmail: 'အခြားအီးမေးလ် သုံးမည်',
      AppLocales.auth.shared.passcodeLength:
          'စကားဝှက်သည် ဂဏန်း ၆ လုံး ဖြစ်ရမည်',
      AppLocales.auth.shared.sessionExpired:
          'အသုံးပြုချိန် ကုန်ဆုံးသွားပါပြီ။ ပြန်ဝင်ပါ။',
      AppLocales.auth.shared.sessionReplaced:
          'ဤစက်ပေါ်တွင် အသစ်ဝင်ရောက်မှုကြောင့် session အစားထိုးခံရပါသည်။',

      // Auth Initial
      AppLocales.auth.initial.title: 'AtomicOS မှ ကြိုဆိုပါသည်',
      AppLocales.auth.initial.subtitle: 'အိပ်မက်များကို အကောင်အထည်ဖော်လိုက်ပါ',
      AppLocales.auth.initial.continueWithGoogle: 'Google ဖြင့် ဆက်ရန်',
      AppLocales.auth.initial.or: 'သို့မဟုတ်',
      AppLocales.auth.initial.emailHelper:
          'အကောင့်ဝင်ရန် သို့မဟုတ် အသစ်ဖွင့်ရန် အီးမေးလ် ထည့်ပါ',
      AppLocales.auth.initial.invalidEmail:
          'မှန်ကန်သော အီးမေးလ် ထည့်ပါ (ဥပမာ example@domain.com)',
      AppLocales.auth.initial.checking: 'စစ်ဆေးနေဆဲ...',
      AppLocales.auth.initial.googleFailure: 'Google ဖြင့် အတည်ပြု၍ မရပါ!',
      AppLocales.auth.initial.googleTooManyAttempts:
          'အကြိမ်များလွန်းပါသည်။ @seconds စက္ကန့် စောင့်ပြီး ထပ်စမ်းပါ။',
      AppLocales.auth.initial.connectionFailed: 'ချိတ်ဆက်မှု မရပါ။ ထပ်စမ်းပါ။',
      AppLocales.auth.initial.goBack: 'နောက်သို့',

      // Auth SignIn Passcode
      AppLocales.auth.signInPasscode.title: 'လော့ဂ်အင်',
      AppLocales.auth.signInPasscode.heading: 'စကားဝှက် ထည့်ပါ',
      AppLocales.auth.signInPasscode.subtitle:
          '@email အတွက် ဂဏန်း ၆ လုံး စကားဝှက် ထည့်ပါ',
      AppLocales.auth.signInPasscode.passcodeLabel: 'စကားဝှက်',
      AppLocales.auth.signInPasscode.signingIn: 'ဝင်နေဆဲ...',
      AppLocales.auth.signInPasscode.forgotPasscodeLink:
          'စကားဝှက် မေ့နေပါသလား?',
      AppLocales.auth.signInPasscode.passcode6Digits:
          'ဂဏန်း ၆ လုံး စကားဝှက် ထည့်ပါ',
      AppLocales.auth.signInPasscode.attemptsRemaining:
          'ကျန်ကြိုးစားခွင့်: @left/@total',
      AppLocales.auth.signInPasscode.cooldownMessage:
          'စကားဝှက် မှားလွန်းပါသည်။ @seconds စက္ကန့် စောင့်ပါ။',
      AppLocales.auth.signInPasscode.tryAgainIn:
          '@seconds⁠s အကြာတွင် ထပ်စမ်းပါ',
      AppLocales.auth.signInPasscode.signInFailed:
          'လော့ဂ်အင် မအောင်မြင်ပါ။ ထပ်စမ်းပါ။',

      // Auth SignUp Passcode Create
      AppLocales.auth.signUpPasscodeCreate.title: 'အကောင့်ဖွင့်မည်',
      AppLocales.auth.signUpPasscodeCreate.heading: 'စကားဝှက် သတ်မှတ်ပါ',
      AppLocales.auth.signUpPasscodeCreate.subtitle:
          'လော့ဂ်အင်ဝင်ရန် ဤဂဏန်း ၆ လုံး စကားဝှက်ကို သုံးပါမည်',
      AppLocales.auth.signUpPasscodeCreate.googleHeading: 'နောက်ဆုံးအဆင့်',
      AppLocales.auth.signUpPasscodeCreate.googleSubtitle:
          'Google အကောင့်ဖွင့်ရန် စကားဝှက် သတ်မှတ်အတည်ပြုပါ',
      AppLocales.auth.signUpPasscodeCreate.instruction:
          'အကောင့်သို့ အမြန်ဝင်ရန် ဤကုဒ်ကို သုံးပါမည်။',

      // Auth SignUp Passcode Confirm
      AppLocales.auth.signUpPasscodeConfirm.title: 'စကားဝှက် အတည်ပြုပါ',
      AppLocales.auth.signUpPasscodeConfirm.heading: 'စကားဝှက် အတည်ပြုပါ',
      AppLocales.auth.signUpPasscodeConfirm.subtitle: 'စကားဝှက်ကို အတည်ပြုပါ။',
      AppLocales.auth.signUpPasscodeConfirm.confirm: 'အတည်ပြု',
      AppLocales.auth.signUpPasscodeConfirm.changePasscode:
          'စကားဝှက် ပြောင်းမည်',
      AppLocales.auth.signUpPasscodeConfirm.passcodesMismatch:
          'စကားဝှက်များ မကိုက်ညီပါ',
      AppLocales.auth.signUpPasscodeConfirm.sendingCode: 'ကုဒ် ပို့နေဆဲ...',

      // Auth SignUp Info
      AppLocales.auth.signUpInfo.title: 'ပရိုဖိုင် ဖြည့်ပါ',
      AppLocales.auth.signUpInfo.heading: 'သင့်အကြောင်း ပြောပြပါ',
      AppLocales.auth.signUpInfo.fullNameLabel: 'အမည်',
      AppLocales.auth.signUpInfo.fullNameHint: 'မောင်မောင်',
      AppLocales.auth.signUpInfo.usernameLabel: 'အသုံးပြုသူအမည်',
      AppLocales.auth.signUpInfo.usernameHint: 'maung_maung',
      AppLocales.auth.signUpInfo.createAccountButton: 'အကောင့်ဖွင့်မည်',
      AppLocales.auth.signUpInfo.creatingAccount: 'အကောင့် ဖွင့်နေဆဲ...',
      AppLocales.auth.signUpInfo.enterFullName: 'အမည် ထည့်ပါ',
      AppLocales.auth.signUpInfo.fullNameMaxLength:
          'နာမည် အများဆုံး အလုံး ၅၀ သာ ဖြစ်ရပါမည်',
      AppLocales.auth.signUpInfo.fullNameForbiddenChars:
          'နာမည်တွင် ခွင့်မပြုသော စာလုံးများ (<, >, :, ;, ?) မပါဝင်ရပါ',
      AppLocales.auth.signUpInfo.usernameMinLength:
          'Username အနည်းဆုံး ၃ လုံး ရှိရမည်',
      AppLocales.auth.signUpInfo.usernameMaxLength:
          'Username အများဆုံး အလုံး ၃၀ သာ ဖြစ်ရမည်',
      AppLocales.auth.signUpInfo.usernameCharset:
          'Username တွင် စာလုံး၊ ဂဏန်းနှင့် _ သာ ရပါမည်',
      AppLocales.auth.signUpInfo.registrationFailed: 'အကောင့်ဖွင့်၍ မရပါ',

      // Auth Confirm Email
      AppLocales.auth.confirmEmail.title: 'အီးမေးလ် အတည်ပြုပါ',
      AppLocales.auth.confirmEmail.heading: 'အီးမေးလ်ကို အတည်ပြုပါ',
      AppLocales.auth.confirmEmail.subtitle:
          '@email သို့ ဂဏန်း ၆ လုံး ကုဒ် ပို့ထားပါသည်',
      AppLocales.auth.confirmEmail.confirmCodeButton: 'ကုဒ် အတည်ပြုမည်',
      AppLocales.auth.confirmEmail.verifying: 'အတည်ပြုနေဆဲ...',
      AppLocales.auth.confirmEmail.resendCode: 'ကုဒ် ပြန်ပို့မည်',
      AppLocales.auth.confirmEmail.resendCodeIn:
          '@seconds⁠s အတွင်း ပြန်ပို့နိုင်သည်',
      AppLocales.auth.confirmEmail.enter6DigitCode: 'ဂဏန်း ၆ လုံး ကုဒ် ထည့်ပါ',
      AppLocales.auth.confirmEmail.verificationFailed:
          'အတည်ပြုမှု မအောင်မြင်ပါ',
      AppLocales.auth.confirmEmail.sendCodeFailed: 'အတည်ပြုကုဒ် ပို့၍မရပါ',

      // Auth Forgot Passcode
      AppLocales.auth.forgotPasscode.title: 'စကားဝှက် မေ့နေပါသလား',
      AppLocales.auth.forgotPasscode.subtitle:
          'အီးမေးလ်ထည့်ပါ။ စကားဝှက် လင့်ခ် ပို့ပေးပါမည်။',
      AppLocales.auth.forgotPasscode.sendResetLink: 'လင့်ခ် ပို့မည်',
      AppLocales.auth.forgotPasscode.sending: 'ပို့နေဆဲ...',
      AppLocales.auth.forgotPasscode.backToSignIn: 'လော့ဂ်အင်သို့ ပြန်သွားမည်',
      AppLocales.auth.forgotPasscode.resetFailed: 'လမ်းညွှန်ချက် ပို့၍မရပါ',

      // Settings
      AppLocales.setting.settings: 'ဆက်တင်များ',
      AppLocales.setting.theme: 'အပြင်အဆင်',
      AppLocales.setting.language: 'ဘာသာစကား',
      AppLocales.setting.account: 'အကောင့်',
      AppLocales.setting.logoutConfirmation: 'ထွက်ရန် သေချာပါသလား?',
      AppLocales.setting.appInfo: 'အက်ပ် အချက်အလက်',
      AppLocales.setting.confirmDelete: 'ဖျက်မည်',
      AppLocales.setting.confirmClear: 'ရှင်းမည်',
      AppLocales.setting.clearHistoryTitle: 'မှတ်တမ်းရှင်းမည်',
      AppLocales.setting.clearHistoryConfirmMsg:
          'ဤစကားဝိုင်းရှိ မက်ဆေ့ဂျ်များ အားလုံး အပြီးဖျက်ပါမည်။',
      AppLocales.setting.deleteRoomTitle: 'အခန်းဖျက်မည်',
      AppLocales.setting.deleteRoomConfirmMsg:
          'ဤအခန်းနှင့် မက်ဆေ့ဂျ်များ အားလုံး အပြီးဖျက်ပါမည်။',
      AppLocales.setting.cancelSubTitle: 'စာရင်းသွင်းမှု ပယ်ဖျက်မည်',
      AppLocales.setting.cancelSubConfirmMsg:
          'ကာလကုန်သည်အထိ စာရင်းသွင်းမှု ဆက်လက်သုံးနိုင်ပါမည်။',

      // AI
      AppLocales.ai.title: 'AI လက်ထောက်',
      AppLocales.ai.rooms: 'စကားပြောခန်းများ',
      AppLocales.ai.newChat: 'စကားဝိုင်းသစ်',
      AppLocales.ai.defaultGreeting:
          'မင်္ဂလာပါ! ကျွန်တော်သည် AI လက်ထောက် ဖြစ်ပါသည်။ ဘာများ ကူညီပေးရမလဲ?',
      AppLocales.ai.messagesCount: 'မက်ဆေ့ဂျ် @count စောင်',
      AppLocales.ai.listen: 'နားထောင်မည်',
      AppLocales.ai.thinking: 'AI စဉ်းစားနေသည်',
      AppLocales.ai.cancelListening: 'နားထောင်ခြင်း ရပ်မည်',
      AppLocales.ai.typeMessage: 'မက်ဆေ့ဂျ် ရေးပါ...',
      AppLocales.ai.send: 'ပို့မည်',
      AppLocales.ai.composerHint: 'AtomicOS ကို စာရေးပါ…',
      AppLocales.ai.retry: 'ထပ်စမ်းမည်',
      AppLocales.ai.searchAtomsHint: 'သင့် အက်တမ်များထဲ ရှာပါ…',
      AppLocales.ai.attachSheetTitle: 'သင့်မက်ဆေ့ဂျ်နှင့် တွဲပါ',
      AppLocales.ai.sourceAtomSub: 'သင့် အက်တမ်တစ်ခုအကြောင်း မေးပါ',
      AppLocales.ai.usingAsContext: '"@name" ကို context အဖြစ် သုံးမည်',
      AppLocales.ai.selected: 'ရွေးထားသည်',
      AppLocales.ai.processing: 'AI စဉ်းစားနေဆဲ...',
      AppLocales.ai.clearHistory: 'မှတ်တမ်းရှင်းမည်',
      AppLocales.ai.micPermissionTitle: 'မိုက်ခရိုဖုန်း ခွင့်ပြုချက် လိုအပ်သည်',
      AppLocales.ai.micPermissionMessage:
          'အသံဖြင့် ရိုက်ထည့်ရန် မိုက်ခရိုဖုန်း ခွင့်ပြုချက် လိုအပ်ပါသည်။ Settings မှ ဖွင့်ပေးပါ။',
      AppLocales.ai.openSettings: 'Settings ဖွင့်မည်',
      AppLocales.ai.askSourcePhoto: 'ဓာတ်ပုံ',
      AppLocales.ai.askSourceFiles: 'ဖိုင်များ',
      AppLocales.ai.askSourceAtom: 'အက်တမ် ထည့်မည်',
      AppLocales.ai.aiSendMessageFailed: 'မက်ဆေ့ဂျ် ပို့၍မရပါ',
      AppLocales.ai.aiResponseFailed: 'AI အဖြေ မရပါ',
      AppLocales.ai.aiHistoryCleared: 'မှတ်တမ်း ရှင်းပြီးပါပြီ',
      AppLocales.ai.aiClearHistoryFailed: 'မှတ်တမ်း ရှင်း၍မရပါ',
      AppLocales.ai.aiStartRecordingFailed: 'အသံဖမ်း၍ မရပါ',
      AppLocales.ai.aiTranscriptionFailed: 'အသံကို စာသားပြောင်း၍ မရပါ',
      AppLocales.ai.aiTtsFailed: 'အသံဖွင့်၍ မရပါ',
      AppLocales.ai.aiTtsEmpty: 'ဖွင့်ရန် စာသားမရှိပါ',
      AppLocales.ai.keyPoints: 'အဓိကအချက်များ',
      AppLocales.ai.actionItems: 'ဆောင်ရွက်ရန်အချက်များ',
      AppLocales.ai.risks: 'အန္တရာယ်များ',

      // Feedback
      AppLocales.feedback.title: 'အကြံပြုချက်',
      AppLocales.feedback.description:
          'AtomicOS ပိုမိုကောင်းမွန်စေရန် သင့်အကြံပြုချက်ကို ကြိုဆိုပါသည်။',
      AppLocales.feedback.rateExperience: 'အဆင့်သတ်မှတ်ပါ (၁ - ၁၀)',
      AppLocales.feedback.tellUsMore: 'သင့်အကြံပြုချက် ရေးပါ',
      AppLocales.feedback.placeholder:
          'ချို့ယွင်းချက်၊ အကြံပြုချက် သို့မဟုတ် စိတ်ကူးသစ်များ ရေးသားနိုင်ပါသည်။',
      AppLocales.feedback.submit: 'အကြံပြုချက် ပို့မည်',
      AppLocales.feedback.submitting: 'ပို့နေဆဲ...',
      AppLocales.feedback.successMessage: 'အကြံပြုချက်အတွက် ကျေးဇူးတင်ပါသည်!',

      // Payment
      AppLocales.payment.title: 'ငွေပေးချေမှုနှင့် စာရင်းသွင်းမှု',
      AppLocales.payment.subscriptions: 'စာရင်းသွင်းမှုများ',
      AppLocales.payment.transactions: 'ငွေလွှဲမှတ်တမ်း',
      AppLocales.payment.upgradePlan: 'အဆင့်မြှင့်မည်',
      AppLocales.payment.active: 'အသုံးပြုဆဲ',
      AppLocales.payment.canceled: 'ပယ်ဖျက်ပြီး',
      AppLocales.payment.cancelSubscription: 'စာရင်းသွင်းမှု ပယ်ဖျက်မည်',
      AppLocales.payment.resumeSubscription: 'စာရင်းသွင်းမှု ပြန်စမည်',
      AppLocales.payment.subscribeNow: 'ယခု စာရင်းသွင်းမည်',
      AppLocales.payment.successTitle: 'ငွေပေးချေမှု အောင်မြင်သည်!',
      AppLocales.payment.successDesc:
          'ငွေပေးချေမှု ပြီးမြောက်ပြီး ဝန်ဆောင်မှု စတင်သုံးနိုင်ပါပြီ။',
      AppLocales.payment.cancelTitle: 'ငွေပေးချေမှု ပယ်ဖျက်ပြီး',
      AppLocales.payment.cancelDesc:
          'ငွေပေးချေမှု ပယ်ဖျက်လိုက်ပြီး မည်သည့်ငွေမှ မဖြတ်တောက်ပါ။',

      // User
      AppLocales.user.profile: 'ပရိုဖိုင်',
      AppLocales.user.changeAvatar: 'ပုံပြောင်းမည်',
      AppLocales.user.avatarHint: 'ပရိုဖိုင်ပုံ အသစ်တင်ပါ (PNG, JPG, WebP)',
      AppLocales.user.selectImage: 'ပုံရွေးပါ',
      AppLocales.user.uploadAvatar: 'ပုံတင်မည်',
      AppLocales.user.takePhoto: 'ကင်မရာ',
      AppLocales.user.chooseFromGallery: 'ပြခန်းမှ ရွေးရန်',
      AppLocales.user.cameraPermissionTitle: 'ကင်မရာ ခွင့်ပြုချက် လိုအပ်သည်',
      AppLocales.user.cameraPermissionMessage:
          'ပရိုဖိုင်ပုံ ရိုက်ရန် ကင်မရာ ခွင့်ပြုချက် လိုအပ်သည်။ Settings တွင် ဤအက်ပ်အတွက် ဖွင့်ပါ။',
      AppLocales.user.photosPermissionTitle:
          'ဓာတ်ပုံပြခန်း ခွင့်ပြုချက် လိုအပ်သည်',
      AppLocales.user.photosPermissionMessage:
          'ပရိုဖိုင်ပုံ ရွေးရန် ဓာတ်ပုံပြခန်း ခွင့်ပြုချက် လိုအပ်သည်။ Settings တွင် ဤအက်ပ်အတွက် ဖွင့်ပါ။',
      AppLocales.user.uploadAvatarFailed: 'ပရိုဖိုင်ပုံ တင်၍ မရပါ',
      AppLocales.user.updateSuccess: 'ပရိုဖိုင် သိမ်းပြီးပါပြီ',
      AppLocales.user.updateFailed: 'ပရိုဖိုင် ပြင်၍ မရပါ',
      AppLocales.user.accountInfo: 'အကောင့် အချက်အလက်',
      AppLocales.user.roles: 'ရာထူးများ',
      AppLocales.user.permissions: 'ခွင့်ပြုချက်များ',

      // Notification
      AppLocales.notification.title: 'အသိပေးချက်များ',
      AppLocales.notification.all: 'အားလုံး',
      AppLocales.notification.unread: 'မဖတ်ရသေးသော',
      AppLocales.notification.read: 'ဖတ်ပြီးသော',
      AppLocales.notification.markAllAsRead: 'အားလုံးဖတ်ပြီးမှတ်သားရန်',
      AppLocales.notification.markAsRead: 'ဖတ်ပြီးမှတ်သားရန်',
      AppLocales.notification.empty: 'အသိပေးချက် မရှိသေးပါ',
      AppLocales.notification.loadMore: 'ထပ်မံကြည့်ရှုရန်',
      AppLocales.notification.deleted: 'အသိပေးချက် ဖျက်ပြီးပါပြီ',
      AppLocales.notification.failedToLoad: 'အသိပေးချက်များ ရယူ၍မရပါ',
      AppLocales.notification.viewAll: 'အားလုံးကြည့်ရန်',
      AppLocales.notification.today: 'ယနေ့',
      AppLocales.notification.yesterday: 'မနေ့က',

      // Update
      AppLocales.update.title: 'အက်ပ်ကို အပ်ဒိတ်လုပ်မလား?',
      AppLocales.update.message: 'အက်ပ်ဗားရှင်း အသစ် ရရှိပါသည်။',
      AppLocales.update.prompt: 'ယခု အပ်ဒိတ်လုပ်လိုပါသလား?',
      AppLocales.update.update: 'ယခု အပ်ဒိတ်',
      AppLocales.update.later: 'နောက်မှ',

      // Atom
      AppLocales.atom.title: 'အက်တမ်',
      AppLocales.atom.summary: 'အနှစ်ချုပ်',
      AppLocales.atom.transcript: 'စာသားမှတ်တမ်း',
      AppLocales.atom.note: 'မှတ်စု',
      AppLocales.atom.assets: 'ဖိုင်များ',
      AppLocales.atom.noSummary: 'အနှစ်ချုပ် မရှိသေးပါ',
      AppLocales.atom.noTranscript: 'စာသားမှတ်တမ်း မရှိသေးပါ',
      AppLocales.atom.noNote: 'မှတ်စု မရှိပါ',
      AppLocales.atom.noAssets: 'ဖိုင် မရှိပါ',
      AppLocales.atom.loadFailed: 'ဤအက်တမ်ကို ရယူ၍မရပါ',
      AppLocales.atom.retry: 'ထပ်စမ်းမည်',
      AppLocales.atom.copiedToClipboard: 'ကလစ်ဘုတ်သို့ ကူးယူပြီးပါပြီ',
      AppLocales.atom.copy: 'ကူးယူမည်',

      // Calendar
      AppLocales.calendar.title: 'ပြက္ခဒိန်',
      AppLocales.calendar.scheduleLoadFailed: 'အချိန်ဇယား ရယူ၍မရပါ',
      AppLocales.calendar.noEvents: 'ရွေးထားသော အချိန်တွင် အစီအစဉ် မရှိပါ',
      AppLocales.calendar.scheduled: 'စီစဉ်ထားသည်',

      // Permission
      AppLocales.permission.title: 'ခွင့်ပြုချက်များ',
      AppLocales.permission.subtitle:
          'အစည်းအဝေး မှတ်တမ်းတင်ရန်၊ မီဒီယာ ရိုက်ကူးရန်နှင့် ဖိုင်ချိတ်ရန် ခွင့်ပြုပေးပါ။',
      AppLocales.permission.grantAll: 'အားလုံး ခွင့်ပြုမည်',
      AppLocales.permission.done: 'ပြီးပြီ',
      AppLocales.permission.notificationTitle: 'အသိပေးချက်များ ဖွင့်ပါ',
      AppLocales.permission.notificationMessage:
          'အသံဖမ်းနေစဉ် နောက်ခံတွင် ဆက်လက်လည်ပတ်နိုင်ရန်နှင့် အသိပေးချက်မှ ခေတ္တရပ်/ရပ်နိုင်ရန် အသိပေးချက်များကို ခွင့်ပြုပေးပါ။',
      AppLocales.permission.notificationEnable: 'ဖွင့်မည်',

      // Search
      AppLocales.search.placeholder: 'အက်တမ်များ သို့မဟုတ် အစည်းအဝေးများ ရှာပါ',
      AppLocales.search.emptyTitle: 'ရှာဖွေမှု မတွေ့ပါ!',
      AppLocales.search.emptyMessage:
          'သင်ရှာနေသော အက်တမ် မရှိပါ။ အခြားအက်တမ်တစ်ခုကို ရှာကြည့်ပါ။',

      // Recording
      AppLocales.recording.endTitle: 'အသံဖမ်းခြင်း ရပ်မည်လား?',
      AppLocales.recording.endMessage:
          'ဖမ်းယူမှုကို ရပ်ပြီး စကားပြောစာသားမှ အက်တမ်တစ်ခု ဖန်တီးပါမည်။ နောက်မှ ဖတ်ရှု ပြင်ဆင်နိုင်ပါသည်။',
      AppLocales.recording.endConfirm: 'ရပ်ပြီး အက်တမ် ဖန်တီးမည်',

      // AI workspace (ask + recording)
      AppLocales.ai.meetingNoteHint: 'အစည်းအဝေး မှတ်စု ရေးသားပါ...',
      AppLocales.ai.processingMeeting: 'အစည်းအဝေး လုပ်ဆောင်နေသည်',
      AppLocales.ai.processingMeetingSub:
          'ဖမ်းယူထားသော အသံမှ အနှစ်ချုပ်၊ စကားပြောစာသားနှင့် လုပ်ဆောင်ချက်များကို AtomicOS ဖန်တီးနေသည်။',
      AppLocales.ai.meetingReady: 'အစည်းအဝေး အဆင်သင့်ဖြစ်ပြီ',
      AppLocales.ai.meetingReadySub:
          'ဖန်တီးထားသော ရလဒ်များကို ကြည့်ရှုပြီး အသေးစိတ်စာမျက်နှာသို့ ဆက်သွားပါ။',
      AppLocales.ai.recordingPausedTitle: 'အသံဖမ်းခြင်း ခေတ္တရပ်ထားသည်',
      AppLocales.ai.recordingPausedSub:
          'မိုက်ခေတ္တရပ်ထားစဉ် မှတ်စုများ ရေးသားနိုင်သည်။ အစည်းအဝေး ဆက်လုပ်သည့်အခါ ပြန်စပါ။',
      AppLocales.ai.askTitle: 'AtomicOS ကို မေးမြန်းပါ',
      AppLocales.ai.askSubtitle:
          'မေးခွန်းတစ်ခုဖြင့် စတင်ပါ၊ အကြောင်းအရာ ပူးတွဲပါ၊ အဖြေကို စနစ်တကျ နောက်ဆက်တွဲ အဆင့်များအဖြစ် ပြောင်းလဲပါ။',
      AppLocales.ai.resultSummary: 'အနှစ်ချုပ်',
      AppLocales.ai.resultDecisions: 'ဆုံးဖြတ်ချက်များ',
      AppLocales.ai.resultTasks: 'လုပ်ဆောင်ချက်များ',
      AppLocales.ai.actionSummarySub:
          'အဖြေကို အတိုဆုံး အသုံးဝင်သည့်ပုံစံသို့ ချုံ့ပါ',
      AppLocales.ai.actionDecisionsSub:
          'ဆုံးဖြတ်ချက်များ၊ အတည်ပြုချက်များနှင့် ဖြေရှင်းပြီးသော မေးခွန်းများကို ထုတ်ယူပါ',
      AppLocales.ai.actionFusion: 'ပေါင်းစပ်မည်',
      AppLocales.ai.actionFusionSub:
          'အဖြေကို အခြားပရိသတ်အတွက် ဘာသာပြန်ပါ သို့မဟုတ် ပြန်လည်ဖွဲ့စည်းပါ',
      AppLocales.ai.actionTasks: 'လုပ်ဆောင်ချက်များ ဖန်တီးပါ',
      AppLocales.ai.actionTasksSub:
          'အဖြေကို တိကျသော နောက်ဆက်တွဲ အလုပ်များအဖြစ် ပြောင်းပါ',
      AppLocales.ai.actionReport: 'ခွဲခြမ်းစိတ်ဖြာ အစီရင်ခံစာ ဖန်တီးပါ',
      AppLocales.ai.actionReportSub:
          'အခန်းများပါသော ပိုရှည်သည့် ဖွဲ့စည်းထားသော အစီရင်ခံစာ ဖန်တီးပါ',
      AppLocales.ai.noTranscript: 'စကားပြောစာသား မရှိသေးပါ',
      AppLocales.ai.noTranscriptSub:
          'အကြောင်းအရာ ဖန်တီးရန် အသံဖမ်းပါ သို့မဟုတ် မေးခွန်းမေးပါ။',
      AppLocales.ai.today: 'ယနေ့',
      AppLocales.ai.source: 'အရင်းအမြစ်',
      AppLocales.ai.participants: 'ပါဝင်သူများ',
      AppLocales.ai.askAboutThisAtom: 'ဤအက်တမ်အကြောင်း မေးမည်',
      AppLocales.ai.askAboutThisAtomSub:
          'ဤမှတ်စုကို အကြောင်းအရာအဖြစ် ထည့်သွင်း၍ AI workspace ဖွင့်ပါ။',
      AppLocales.ai.noAssets: 'ဖိုင်များ မရှိသေးပါ',
      AppLocales.ai.noAssetsSub:
          'ပူးတွဲဖိုင်များနှင့် တင်သွင်းထားသော ဖိုင်များ ဤနေရာတွင် ပေါ်လာမည်။',
      AppLocales.ai.addMoreFiles: 'ဖိုင်များ ထပ်ထည့်ပါ',
      AppLocales.ai.addMoreFilesSub1:
          'တင်လိုက်သော ဖိုင်များ၏ preview များ ဤနေရာတွင် ပေါ်လာမည်။',
      AppLocales.ai.addMoreFilesSub2:
          'ဤအက်တမ်နှင့် ဆက်စပ်ထားသော စာရွက်စာတမ်းများကို ထိန်းသိမ်းထားပါ။',
      AppLocales.ai.generatingOutputs: 'ရလဒ်များ ဖန်တီးနေသည်',
      AppLocales.ai.outputsReady: 'ရလဒ်များ အဆင်သင့်ဖြစ်ပြီ',
      AppLocales.ai.actionItems: 'လုပ်ဆောင်ရမည့် အချက်များ',
      AppLocales.ai.attachAsContext: 'အကြောင်းအရာအဖြစ် ပူးတွဲမည်',
      AppLocales.ai.chooseContext: 'အကြောင်းအရာ ရွေးချယ်ပါ',
      AppLocales.ai.chooseContextSub:
          'AtomicOS အဖြေများ တိကျစေရန် သင့်အက်တမ်တစ်ခုကို ရွေးချယ်ပါ။',
      AppLocales.ai.noAtomsHere: 'ဤနေရာတွင် အက်တမ် မရှိသေးပါ',
      AppLocales.ai.noAtomsHereSub:
          'အက်တမ်တစ်ခု အရင်ဖန်တီးပြီးမှ အကြောင်းအရာအဖြစ် ပူးတွဲပါ။',
      AppLocales.ai.workWithAnswer: 'ဤအဖြေဖြင့် ဆက်လုပ်ပါ',
      AppLocales.ai.runActionHint:
          'အဖြေ preview ဖန်တီးရန် လုပ်ဆောင်ချက်တစ်ခု လုပ်ဆောင်ပါ။',
      AppLocales.ai.detailsTab: 'အသေးစိတ်',
      AppLocales.ai.overview: 'ခြုံငုံသုံးသပ်ချက်',
      AppLocales.ai.contextCards: 'အကြောင်းအရာ ကတ်များ',
      AppLocales.ai.attachments: 'ပူးတွဲဖိုင်များ',
      AppLocales.ai.processingPanelSub:
          'စကားပြောစာသား၊ အနှစ်ချုပ်နှင့် လုပ်ဆောင်ချက်များကို ပြင်ဆင်နေသည်။',
      AppLocales.ai.outputsReadySub:
          'အနှစ်ချုပ်၊ စကားပြောစာသား၊ မှတ်စုနှင့် ဖိုင် preview များကို ယခု ကြည့်ရှုနိုင်ပါပြီ။',
      AppLocales.ai.processingPreview: 'preview ပြုလုပ်နေသည်...',
      AppLocales.ai.readyOpenDetails: 'အဆင်သင့်ဖြစ်ပြီ။ အသေးစိတ် ဖွင့်ပါ။',
      AppLocales.ai.needsRetry: 'ပြန်စမ်းရန် လိုအပ်သည်',
      AppLocales.ai.thinking: 'AtomicOS စဉ်းစားနေသည်…',

      // Create / details / calendar / recording (round 3)
      AppLocales.create.stagePreview: 'အစမ်းကြည့်',
      AppLocales.create.stageChoose: 'ရွေးပါ',
      AppLocales.create.stageDraft: 'မူကြမ်း',
      AppLocales.create.draftRefineHint:
          'မူကြမ်းများကို အနှစ်ချုပ်နှင့် လုပ်ဆောင်ချက်စာရင်းများအဖြစ် အရင်ပြင်နိုင်သည်။',
      AppLocales.create.working: 'လုပ်ဆောင်နေသည်...',
      AppLocales.create.modeRecord: 'ဖမ်းယူမည်',
      AppLocales.create.addNow: 'ယခု ထည့်မည်',
      AppLocales.create.uploadAndCreate: 'တင်ပြီး ဖန်တီးမည်',
      AppLocales.create.createFromShared: 'မျှဝေစာသားမှ ဖန်တီးမည်',
      AppLocales.create.continueLabel: 'ဆက်လုပ်မည်',
      AppLocales.create.turnTasksIntoAtom:
          'လုပ်ဆောင်ချက်များကို အက်တမ်အဖြစ် ပြောင်းမည်',
      AppLocales.create.saveNote: 'မှတ်စု သိမ်းမည်',
      AppLocales.create.pickSourceHint:
          'အထက်မှ ရင်းမြစ်တစ်ခု ရွေးပြီး သင့် workspace ထဲ ထည့်ပါ။',
      AppLocales.create.sharedReviewHint:
          'မျှဝေထားသော အကြောင်းအရာများကို မသိမ်းမီ ပြန်စစ်နိုင်သည်။',
      AppLocales.create.attachedFile: 'ပူးတွဲဖိုင်',
      AppLocales.create.tapToBrowse: 'စက်ထဲမှ ရွေးရန် နှိပ်ပါ',
      AppLocales.create.readyToUploadHint:
          'တင်ရန် အသင့်ဖြစ်ပြီ · ပြောင်းရန် နှိပ်ပါ',
      AppLocales.create.pickFileHint:
          'ဖိုင်၊ ပုံ၊ ဗီဒီယို သို့မဟုတ် စာရွက်စာတမ်း ရွေးပါ',
      AppLocales.create.pasteSharedHint:
          'မျှဝေစာသားကို ဤနေရာတွင် paste လုပ်ပါ...',
      AppLocales.create.noteFieldHint: 'မှတ်စု ရေးပါ သို့မဟုတ် paste လုပ်ပါ...',
      AppLocales.atom.setMeetingDate: 'အစည်းအဝေး ရက်စွဲ သတ်မှတ်ပါ',
      AppLocales.atom.addFiles: 'ဖိုင်များ ထည့်ပါ',
      AppLocales.atom.name: 'အက်တမ် အမည်',
      AppLocales.calendar.rangeDay: 'နေ့',
      AppLocales.calendar.rangeWeek: 'အပတ်',
      AppLocales.calendar.rangeMonth: 'လ',
      AppLocales.calendar.dayMon: 'တန',
      AppLocales.calendar.dayTue: 'အင်္ဂါ',
      AppLocales.calendar.dayWed: 'ဗုဒ္ဓ',
      AppLocales.calendar.dayThu: 'ကြာ',
      AppLocales.calendar.dayFri: 'သော',
      AppLocales.calendar.daySat: 'စနေ',
      AppLocales.calendar.daySun: 'နွေ',
      AppLocales.calendar.monthSchedule: 'လအလိုက် အစီအစဉ်',
      AppLocales.calendar.scheduleFor: '@day အတွက် အစီအစဉ်',
      AppLocales.recording.noteFieldHint: 'အစည်းအဝေး မှတ်စု ရေးပါ…',
      AppLocales.recording.transcriptPlaceholder:
          'သင်ပြောနေစဉ် တိုက်ရိုက်စာသား ဤနေရာတွင် ပေါ်လာမည်…',
      AppLocales.recording.badgeLive: 'တိုက်ရိုက်',
      AppLocales.recording.badgeOff: 'ပိတ်',
      AppLocales.recording.transcriptOffline:
          'တိုက်ရိုက်စာသား အော့ဖ်လိုင်း — ပြန်ချိတ်ဆက်ပါ။',
      AppLocales.recording.transcriptMicNeeded:
          'တိုက်ရိုက်စာသားအတွက် မိုက်ခရိုဖုန်း ခွင့်ပြုချက် လိုအပ်သည်။',
      AppLocales.recording.transcriptOfflineRecording:
          'တိုက်ရိုက်စာသား အော့ဖ်လိုင်း — အသံကို ဆက်လက်ဖမ်းယူနေသည်။',
      AppLocales.recording.transcriptUnavailable:
          'တိုက်ရိုက်စာသား ယခုအချိန် မရနိုင်ပါ။',

      // Home + payment (round 4)
      AppLocales.home.greeting: 'မင်္ဂလာပါ၊ @name!',
      AppLocales.home.weekInAtoms: 'ဤအပတ်၏ အက်တမ်များ',
      AppLocales.home.recentAtoms: 'မကြာသေးမီ အက်တမ်များ',
      AppLocales.home.noAtoms: 'အက်တမ် မတွေ့ပါ',
      AppLocales.home.noAtomsFilterSub:
          'အခြား ရှာဖွေမှု သို့မဟုတ် filter စမ်းပါ။',
      AppLocales.home.noAtomsEmptySub: 'ဤ workspace အတွက် အက်တမ်အသစ် ဖန်တီးပါ။',
      AppLocales.home.newAtom: 'အက်တမ်အသစ်',
      AppLocales.home.loadFailed: 'သင့် workspace ကို မတင်နိုင်ပါ',
      AppLocales.home.loadFailedSub: 'ချိတ်ဆက်မှု စစ်ပြီး ပြန်စမ်းပါ။',
      AppLocales.home.askAtom: 'မေးမည်',
      AppLocales.home.newAtomSheetSub:
          'AtomicOS ထဲ အမြန်ဆုံး ထည့်နည်းကို ရွေးပါ။',
      AppLocales.home.devTools: 'Dev tools',
      AppLocales.home.debugContent: 'အကြောင်းအရာ',
      AppLocales.home.debugLoading: 'Load နေသည်',
      AppLocales.home.debugEmpty: 'ဗလာ',
      AppLocales.home.openCalendar: 'ပြက္ခဒိန် ဖွင့်ပါ',
      AppLocales.home.openLiveActivity: 'Live Activity ဖွင့်ပါ',
      AppLocales.home.sendTestLog: 'Test log ပို့မည်',
      AppLocales.home.testLogSent: 'Test log ပို့ပြီးပါပြီ',
      AppLocales.home.filterAll: 'အားလုံး',
      AppLocales.home.filterNew: 'အသစ်',
      AppLocales.home.filterPersonal: 'ကိုယ်ပိုင်',
      AppLocales.payment.plansPricing: 'အစီအစဉ်နှင့် စျေးနှုန်း',
      AppLocales.payment.choosePlan: 'သင့်အစီအစဉ် ရွေးပါ',
      AppLocales.payment.choosePlanSub:
          'သင့်အတွက် အကောင်းဆုံး ရွေးချယ်မှုကို ရွေးပါ',
      AppLocales.payment.noProducts: 'ယခုအချိန် ထုတ်ကုန် မရှိပါ။',
      AppLocales.payment.orderHistory: 'အမှာစာ မှတ်တမ်း',
      AppLocales.payment.claimed: 'ရယူပြီး',
      AppLocales.payment.expiring: 'သက်တမ်းကုန်ခါနီး',
      AppLocales.payment.ended: 'ပြီးဆုံး',
      AppLocales.payment.claimNow: 'ယခု ရယူမည်',
      AppLocales.payment.renewsOn: '@date တွင် အလိုအလျောက် သက်တမ်းတိုးမည်',
      AppLocales.payment.accessUntil: '@date အထိ အသုံးပြုခွင့် ရှိမည်',
      AppLocales.payment.subscribeAgain: 'ထပ်မံ စာရင်းသွင်းမည်',
      AppLocales.payment.buyAgain: 'ထပ်မံ ဝယ်မည်',
      AppLocales.payment.purchasedOnce: 'တစ်ကြိမ် ဝယ်ယူပြီး',
      AppLocales.payment.purchasedTimes: '@count ကြိမ် ဝယ်ယူပြီး',
      AppLocales.payment.buyNow: 'ယခု ဝယ်မည်',
      AppLocales.payment.paymentLabel: 'ငွေပေးချေမှု',
      AppLocales.payment.paid: 'ပေးပြီး',
      AppLocales.payment.checkout: 'ငွေရှင်းရန်',
      AppLocales.ai.sourcePhotoSub: 'ဓာတ်ပုံ ပူးတွဲပါ',
      AppLocales.ai.sourceFilesSub: 'ဖိုင် ပူးတွဲပါ',
      AppLocales.ai.attachedFile: '@name ပူးတွဲပြီးပါပြီ',
      AppLocales.ai.filePickerFailed: 'ဖိုင်ရွေးချယ်ရေး ကို ဖွင့်၍မရပါ',
      AppLocales.home.itemsCount: 'ဤ workspace တွင် @count ခု',
      AppLocales.create.title: 'အက်တမ် ဖန်တီးပါ',
      AppLocales.create.heading: 'မည်သည့်အရာမဆို AtomicOS ထဲ ယူလာပါ',
      AppLocales.create.headingSub:
          'မီဒီယာ တင်ပါ သို့မဟုတ် မျှဝေထားသော စာသားကို အက်တမ်အဖြစ် သိမ်းဆည်းပါ။',
      AppLocales.create.import: 'တင်သွင်းမည်',
      AppLocales.create.openAsk: 'Ask AtomicOS ဖွင့်ပါ',
      AppLocales.create.uploading: 'တင်နေသည်…',
      AppLocales.create.captureLive: 'တိုက်ရိုက် စကားပြောကို ဖမ်းယူပါ',
      AppLocales.create.captureLiveSub:
          'AtomicOS က အစည်းအဝေးကို ဖမ်းယူ၊ စာသားပြောင်းပြီး အက်တမ်အသစ်အဖြစ် အနှစ်ချုပ်ပေးသည်။',
      AppLocales.create.sharedPayload: 'မျှဝေထားသော အကြောင်းအရာ',
      AppLocales.create.readyToImport: 'တင်သွင်းရန် အသင့်ဖြစ်ပြီ',
      AppLocales.create.uploadFile: 'ဖိုင် တင်ပါ',
      AppLocales.create.uploadFileSub:
          'အသံ၊ ဗီဒီယို သို့မဟုတ် စာရွက်စာတမ်းများ',
      AppLocales.create.noteTitle: 'မှတ်စု',
      AppLocales.create.noteSub: 'စာသား ရေးပါ သို့မဟုတ် paste လုပ်ပါ',
      AppLocales.create.shareTitle: 'အခြား app မှ မျှဝေပါ',
      AppLocales.create.shareSub: 'system share sheet မှတစ်ဆင့်',
      AppLocales.create.sharedItem: 'မျှဝေထားသော အရာ',
      AppLocales.create.noteDraft: 'မှတ်စု မူကြမ်း',
      AppLocales.create.nextSteps: 'နောက်ဆက်တွဲ အဆင့်များ',
      AppLocales.create.generateSummary: 'အနှစ်ချုပ် ဖန်တီးပါ',
      AppLocales.create.generateSummarySub: 'အကျဉ်းချုပ် ဗားရှင်း ဖန်တီးပါ',
      AppLocales.create.extractTasks: 'လုပ်ဆောင်ချက်များ ထုတ်ယူပါ',
      AppLocales.create.extractTasksSub:
          'မှတ်စုကို နောက်လုပ်ဆောင်ချက်များအဖြစ် ပြောင်းပါ',
      AppLocales.create.chipAudio: 'အသံ',
      AppLocales.create.chipVideo: 'ဗီဒီယို',
      AppLocales.create.chipDocuments: 'စာရွက်စာတမ်းများ',
      AppLocales.create.recordNow: 'ယခု ဖမ်းယူမည်',
      AppLocales.create.recordNowSub: 'AtomicOS ဖြင့် အသံ စတင်ဖမ်းယူပါ',
      AppLocales.create.noteFromShare: 'မျှဝေမှုမှ မှတ်စု ဖန်တီးပါ',
      AppLocales.create.noteFromShareSub:
          'စာသားအကြမ်းကို စနစ်တကျ မှတ်စုအဖြစ် ပြောင်းလဲပါ',
      AppLocales.create.askAboutThis: 'ဤအကြောင်း AtomicOS ကို မေးမည်',
      AppLocales.create.askAboutThisSub:
          'အနှစ်ချုပ်၊ ဆုံးဖြတ်ချက်နှင့် လုပ်ဆောင်ချက်များ ဖန်တီးပါ',
      AppLocales.create.attachExisting: 'လက်ရှိ အက်တမ်နှင့် ချိတ်ဆက်ပါ',
      AppLocales.create.attachExistingSub:
          'ယခင် အစည်းအဝေး workspace နှင့် ပေါင်းစပ်ပါ',
      AppLocales.create.destination: 'ဦးတည်ရာ',
      AppLocales.create.destinationSub: 'မျှဝေစာသားမှ အက်တမ်အသစ်',
      AppLocales.create.backendRoute: 'Backend လမ်းကြောင်း',
      AppLocales.create.backendRouteSub:
          'Creates via POST /v1/atoms/from-share',
      AppLocales.atom.inPlanner: 'Planner တွင် ရှိသည်',
      AppLocales.atom.addFilesHint: 'သင့်မှတ်စုများအတွက် ဖိုင်များ ထည့်ပါ။',
      AppLocales.atom.nothingHere: 'ဤနေရာတွင် ဘာမှ မရှိသေးပါ',
      AppLocales.atom.pullToRetry: 'ပြန်လည်စမ်းသပ်ရန် အောက်သို့ ဆွဲပါ။',
      AppLocales.calendar.pageHeader: 'ပြက္ခဒိန်',
      AppLocales.calendar.headerSub:
          'လာမည့် အစည်းအဝေးများကို ကြည့်ရှုပြီး live workspace သို့ တိုက်ရိုက်ဝင်ပါ။',
      AppLocales.calendar.metricVisible: 'မြင်နေရ',
      AppLocales.calendar.metricRange: 'အပိုင်းအခြား',
      AppLocales.calendar.metricDay: 'နေ့',
      AppLocales.calendar.openLiveView: 'တိုက်ရိုက်ကြည့်ရန် ဖွင့်ပါ',
      AppLocales.recording.liveMeeting: 'တိုက်ရိုက် အစည်းအဝေး',
      AppLocales.recording.end: 'ရပ်မည်',
    },
  };
}
