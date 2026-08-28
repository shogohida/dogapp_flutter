// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dog Health';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDogs => 'Dogs';

  @override
  String get tabHealthCheck => 'Health Check';

  @override
  String get tabRecords => 'Records';

  @override
  String get tabWalk => 'Walk';

  @override
  String get loadErrorTitle => 'Couldn\'t connect to dogapp-api';

  @override
  String get retry => 'Retry';

  @override
  String get noDogsRegistered => 'No dogs registered';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String healthRecordsSummary(int count) {
    return 'Keeping track of $count dogs\' health, every day.';
  }

  @override
  String get upcoming => 'Upcoming';

  @override
  String dogInfoLine(String color, int age) {
    return '$color · ${age}y';
  }

  @override
  String get dogsTitle => 'Dogs';

  @override
  String get weightHistory => 'Weight History';

  @override
  String get currentWeight => 'Weight';

  @override
  String get recordsTitle => 'Records';

  @override
  String get shareProfile => 'Share profile';

  @override
  String shareFailed(String error) {
    return 'Failed to share: $error';
  }

  @override
  String breedColorLine(String breed, String color) {
    return '$breed · $color';
  }

  @override
  String get healthCheckTitle => 'Health Check';

  @override
  String get healthCheckDescription =>
      'Take a photo of the skin or coat for a quick check on any changes. This isn\'t a diagnosis — just a guide for whether to see a vet.';

  @override
  String get takeOrChoosePhoto => 'Take or choose a photo';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get analyzing => 'Analyzing…';

  @override
  String get analysisFailed => 'Analysis failed';

  @override
  String get tryAgain => 'Try again';

  @override
  String get checkAgain => 'Check again';

  @override
  String get aiCheckDisclaimer =>
      '※ This is a simple AI-based check, not a diagnosis. Please see a vet for any concerning symptoms.';

  @override
  String healthCheckRecordLabel(String title) {
    return 'Health check: $title';
  }

  @override
  String gaitCheckRecordLabel(String title) {
    return 'Gait check: $title';
  }

  @override
  String get healthCheckModePhoto => 'Photo';

  @override
  String get healthCheckModeVideo => 'Video (gait)';

  @override
  String get gaitCheckDescription =>
      'Get a quick check on your dog\'s gait from a short video. This isn\'t a diagnosis — just a guide for whether to see a vet.';

  @override
  String get takeOrChooseVideo => 'Take or choose a video';

  @override
  String get tapToUploadVideo => 'Tap to upload a video';

  @override
  String get recordVideo => 'Record a video';

  @override
  String get chooseVideoFromGallery => 'Choose video from gallery';

  @override
  String get addRecord => 'Add Record';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get costOptional => 'Cost (optional)';

  @override
  String get invalidCost => 'Enter a cost of 0 or more';

  @override
  String totalCost(String amount) {
    return 'Total cost: $amount';
  }

  @override
  String get save => 'Save';

  @override
  String saveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get recordTypeVaccine => 'Vaccine';

  @override
  String get recordTypeGrooming => 'Grooming';

  @override
  String get recordTypeVet => 'Vet Visit';

  @override
  String get recordTypeMedication => 'Medication';

  @override
  String get walkTitle => 'Walk';

  @override
  String get startWalk => 'Start Walk';

  @override
  String get stopWalk => 'Stop Walk';

  @override
  String get recording => 'Recording…';

  @override
  String get distance => 'Distance';

  @override
  String get duration => 'Duration';

  @override
  String get pace => 'Pace';

  @override
  String get walkHistory => 'Walk History';

  @override
  String get recommendedCourses => 'Recommended Courses';

  @override
  String get noWalksYet => 'No walks recorded yet';

  @override
  String get noRecommendationsYet =>
      'Record a few walks and we\'ll recommend your favorite routes';

  @override
  String walkedNTimes(int count) {
    return 'Walked $count times';
  }

  @override
  String get locationPermissionDenied => 'Location permission was denied';

  @override
  String get locationServiceDisabled => 'Location services are disabled';

  @override
  String saveWalkFailed(String error) {
    return 'Failed to save the walk: $error';
  }

  @override
  String loadWalksFailed(String error) {
    return 'Failed to load walks: $error';
  }

  @override
  String get discardWalk => 'Discard';

  @override
  String get discardWalkConfirm => 'Discard this walk\'s recording?';

  @override
  String get cancel => 'Cancel';

  @override
  String get km => 'km';

  @override
  String get minutesShort => 'min';
}
