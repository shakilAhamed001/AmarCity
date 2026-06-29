// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AmarCity';

  @override
  String get smartMunicipalityPlatform => 'SMART MUNICIPALITY PLATFORM';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToDashboard => 'Sign in to your civic dashboard';

  @override
  String get emailAddress => 'EMAIL ADDRESS';

  @override
  String get password => 'PASSWORD';

  @override
  String get emailHint => 'rahim@example.com';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign in securely';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get newToAmarCity => 'New to AmarCity? ';

  @override
  String get createAccount => 'Create account';

  @override
  String get pleaseEnterAllFields => 'Please fill all fields';

  @override
  String get invalidCredentials => 'Invalid email or password.';

  @override
  String get verifyEmail => 'Please verify your email first. Check your inbox.';

  @override
  String get goodMorning => 'Good morning,';

  @override
  String get totalReports => 'Total\nReports';

  @override
  String get inProgress => 'In\nProgress';

  @override
  String get resolved => 'Resolved';

  @override
  String get escalated => 'Escalated';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get reportIssue => 'Report issue';

  @override
  String get submitNewComplaint => 'Submit new complaint';

  @override
  String get myComplaints => 'My complaints';

  @override
  String get viewAndTrackAll => 'View & track all';

  @override
  String get liveTracking => 'Live tracking';

  @override
  String get checkComplaintMap => 'Check complaint map';

  @override
  String get cityStats => 'City stats';

  @override
  String get publicAnalytics => 'Public analytics';

  @override
  String get recentComplaints => 'Recent complaints';

  @override
  String get seeAll => 'See all >';

  @override
  String get noComplaintsYet => 'No complaints yet.';

  @override
  String noFilteredComplaints(String status) {
    return 'No $status complaints.';
  }

  @override
  String get home => 'Home';

  @override
  String get report => 'Report';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get officer => 'Officer';

  @override
  String get complaints => 'Complaints';

  @override
  String totalComplaints(int count) {
    return '$count total complaints';
  }

  @override
  String get searchComplaint => 'Search complaint or location...';

  @override
  String get all => 'All';

  @override
  String get statusNew => 'New';

  @override
  String get assignOfficer => 'Assign Officer';

  @override
  String get assign => 'Assign';

  @override
  String get reassign => 'Reassign >';

  @override
  String get assignBtn => 'Assign >';

  @override
  String get cancel => 'Cancel';

  @override
  String get selectOfficer => 'Select Officer';

  @override
  String noOfficersFound(String dept) {
    return 'No officers found for \"$dept\"';
  }

  @override
  String get officerAssigned => 'Officer assigned & notified!';

  @override
  String get autoEscalated => 'Auto-Escalated: No update for 48+ hours';

  @override
  String get overview => 'Overview';

  @override
  String get users => 'Users';

  @override
  String get reports => 'Reports';

  @override
  String get alerts => 'Alerts';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';
}
