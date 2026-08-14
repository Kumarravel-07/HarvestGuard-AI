import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  static const _preferenceKey = 'app_language';
  String _language = 'English';

  String get language => _language;
  bool get isTamil => _language == 'Tamil';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _language = preferences.getString(_preferenceKey) == 'Tamil'
        ? 'Tamil'
        : 'English';
  }

  Future<void> setLanguage(String value) async {
    final language = value == 'Tamil' ? 'Tamil' : 'English';
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, language);
  }
}

class AppLocalizations extends InheritedNotifier<AppLanguageController> {
  const AppLocalizations({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizations>();
    assert(scope != null, 'AppLocalizations is missing above this widget.');
    return scope!.notifier!;
  }

  static String text(BuildContext context, String key) =>
      _strings[controllerOf(context).isTamil ? 'Tamil' : 'English']![key] ??
      _strings['English']![key] ??
      key;

  static String content(BuildContext context, String value) {
    if (!controllerOf(context).isTamil) return value;
    final key = value.trim();
    if (key.isEmpty) return value;
    return _tamilContent[key] ??
        _tamilContent[key.toLowerCase()] ??
        _tamilContent[_normalizeDynamicValue(key)] ??
        value;
  }

  static String risk(BuildContext context, String value) {
    final normalized = value.trim();
    if (!controllerOf(context).isTamil) return normalized;
    return switch (normalized.toLowerCase()) {
      'low' => 'குறைவு',
      'medium' => 'நடுத்தரம்',
      'high' => 'அதிகம்',
      'குறைவு' => 'குறைவு',
      'நடுத்தரம்' => 'நடுத்தரம்',
      'அதிகம்' => 'அதிகம்',
      _ => normalized,
    };
  }

  static String condition(BuildContext context, String value) {
    final normalized = value.trim();
    if (!controllerOf(context).isTamil) return normalized;
    return switch (normalized.toLowerCase()) {
      'damaged' => 'கெட்டுப்போனது',
      'old' => 'பழையது',
      'ripe' => 'பழுத்தது',
      'unripe' => 'பழுக்காதது',
      'கெட்டுப்போனது' => 'கெட்டுப்போனது',
      'பழையது' => 'பழையது',
      'பழுத்தது' => 'பழுத்தது',
      'பழுக்காதது' => 'பழுக்காதது',
      _ => normalized,
    };
  }

  static String _normalizeDynamicValue(String value) {
    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'low') return 'LOW';
    if (lower == 'medium') return 'MEDIUM';
    if (lower == 'high') return 'HIGH';
    if (lower == 'damaged') return 'Damaged';
    if (lower == 'old') return 'Old';
    if (lower == 'ripe') return 'Ripe';
    if (lower == 'unripe') return 'Unripe';
    return trimmed;
  }
}

String tr(BuildContext context, String key) =>
    AppLocalizations.text(context, key);

String trContent(BuildContext context, String value) =>
    AppLocalizations.content(context, value);

String riskLabel(BuildContext context, String value) =>
    AppLocalizations.risk(context, value);

String conditionLabel(BuildContext context, String value) =>
    AppLocalizations.condition(context, value);

const _strings = <String, Map<String, String>>{
  'English': {
    'home': 'Home',
    'predict': 'Predict',
    'history': 'History',
    'profile': 'Profile',
    'editProfile': 'Edit Profile',
    'totalPredictions': 'Total Predictions',
    'about': 'About HarvestGuard AI',
    'privacy': 'Privacy Policy',
    'help': 'Help & Support',
    'logout': 'Logout',
    'language': 'Language',
    'name': 'Name',
    'email': 'Email',
    'mobileNumber': 'Mobile Number',
    'accountCreated': 'Account Created',
    'notAvailable': 'Not available',
    'save': 'Save',
    'cancel': 'Cancel',
    'prediction': 'Prediction',
    'tomato': 'Tomato',
    'storageDetails': 'Storage Details',
    'captureBatch': 'Capture Tomato Batch',
    'captureBatchDescription':
        'Take one overall photo of the tomato batch and 2-3 close-up photos from different parts of the batch.',
    'overallBatchPhoto': 'One Overall Batch Photo',
    'batchPhotoDescription': 'crate, basket, gunny bag, carton or heap',
    'closeUpPhotos': '2-3 Close-up Tomato Photos',
    'closeUpDescription': 'different tomatoes from different positions',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'packaging': 'Packaging',
    'transport': 'Transport',
    'location': 'Location',
    'weather': 'Weather',
    'temperature': 'Temperature',
    'humidity': 'Humidity',
    'storageType': 'Storage Type',
    'packagingType': 'Packaging Type',
    'transportMode': 'Transport Mode',
    'predictShelfLife': 'Predict Shelf Life',
    'predictionResult': 'Prediction Result',
    'estimatedShelfLife': 'Estimated Shelf Life',
    'spoilageRisk': 'Spoilage Risk',
    'recommendedAction': 'Recommended Action',
    'conditionSummary': 'Condition Summary',
    'overallCondition': 'Overall Condition',
    'batchAnalysis': 'Batch Analysis',
    'conditionDistribution': 'Condition Distribution',
    'damaged': 'Damaged',
    'old': 'Old',
    'ripe': 'Ripe',
    'unripe': 'Unripe',
    'dateTime': 'Date and Time',
    'setReminder': 'Set Reminder',
    'cancelReminder': 'Cancel Reminder',
    'confidence': 'Confidence',
    'back': 'Back',
    'loading': 'Loading...',
    'checkTransport': 'Check Transport Recommendation',
    'transportRecommendation': 'Transportation Recommendation',
    'transportDistance': 'Transport Distance (km)',
    'transportType': 'Transport Type',
    'travelDuration': 'Travel Duration (hours)',
    'quantity': 'Quantity (kg)',
    'getRecommendation': 'Get Recommendation',
    'transportRisk': 'Transportation Risk',
    'recommendedActions': 'Recommended Actions',
    'why': 'Why?',
    'backToResult': 'Back to Result',
    'historyTitle': 'Prediction History',
    'clearHistory': 'Clear History',
    'noPredictions':
        'No predictions yet. Your completed predictions will appear here.',
    'viewAll': 'View All',
    'latestPredictions': 'Latest Predictions',
    'yourSummary': 'Your Summary',
    'startPrediction': 'Start New Prediction',
    'contactSupport': 'Contact Support',
    'aboutText':
        'AI-powered post-harvest tomato loss prediction and management system.',
    'low': 'LOW',
    'medium': 'MEDIUM',
    'high': 'HIGH',
    'ruleBasedGuide':
        'This is a simple rule-based guide using your transport details.',
    'currentTemperature': 'Current temperature',
    'temperatureUnavailable':
        'Temperature unavailable. It will not be used in this guide.',
    'attentionRequired': 'Attention Required',
    'reminderSet': 'Reminder set',
    'reminderTomorrow': 'Reminder: Tomorrow',
    'reminderInDays': 'Reminder: In {days} days',
    'selectRequiredFields': '{fields} are required.',
    'signInToViewDashboard': 'Please sign in to view your dashboard.',
    'signInToViewHistory': 'Please sign in to see your prediction history.',
    'weatherUnavailable':
        'Weather is unavailable. Check location and internet access.',
    'couldNotLoadHistory': 'Could not load prediction history.',
    'noPredictionsStart': 'No predictions yet. Start your first prediction!',
    'editProfileTitle': 'Edit Profile',
    'pleaseEnterName': 'Please enter your name.',
    'unableUpdateProfile': 'Unable to update profile. Please try again.',
    'forSupport':
        'For support, please contact the HarvestGuard AI project team.',
    'useCurrentLocation': 'Use current location',
    'addPhotosMessage':
        'Add 1 batch photo and at least 2 close-up photos to continue.',
    'selectDetailsMessage':
        'Select Storage Type, Packaging Type and Transport Mode to continue.',
    'readyToPredict': 'Ready to predict.',
    'pleaseSelectRequiredPredictionDetails':
        'Please select Storage Type, Packaging Type and Transport Mode before predicting.',
    'weatherUnavailableForLocation': 'Weather unavailable for this location',
    'aiPredictionFailed': 'AI prediction failed: {error}',
    'backToLanguageSelection': 'Back to language selection',
    'loginTitle': 'LOGIN',
    'createAccount': 'Create Account',
    'signupTitle': 'SIGN UP',
    'alreadyHaveAccount': 'Already have an account?',
    'signIn': 'SIGN IN',
    'fullName': 'Full Name',
    'emailAddress': 'Email address',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'showPassword': 'Show password',
    'hidePassword': 'Hide password',
    'pleaseEnterValidEmail': 'Please enter a valid email address.',
    'pleaseEnterPassword': 'Please enter your password.',
    'loginSuccessful': 'Login successful.',
    'unableSignIn': 'Unable to sign in. Please try again.',
    'pleaseSignInToViewProfile': 'Please sign in to view your profile.',
    'profileNameUnavailable': 'Name not available',
    'emailUnavailable': 'Email not available',
    'updateProfileSubtitle': 'Update your name, mobile number and language',
    'learnHowAppHelps': 'Learn how the app helps farmers save produce',
    'readPrivacyPractice': 'Read our data and privacy practices',
    'getAppHelp': 'Get help using the app',
    'notificationPermissionNotGranted':
        'Notification permission was not granted.',
    'reminderSetForBatch': 'Reminder set for this batch.',
    'unableSetReminder': 'Unable to set reminder. Please try again.',
    'reminderCancelledForBatch': 'Reminder cancelled for this batch.',
    'checkTomatoBatchAfter': 'Check tomato batch after',
    'daysLabel': 'days',
    'dayLabel': 'day',
    'tomatoesAppear': 'tomatoes appear',
    'tomatoAppears': 'tomato appears',
    'batchGoodCondition':
        'Batch appears to be in good condition. Continue proper storage and transportation practices.',
    'tomatoRiskWarning':
        '{count} {item} damaged or old. Remove them from the healthy batch before storage or transportation to reduce the risk of spoilage.',
    'currentTemperatureValue': 'Current temperature: {temp} °C',
    'temperatureUnavailableGuide':
        'Temperature unavailable. It will not be used in this guide.',
    'transportRiskText': 'Transportation Risk: {risk}',
    'infoUnavailable': 'Information is unavailable',
    'createYourAccount': 'Create Your Account',
    'joinHarvestGuard': 'Join HarvestGuard AI',
    'backToSignIn': 'Back to sign in',
    'pleaseEnterFullName': 'Please enter your full name.',
    'pleaseEnterValidMobile': 'Please enter a valid mobile number.',
    'passwordMinLength': 'Password must be at least 6 characters.',
    'passwordsDoNotMatch': 'Passwords do not match.',
    'accountCreatedSuccessfully':
        'Account created successfully. Please sign in.',
    'unableCreateAccount': 'Unable to create your account. Please try again.',
    'emailAlreadyInUse': 'An account already exists with this email.',
    'weakPassword': 'Please choose a stronger password.',
    'emailOrPasswordIncorrect': 'Email or password is incorrect.',
    'welcomeToHarvestGuard': 'Welcome to HarvestGuard AI',
    'clearHistoryDialogTitle': 'Clear History?',
    'clearHistoryDialogMessage':
        'This will permanently remove all saved prediction history.',
    'unableClearHistory': 'Unable to clear prediction history.',
    'unableLoadHistory': 'Unable to load history. Please try again later.',
    'historyDeleteTooltip': 'Clear History',
    'unknownUserName': 'Farmer',
    'welcomeGreeting': 'Welcome, {name} 👋',
    'refreshWeather': 'Refresh weather',
    'totalSummary': 'Total',
    'safeSummary': 'Safe',
    'highRiskSummary': 'High Risk',
    'retake': 'Retake',
    'remove': 'Remove',
    'closeUpPhotoCountMessage': 'You have added 3 close-up photos.',
    'currentLocation': 'Use current location',
    'galleryPhoto': 'Gallery',
    'cameraPhoto': 'Camera',
    'passwordTooltipShow': 'Show password',
    'passwordTooltipHide': 'Hide password',
    'weatherUnavailableShort':
        'Weather unavailable. Check location and internet access.',
  },
  'Tamil': {
    'home': '\u0bae\u0bc1\u0b95\u0baa\u0bcd\u0baa\u0bc1',
    'predict': '\u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1',
    'history': '\u0bb5\u0bb0\u0bb2\u0bbe\u0bb1\u0bc1',
    'profile': '\u0b9a\u0bc1\u0baf\u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd',
    'editProfile':
        '\u0b9a\u0bc1\u0baf\u0bb5\u0bbf\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc8 \u0ba4\u0bbf\u0bb0\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1',
    'totalPredictions':
        '\u0bae\u0bca\u0ba4\u0bcd\u0ba4 \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
    'about': 'HarvestGuard AI \u0baa\u0bb1\u0bcd\u0bb1\u0bbf',
    'privacy':
        '\u0ba4\u0ba9\u0bbf\u0baf\u0bc1\u0bb0\u0bbf\u0bae\u0bc8 \u0b95\u0bca\u0bb3\u0bcd\u0b95\u0bc8',
    'help':
        '\u0b89\u0ba4\u0bb5\u0bbf \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd',
    'logout': '\u0bb5\u0bc6\u0bb3\u0bbf\u0baf\u0bc7\u0bb1\u0bc1',
    'language': '\u0bae\u0bca\u0bb4\u0bbf',
    'name': '\u0baa\u0bc6\u0baf\u0bb0\u0bcd',
    'email': '\u0bae\u0bbf\u0ba9\u0bcd\u0ba9\u0b9e\u0bcd\u0b9a\u0bb2\u0bcd',
    'mobileNumber': '\u0bae\u0bca\u0baa\u0bc8\u0bb2\u0bcd \u0b8e\u0ba3\u0bcd',
    'accountCreated':
        '\u0b95\u0ba3\u0b95\u0bcd\u0b95\u0bc1 \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f\u0ba4\u0bc1',
    'notAvailable':
        '\u0b95\u0bbf\u0b9f\u0bc8\u0b95\u0bcd\u0b95\u0bb5\u0bbf\u0bb2\u0bcd\u0bb2\u0bc8',
    'save': '\u0b9a\u0bc7\u0bae\u0bbf',
    'cancel': '\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1',
    'prediction': '\u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1',
    'tomato': '\u0ba4\u0b95\u0bcd\u0b95\u0bbe\u0bb3\u0bbf',
    'captureBatch':
        '\u0ba4\u0b95\u0bcd\u0b95\u0bbe\u0bb3\u0bbf \u0ba4\u0bca\u0b95\u0bc1\u0baa\u0bcd\u0baa\u0bc8 \u0baa\u0b9f\u0bae\u0bcd \u0b8e\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
    'captureBatchDescription':
        '\u0ba4\u0b95\u0bcd\u0b95\u0bbe\u0bb3\u0bbf \u0ba4\u0bca\u0b95\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0ba9\u0bcd \u0b92\u0bb0\u0bc1 \u0bae\u0bc1\u0bb4\u0bc1\u0baa\u0bcd \u0baa\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8\u0baf\u0bc1\u0bae\u0bcd, \u0bb5\u0bc6\u0bb5\u0bcd\u0bb5\u0bc7\u0bb1\u0bc1 \u0baa\u0b95\u0bc1\u0ba4\u0bbf\u0b95\u0bb3\u0bbf\u0bb2\u0bcd \u0b87\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 2-3 \u0ba8\u0bc6\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bae\u0bbe\u0ba9 \u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bc8\u0baf\u0bc1\u0bae\u0bcd \u0b8e\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd.',
    'overallBatchPhoto':
        '\u0ba4\u0bca\u0b95\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0ba9\u0bcd \u0bae\u0bc1\u0bb4\u0bc1\u0baa\u0bcd \u0baa\u0b9f\u0bae\u0bcd',
    'batchPhotoDescription':
        '\u0b95\u0bbf\u0bb0\u0bc7\u0b9f\u0bcd, \u0b95\u0bc2\u0b9f\u0bc8, \u0b9a\u0ba3\u0bb2\u0bcd \u0bae\u0bc2\u0b9f\u0bcd\u0b9f\u0bc8, \u0b85\u0b9f\u0bcd\u0b9f\u0bc8 \u0baa\u0bc6\u0b9f\u0bcd\u0b9f\u0bbf \u0b85\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1 \u0b95\u0bc1\u0bb5\u0bbf\u0baf\u0bb2\u0bcd',
    'closeUpPhotos':
        '2-3 \u0ba8\u0bc6\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bae\u0bbe\u0ba9 \u0ba4\u0b95\u0bcd\u0b95\u0bbe\u0bb3\u0bbf \u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    'closeUpDescription':
        '\u0bb5\u0bc6\u0bb5\u0bcd\u0bb5\u0bc7\u0bb1\u0bc1 \u0b87\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bbf\u0bb2\u0bcd \u0b89\u0bb3\u0bcd\u0bb3 \u0ba4\u0b95\u0bcd\u0b95\u0bbe\u0bb3\u0bbf\u0b95\u0bb3\u0bcd',
    'camera': '\u0b95\u0bc7\u0bae\u0bb0\u0bbe',
    'gallery': '\u0b95\u0bc7\u0bb2\u0bb0\u0bbf',
    'packaging': '\u0baa\u0bca\u0ba4\u0bbf\u0baf\u0bb2\u0bcd',
    'transport': '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1',
    'storageDetails':
        '\u0b9a\u0bc7\u0bae\u0bbf\u0baa\u0bcd\u0baa\u0bc1 \u0bb5\u0bbf\u0bb5\u0bb0\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    'location': '\u0b87\u0b9f\u0bae\u0bcd',
    'weather': '\u0bb5\u0bbe\u0ba9\u0bbf\u0bb2\u0bc8',
    'temperature': '\u0bb5\u0bc6\u0baa\u0bcd\u0baa\u0ba8\u0bbf\u0bb2\u0bc8',
    'humidity': '\u0b88\u0bb0\u0baa\u0bcd\u0baa\u0ba4\u0bae\u0bcd',
    'storageType':
        '\u0b9a\u0bc7\u0bae\u0bbf\u0baa\u0bcd\u0baa\u0bc1 \u0bb5\u0b95\u0bc8',
    'packagingType':
        '\u0baa\u0bca\u0ba4\u0bbf\u0baf\u0bb2\u0bcd \u0bb5\u0b95\u0bc8',
    'transportMode':
        '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0bae\u0bc1\u0bb1\u0bc8',
    'predictShelfLife':
        '\u0b85\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bc1 \u0bb5\u0bbe\u0bb4\u0bcd\u0bb5\u0bc8 \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
    'predictionResult':
        '\u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1 \u0bae\u0bc1\u0b9f\u0bbf\u0bb5\u0bc1',
    'estimatedShelfLife':
        '\u0bae\u0ba4\u0bbf\u0baa\u0bcd\u0baa\u0bbf\u0b9f\u0bcd\u0b9f \u0b85\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bc1 \u0bb5\u0bbe\u0bb4\u0bcd\u0bb5\u0bc1',
    'spoilageRisk':
        '\u0b95\u0bc6\u0b9f\u0bc1\u0baa\u0bcd\u0baa\u0bc1 \u0b86\u0baa\u0ba4\u0bcd\u0ba4\u0bc1',
    'recommendedAction':
        '\u0baa\u0bb0\u0bbf\u0ba8\u0bcd\u0ba4\u0bc1\u0bb0\u0bc8\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd',
    'conditionSummary':
        '\u0ba8\u0bbf\u0bb2\u0bc8 \u0b9a\u0bc1\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bae\u0bcd',
    'overallCondition':
        '\u0bae\u0bca\u0ba4\u0bcd\u0ba4 \u0ba8\u0bbf\u0bb2\u0bc8',
    'confidence': '\u0ba8\u0bae\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0bc8',
    'back': '\u0baa\u0bbf\u0ba9\u0bcd',
    'batchAnalysis':
        '\u0ba4\u0bca\u0b95\u0bc1\u0baa\u0bcd\u0baa\u0bc1 \u0baa\u0b95\u0bc1\u0baa\u0bcd\u0baa\u0be7\u0bb2\u0bcd\u0bb5\u0bc1',
    'conditionDistribution':
        '\u0ba8\u0bbf\u0bb2\u0bc8 \u0bb5\u0bbf\u0ba8\u0bbf\u0baf\u0bcb\u0b95\u0bae\u0bcd',
    'damaged':
        '\u0b9a\u0bc7\u0ba4\u0bae\u0b9f\u0bc8\u0ba8\u0bcd\u0ba4\u0ba4\u0bc1',
    'old': '\u0baa\u0bb4\u0bc8\u0baf\u0ba4\u0bc1',
    'ripe': '\u0baa\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0ba4\u0bc1',
    'unripe': '\u0baa\u0bb4\u0bc1\u0b95\u0bcd\u0b95\u0bbe\u0ba4\u0ba4\u0bc1',
    'dateTime':
        '\u0ba4\u0bc7\u0ba4\u0bbf \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0ba8\u0bc7\u0bb0\u0bae\u0bcd',
    'setReminder':
        '\u0ba8\u0bbf\u0ba9\u0bc8\u0bb5\u0bc2\u0b9f\u0bcd\u0b9f\u0bb2\u0bc8 \u0b85\u0bae\u0bc8\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
    'cancelReminder':
        '\u0ba8\u0bbf\u0ba9\u0bc8\u0bb5\u0bc2\u0b9f\u0bcd\u0b9f\u0bb2\u0bc8 \u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb5\u0bc1\u0bae\u0bcd',
    'loading':
        '\u0b8f\u0bb1\u0bcd\u0b95\u0bc7\u0bb1\u0bcd\u0bb1\u0b95\u0bbf\u0bb1\u0ba4\u0bc1...',
    'checkTransport':
        '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0baa\u0bb0\u0bbf\u0ba8\u0bcd\u0ba4\u0bc1\u0bb0\u0bc8\u0baf\u0bc8 \u0baa\u0bbe\u0bb0\u0bcd\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
    'ruleBasedGuide':
        '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0bb5\u0bbf\u0bb5\u0bb0\u0b99\u0bcd\u0b95\u0bb3\u0bc8 \u0baa\u0baf\u0ba9\u0bcd\u0baa\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0bae\u0bcd \u0b8e\u0bb3\u0bbf\u0baf \u0bb5\u0bbf\u0ba4\u0bbf \u0b85\u0b9f\u0bbf\u0baa\u0bcd\u0baa\u0b9f\u0bc8\u0baf\u0bbf\u0bb2\u0bbe\u0ba9 \u0bb5\u0bb4\u0bbf\u0b95\u0bbe\u0b9f\u0bcd\u0b9f\u0bbf.',
    'currentTemperature':
        '\u0ba4\u0bb1\u0baa\u0bcd\u0baa\u0bcb\u0ba4\u0bc8\u0baf \u0bb5\u0bc6\u0baa\u0bcd\u0baa\u0ba8\u0bbf\u0bb2\u0bc8',
    'temperatureUnavailable':
        '\u0bb5\u0bc6\u0baa\u0bcd\u0baa\u0ba8\u0bbf\u0bb2\u0bc8 \u0b95\u0bbf\u0b9f\u0bc8\u0b95\u0bcd\u0b95\u0bb5\u0bbf\u0bb2\u0bcd\u0bb2\u0bc8. \u0b87\u0ba8\u0bcd\u0ba4 \u0bb5\u0bb4\u0bbf\u0b95\u0bbe\u0b9f\u0bcd\u0b9f\u0bbf\u0bb2\u0bcd \u0b85\u0ba4\u0bc1 \u0baa\u0baf\u0ba9\u0bcd\u0baa\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0baa\u0bcd\u0baa\u0b9f\u0bbe\u0ba4\u0bc1.',
    'transportRecommendation':
        '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0baa\u0bb0\u0bbf\u0ba8\u0bcd\u0ba4\u0bc1\u0bb0\u0bc8',
    'transportDistance':
        '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0ba4\u0bca\u0bb2\u0bc8\u0bb5\u0bc1 (km)',
    'transportType':
        '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0bb5\u0b95\u0bc8',
    'travelDuration':
        '\u0baa\u0baf\u0ba3 \u0ba8\u0bc7\u0bb0\u0bae\u0bcd (\u0bae\u0ba3\u0bbf)',
    'quantity': '\u0b85\u0bb3\u0bb5\u0bc1 (kg)',
    'getRecommendation':
        '\u0baa\u0bb0\u0bbf\u0ba8\u0bcd\u0ba4\u0bc1\u0bb0\u0bc8\u0baf\u0bc8\u0baa\u0bcd \u0baa\u0bc6\u0bb1\u0bc1',
    'transportRisk':
        '\u0baa\u0bcb\u0b95\u0bc1\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1 \u0b86\u0baa\u0ba4\u0bcd\u0ba4\u0bc1',
    'recommendedActions':
        '\u0baa\u0bb0\u0bbf\u0ba8\u0bcd\u0ba4\u0bc1\u0bb0\u0bc8\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f \u0ba8\u0b9f\u0bb5\u0b9f\u0bbf\u0b95\u0bcd\u0b95\u0bc8\u0b95\u0bb3\u0bcd',
    'why': '\u0b8f\u0ba9\u0bcd?',
    'backToResult':
        '\u0bae\u0bc1\u0b9f\u0bbf\u0bb5\u0bc1\u0b95\u0bcd\u0b95\u0bc1 \u0ba4\u0bbf\u0bb0\u0bc1\u0bae\u0bcd\u0baa\u0bcd\u0b9a\u0bc6\u0bb2\u0bcd',
    'historyTitle':
        '\u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1 \u0bb5\u0bb0\u0bb2\u0bbe\u0bb1\u0bc1',
    'clearHistory': '\u0bb5\u0bb0\u0bb2\u0bbe\u0bb1\u0bc8 \u0b85\u0bb4\u0bbf',
    'noPredictions':
        '\u0b87\u0ba9\u0bcd\u0ba9\u0bc1\u0bae\u0bcd \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd \u0b87\u0bb2\u0bcd\u0bb2\u0bc8. \u0bae\u0bc1\u0b9f\u0bbf\u0ba8\u0bcd\u0ba4 \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd \u0b87\u0b99\u0bcd\u0b95\u0bc7 \u0ba4\u0bca\u0ba9\u0bcd\u0bb1\u0bc1\u0bae\u0bcd.',
    'viewAll':
        '\u0b85\u0ba9\u0bc8\u0ba4\u0bcd\u0ba4\u0bc8\u0baf\u0bc1\u0bae\u0bcd \u0baa\u0bbe\u0bb0\u0bcd',
    'latestPredictions':
        '\u0b9a\u0bae\u0bc0\u0baa\u0ba4\u0bcd\u0ba4\u0bbf\u0baf \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
    'yourSummary':
        '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bbf\u0ba9\u0bcd \u0b9a\u0bc1\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bae\u0bcd',
    'startPrediction':
        '\u0baa\u0bc1\u0ba4\u0bbf\u0baf \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bc8 \u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95\u0bc1',
    'contactSupport':
        '\u0b86\u0ba4\u0bb0\u0bb5\u0bc1 \u0ba4\u0bca\u0b9f\u0bb0\u0bcd\u0baa\u0bc1',
    'aboutText':
        'AI \u0b86\u0ba4\u0bb0\u0bb5\u0bc1\u0b9f\u0ba9\u0bcd \u0b85\u0bb1\u0bc1\u0bb5\u0b9f\u0bc8\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0bbf\u0bb1\u0b95\u0bc1 \u0ba4\u0b95\u0bcd\u0b95\u0bbe\u0bb3\u0bbf \u0b87\u0bb4\u0baa\u0bcd\u0baa\u0bc8 \u0b95\u0ba3\u0bbf\u0baa\u0bcd\u0baa\u0bbf\u0b9f\u0bc1\u0bae\u0bcd \u0bae\u0bc7\u0bb2\u0bbe\u0ba3\u0bcd\u0bae\u0bc8 \u0b85\u0bae\u0bc8\u0baa\u0bcd\u0baa\u0bc1.',
    'low': '\u0b95\u0bc1\u0bb1\u0bc8\u0bb5\u0bc1',
    'medium': '\u0ba8\u0b9f\u0bc1\u0ba8\u0bbf\u0bb2\u0bc8',
    'high': '\u0b85\u0ba4\u0bbf\u0b95\u0bae\u0bcd',
  },
};

const _tamilContent = <String, String>{
  'AI-powered post-harvest tomato loss prediction and management system.':
      'AI உதவியுடன் அறுவடைக்குப் பிந்தைய தக்காளி இழப்பை கணித்து நிர்வகிக்கும் அமைப்பு.',
  'How it helps': 'இது எவ்வாறு உதவுகிறது',
  'HarvestGuard AI helps farmers assess tomato condition, predict post-harvest spoilage risk, estimate shelf life, and receive storage and transport recommendations.':
      'HarvestGuard AI விவசாயிகள் தக்காளியின் நிலையை அறியவும், கெடுதல் அபாயம் மற்றும் அடுக்கு வாழ்நாளை கணிக்கவும், சேமிப்பு மற்றும் போக்குவரத்து பரிந்துரைகளைப் பெறவும் உதவுகிறது.',
  'Our goal is to help farmers reduce tomato wastage and improve post-harvest handling.':
      'தக்காளி வீணாவதை குறைத்து அறுவடைக்குப் பிந்தைய கையாளுதலை மேம்படுத்துவது எங்கள் நோக்கம்.',
  'Information We Collect': 'நாங்கள் சேகரிக்கும் தகவல்',
  'How We Use Information': 'தகவலை எவ்வாறு பயன்படுத்துகிறோம்',
  'Prediction Data': 'கணிப்பு தரவு',
  'Account Information': 'கணக்கு தகவல்',
  'Data Security': 'தரவு பாதுகாப்பு',
  'Data Sharing': 'தரவு பகிர்வு',
  'User Control': 'பயனர் கட்டுப்பாடு',
  'How to make a prediction': 'கணிப்பை செய்வது எப்படி',
  'View prediction history': 'கணிப்பு வரலாற்றைப் பார்ப்பது',
  'Edit profile information': 'சுயவிவரத் தகவலை திருத்துவது',
  'If image prediction does not work': 'படக் கணிப்பு செயல்படவில்லை என்றால்',
  'If weather or location is unavailable':
      'வானிலை அல்லது இடம் கிடைக்கவில்லை என்றால்',
  'The app uses the account details you provide, selected tomato images, and location or weather information when you use those features.':
      'நீங்கள் வழங்கும் கணக்கு விவரங்கள், தேர்ந்தெடுத்த தக்காளி படங்கள் மற்றும் நீங்கள் பயன்படுத்தும் இடம் அல்லது வானிலை தகவல்களை செயலி பயன்படுத்துகிறது.',
  'Information is used to provide tomato batch analysis, weather details, prediction history, and account features.':
      'தக்காளி தொகுதி பகுப்பாய்வு, வானிலை விவரங்கள், கணிப்பு வரலாறு மற்றும் கணக்கு வசதிகளுக்காக தகவல் பயன்படுத்தப்படுகிறது.',
  'Completed prediction results are saved in your account history so you can review them later.':
      'முடிக்கப்பட்ட கணிப்பு முடிவுகள் பின்னர் பார்க்க உங்கள் கணக்கு வரலாற்றில் சேமிக்கப்படும்.',
  'Your name, email, mobile number, and language are used to display and manage your profile.':
      'உங்கள் சுயவிவரத்தை காட்டவும் நிர்வகிக்கவும் உங்கள் பெயர், மின்னஞ்சல், மொபைல் எண் மற்றும் மொழி பயன்படுத்தப்படுகின்றன.',
  'We use the app services needed to provide your account and prediction history. This student project does not claim advanced security features beyond those services.':
      'உங்கள் கணக்கு மற்றும் கணிப்பு வரலாற்றிற்கு தேவையான செயலி சேவைகளை நாங்கள் பயன்படுத்துகிறோம். இந்த மாணவர் திட்டம் கூடுதல் மேம்பட்ட பாதுகாப்பை உரிமை கோரவில்லை.',
  'HarvestGuard AI does not send your prediction results to other farmers or use them for notification delivery.':
      'HarvestGuard AI உங்கள் கணிப்பு முடிவுகளை மற்ற விவசாயிகளுக்கு அனுப்பாது அல்லது அறிவிப்பு அனுப்ப பயன்படுத்தாது.',
  'You can edit your profile information, review your prediction history, and clear saved history from the app.':
      'நீங்கள் சுயவிவரத் தகவலை திருத்தலாம், கணிப்பு வரலாற்றைப் பார்க்கலாம் மற்றும் சேமித்த வரலாற்றை செயலியில் நீக்கலாம்.',
  'Open Predict, add one overall batch photo and at least two close-up tomato photos, then tap Predict Shelf Life.':
      'கணிப்பு பக்கத்தைத் திறந்து ஒரு முழு தொகுதி படத்தையும் குறைந்தது இரண்டு நெருக்கமான தக்காளி படங்களையும் சேர்த்து, அடுக்கு வாழ்நாளை கணிக்க என்பதைத் தட்டவும்.',
  'Open the History tab to review your completed batch predictions and their details.':
      'உங்கள் முடிக்கப்பட்ட தொகுதி கணிப்புகள் மற்றும் விவரங்களை பார்க்க வரலாறு தாவலைத் திறக்கவும்.',
  'Open Profile and tap Edit Profile to update your name, mobile number, or language.':
      'பெயர், மொபைல் எண் அல்லது மொழியை மாற்ற சுயவிவரத்தைத் திறந்து சுயவிவரத்தைத் திருத்து என்பதைத் தட்டவும்.',
  'Check that the photos are clear, show tomatoes properly, and include the required overall and close-up images. Then try again.':
      'படங்கள் தெளிவாகவும் தக்காளிகள் சரியாகவும் உள்ளதா, தேவையான முழு மற்றும் நெருக்கமான படங்கள் உள்ளதா என்பதைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  'Check your internet connection and location permission. You can also enter a location manually on the Prediction page.':
      'இணைய இணைப்பு மற்றும் இருப்பிட அனுமதியைச் சரிபார்க்கவும். கணிப்பு பக்கத்தில் இடத்தை கைமுறையாகவும் உள்ளிடலாம்.',
};
