import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PaperFlow'**
  String get appTitle;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @importDocument.
  ///
  /// In en, this message translates to:
  /// **'Import Document'**
  String get importDocument;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocuments;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'Import a PDF, EPUB, or other document to get started'**
  String get importHint;

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get reader;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @tableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get tableOfContents;

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionary;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @vocabularyList.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary List'**
  String get vocabularyList;

  /// No description provided for @exportVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Export Vocabulary'**
  String get exportVocabulary;

  /// No description provided for @addToVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Add to Vocabulary'**
  String get addToVocabulary;

  /// No description provided for @word.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get word;

  /// No description provided for @definition.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get definition;

  /// No description provided for @cnDefinition.
  ///
  /// In en, this message translates to:
  /// **'Chinese Definition'**
  String get cnDefinition;

  /// No description provided for @pronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get pronunciation;

  /// No description provided for @partOfSpeech.
  ///
  /// In en, this message translates to:
  /// **'Part of Speech'**
  String get partOfSpeech;

  /// No description provided for @context.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get context;

  /// No description provided for @noVocabulary.
  ///
  /// In en, this message translates to:
  /// **'No vocabulary collected yet'**
  String get noVocabulary;

  /// No description provided for @activeRecall.
  ///
  /// In en, this message translates to:
  /// **'Active Recall'**
  String get activeRecall;

  /// No description provided for @startReview.
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get startReview;

  /// No description provided for @nextParagraph.
  ///
  /// In en, this message translates to:
  /// **'Next Paragraph'**
  String get nextParagraph;

  /// No description provided for @finishReview.
  ///
  /// In en, this message translates to:
  /// **'Finish Review'**
  String get finishReview;

  /// No description provided for @describeThisParagraph.
  ///
  /// In en, this message translates to:
  /// **'Describe what this paragraph means'**
  String get describeThisParagraph;

  /// No description provided for @whatDidTheAuthorMean.
  ///
  /// In en, this message translates to:
  /// **'What did the author express here?'**
  String get whatDidTheAuthorMean;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @aiReview.
  ///
  /// In en, this message translates to:
  /// **'AI Review'**
  String get aiReview;

  /// No description provided for @overallUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Overall Understanding'**
  String get overallUnderstanding;

  /// No description provided for @sectionScores.
  ///
  /// In en, this message translates to:
  /// **'Section Scores'**
  String get sectionScores;

  /// No description provided for @misunderstoodParagraphs.
  ///
  /// In en, this message translates to:
  /// **'Misunderstood Paragraphs'**
  String get misunderstoodParagraphs;

  /// No description provided for @vocabularyImpact.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Impact'**
  String get vocabularyImpact;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @jumpToParagraph.
  ///
  /// In en, this message translates to:
  /// **'Jump to Paragraph'**
  String get jumpToParagraph;

  /// No description provided for @readingMastery.
  ///
  /// In en, this message translates to:
  /// **'Reading Mastery'**
  String get readingMastery;

  /// No description provided for @masteryTrend.
  ///
  /// In en, this message translates to:
  /// **'Mastery Trend'**
  String get masteryTrend;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @last90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last90Days;

  /// No description provided for @contextMastery.
  ///
  /// In en, this message translates to:
  /// **'Context Mastery'**
  String get contextMastery;

  /// No description provided for @globalMastery.
  ///
  /// In en, this message translates to:
  /// **'Global Mastery'**
  String get globalMastery;

  /// No description provided for @wordsCollected.
  ///
  /// In en, this message translates to:
  /// **'Words Collected'**
  String get wordsCollected;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @readingWidth.
  ///
  /// In en, this message translates to:
  /// **'Reading Width'**
  String get readingWidth;

  /// No description provided for @lineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get lineHeight;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get aiModel;

  /// No description provided for @apiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API Base URL'**
  String get apiBaseUrl;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @youUnderstoodWell.
  ///
  /// In en, this message translates to:
  /// **'You Understood Well'**
  String get youUnderstoodWell;

  /// No description provided for @needReview.
  ///
  /// In en, this message translates to:
  /// **'Need Review'**
  String get needReview;

  /// No description provided for @overallSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Overall Suggestions'**
  String get overallSuggestions;

  /// No description provided for @affectedUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Affected Understanding'**
  String get affectedUnderstanding;

  /// No description provided for @recommendReread.
  ///
  /// In en, this message translates to:
  /// **'Recommend re-reading related paragraphs'**
  String get recommendReread;

  /// No description provided for @newWordsThisSession.
  ///
  /// In en, this message translates to:
  /// **'New words this session'**
  String get newWordsThisSession;

  /// No description provided for @mastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get mastered;

  /// No description provided for @notMastered.
  ///
  /// In en, this message translates to:
  /// **'Not Mastered'**
  String get notMastered;

  /// No description provided for @noRecallSessions.
  ///
  /// In en, this message translates to:
  /// **'No recall sessions yet'**
  String get noRecallSessions;

  /// No description provided for @startReadingToSeeProgress.
  ///
  /// In en, this message translates to:
  /// **'Start reading to see your progress'**
  String get startReadingToSeeProgress;

  /// No description provided for @masteryHistory.
  ///
  /// In en, this message translates to:
  /// **'Mastery History'**
  String get masteryHistory;

  /// No description provided for @noMasteryData.
  ///
  /// In en, this message translates to:
  /// **'No mastery data yet'**
  String get noMasteryData;

  /// No description provided for @completeRecallToSeeScores.
  ///
  /// In en, this message translates to:
  /// **'Complete a recall session to see your scores'**
  String get completeRecallToSeeScores;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
