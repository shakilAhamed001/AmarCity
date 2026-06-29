// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'আমার শহর';

  @override
  String get smartMunicipalityPlatform => 'স্মার্ট পৌরসভা প্ল্যাটফর্ম';

  @override
  String get welcomeBack => 'স্বাগতম';

  @override
  String get signInToDashboard => 'আপনার নাগরিক ড্যাশবোর্ডে লগইন করুন';

  @override
  String get emailAddress => 'ইমেইল ঠিকানা';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get emailHint => 'rahim@example.com';

  @override
  String get passwordHint => 'আপনার পাসওয়ার্ড দিন';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get signIn => 'নিরাপদে লগইন করুন';

  @override
  String get orContinueWith => 'অথবা চালিয়ে যান';

  @override
  String get newToAmarCity => 'নতুন ব্যবহারকারী? ';

  @override
  String get createAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get pleaseEnterAllFields => 'সব তথ্য পূরণ করুন';

  @override
  String get invalidCredentials => 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';

  @override
  String get verifyEmail => 'প্রথমে আপনার ইমেইল যাচাই করুন। ইনবক্স চেক করুন।';

  @override
  String get goodMorning => 'শুভ সকাল,';

  @override
  String get totalReports => 'মোট\nঅভিযোগ';

  @override
  String get inProgress => 'চলমান';

  @override
  String get resolved => 'সমাধান';

  @override
  String get escalated => 'এস্কালেটেড';

  @override
  String get quickActions => 'দ্রুত কাজ';

  @override
  String get reportIssue => 'অভিযোগ দিন';

  @override
  String get submitNewComplaint => 'নতুন অভিযোগ জমা দিন';

  @override
  String get myComplaints => 'আমার অভিযোগ';

  @override
  String get viewAndTrackAll => 'সব দেখুন ও ট্র্যাক করুন';

  @override
  String get liveTracking => 'লাইভ ট্র্যাকিং';

  @override
  String get checkComplaintMap => 'অভিযোগের মানচিত্র দেখুন';

  @override
  String get cityStats => 'শহরের পরিসংখ্যান';

  @override
  String get publicAnalytics => 'পাবলিক বিশ্লেষণ';

  @override
  String get recentComplaints => 'সাম্প্রতিক অভিযোগ';

  @override
  String get seeAll => 'সব দেখুন >';

  @override
  String get noComplaintsYet => 'এখনো কোনো অভিযোগ নেই।';

  @override
  String noFilteredComplaints(String status) {
    return 'কোনো $status অভিযোগ নেই।';
  }

  @override
  String get home => 'হোম';

  @override
  String get report => 'রিপোর্ট';

  @override
  String get notifications => 'বিজ্ঞপ্তি';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get unassigned => 'নির্ধারিত নয়';

  @override
  String get officer => 'অফিসার';

  @override
  String get complaints => 'অভিযোগ';

  @override
  String totalComplaints(int count) {
    return 'মোট $countটি অভিযোগ';
  }

  @override
  String get searchComplaint => 'অভিযোগ বা স্থান খুঁজুন...';

  @override
  String get all => 'সব';

  @override
  String get statusNew => 'নতুন';

  @override
  String get assignOfficer => 'অফিসার নির্ধারণ';

  @override
  String get assign => 'নির্ধারণ করুন';

  @override
  String get reassign => 'পুনরায় নির্ধারণ >';

  @override
  String get assignBtn => 'নির্ধারণ >';

  @override
  String get cancel => 'বাতিল';

  @override
  String get selectOfficer => 'অফিসার বাছুন';

  @override
  String noOfficersFound(String dept) {
    return '\"$dept\" এর জন্য কোনো অফিসার পাওয়া যায়নি';
  }

  @override
  String get officerAssigned => 'অফিসার নির্ধারিত ও বিজ্ঞপ্তি পাঠানো হয়েছে!';

  @override
  String get autoEscalated =>
      'স্বয়ংক্রিয় এস্কালেশন: ৪৮+ ঘণ্টায় কোনো আপডেট নেই';

  @override
  String get overview => 'সংক্ষিপ্ত';

  @override
  String get users => 'ব্যবহারকারী';

  @override
  String get reports => 'রিপোর্ট';

  @override
  String get alerts => 'সতর্কতা';

  @override
  String get language => 'ভাষা';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';
}
