import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';

class _HelpEntry {
  final IconData icon;
  final String label;
  final String detail;
  const _HelpEntry(this.icon, this.label, this.detail);
}

class _HelpSection {
  final String title;
  final String context;
  final List<_HelpEntry> entries;
  const _HelpSection(this.title, this.context, this.entries);
}

class _HelpContent {
  final String title;
  final String intro;
  final List<_HelpSection> sections;
  final String disclaimer;
  const _HelpContent(this.title, this.intro, this.sections, this.disclaimer);
}

class ScreenHelpButton extends StatelessWidget {
  final String topic;
  const ScreenHelpButton({super.key, required this.topic});

  static const _content = <String, _HelpContent>{
    'Settings': _HelpContent(
        'Settings',
        'Manage account security and local app preferences. Changes to your password and sessions are verified by the backend.',
        [
          _HelpSection('Account security',
              'These controls require your authenticated account.', [
            _HelpEntry(Icons.medical_information_outlined, 'Health conditions',
                'Patients can record clinician-diagnosed diabetes, heart disease, or another chronic condition. These entries are patient reported and can be changed later.'),
            _HelpEntry(Icons.lock_outline_rounded, 'Change password',
                'Enter your current password. Other active sessions are signed out when the change succeeds.'),
            _HelpEntry(Icons.devices_rounded, 'Active sessions',
                'Review current and other sessions; revoke a session you no longer recognise.'),
          ]),
          _HelpSection(
              'On this device',
              'Display and risk-alert choices are saved locally on this device.',
              [
                _HelpEntry(Icons.dark_mode_outlined, 'Dark mode',
                    'Switch between light and dark palettes without changing your data or navigation.'),
                _HelpEntry(Icons.text_fields_rounded, 'Text size',
                    'Choose a comfortable size for app text.'),
                _HelpEntry(Icons.motion_photos_off_rounded, 'Reduce motion',
                    'Reduce supported in-app animations.'),
                _HelpEntry(Icons.notifications_outlined, 'Risk alerts',
                    'Patient dashboard badges can be shown or hidden; this does not change stored results.'),
              ]),
          _HelpSection('Legal and privacy',
              'Open the information panel before sharing health details or acting on a report.', [
            _HelpEntry(Icons.gavel_rounded, 'Legal & Privacy',
                'Explains saved health information, clinician access, account security, demonstration payments, and the limits of risk estimates.'),
          ]),
        ],
        'RiskSense AI settings do not replace medical advice. Device preferences do not change backend access or clinical records.'),
    'Registration': _HelpContent(
        'Create your patient account',
        'Enter your own account details, then use the six-digit code sent to your email. Your patient account is created only after the code is verified. Next, activate access and complete the six-step introduction and health form before the dashboard opens.',
        [
          _HelpSection(
              'Identity',
              'Use accurate details so your account and health information remain linked to you.',
              [
                _HelpEntry(Icons.person_outline_rounded, 'Full name',
                    'Enter your first and last name.'),
                _HelpEntry(Icons.mail_outline_rounded, 'Email address',
                    'Use an address you can access. It becomes your sign-in name.'),
                _HelpEntry(Icons.cake_outlined, 'Date of birth',
                    'Used to calculate your age. Choose your actual date of birth.'),
                _HelpEntry(Icons.badge_outlined, 'Gender',
                    'Choose the option that applies to you. Some analyses require a recorded sex value.'),
              ]),
          _HelpSection('Account security',
              'Choose a password you have not reused elsewhere.', [
            _HelpEntry(Icons.lock_outline_rounded, 'Password',
                'At least 6 characters, with a capital letter, a number, and a special character.'),
            _HelpEntry(Icons.verified_user_outlined, 'Confirm password',
                'Enter exactly the same password again.'),
            _HelpEntry(Icons.check_box_outlined, 'Consent',
                'Read and accept the health-data notice before creating the account.'),
          ]),
        ],
        'RiskSense AI provides decision support, not a diagnosis. Registration does not verify a subscription or insurance benefit.'),
    'Onboarding Health Profile': _HelpContent(
      'Complete your health profile',
      'This final onboarding step records baseline details used across RiskSense. Enter only information you know and can verify; you can update eligible health measurements later.',
      [
        _HelpSection('Body measurements', 'Use your current measurements. BMI is calculated automatically from height and weight.', [
          _HelpEntry(Icons.height_rounded, 'Height', 'Enter centimetres (cm), between 100 and 250.'),
          _HelpEntry(Icons.monitor_weight_rounded, 'Weight', 'Enter kilograms (kg), between 25 and 350.'),
          _HelpEntry(Icons.straighten_rounded, 'Waist circumference', 'Optional; record centimetres (cm) if measured.'),
        ]),
        _HelpSection('Lifestyle and family history', 'Select the option that describes you. Unknown family history can remain unknown.', [
          _HelpEntry(Icons.smoke_free_rounded, 'Smoking', 'Never, Former, or Current.'),
          _HelpEntry(Icons.directions_run_rounded, 'Activity', 'Sedentary, Light, Moderate, or Active.'),
          _HelpEntry(Icons.local_bar_rounded, 'Alcohol', 'None, Occasional, Regular, or Prefer not to say.'),
          _HelpEntry(Icons.family_restroom_rounded, 'Family history', 'Record known diabetes, heart disease, and high blood pressure history separately.'),
        ]),
        _HelpSection('Health context', 'Only add conditions and medication that apply to you.', [
          _HelpEntry(Icons.public_rounded, 'Ethnicity', 'Optional account information; if already recorded it cannot be changed here.'),
          _HelpEntry(Icons.medical_information_outlined, 'Chronic condition', 'Enable the checkbox to describe a chronic condition.'),
          _HelpEntry(Icons.medication_outlined, 'Chronic medication', 'Optional when a chronic condition is selected; include the name and dose if known.'),
        ]),
      ],
      'RiskSense AI provides decision support, not a diagnosis. Do not guess clinical information or change treatment based on this form.',
    ),
    'Health Data Input': _HelpContent(
      'Health data input',
      'Review account demographics, record measurements you know, and choose the model to run. Closed sections can be opened as needed. Your entries remain in place when you return from an analysis.',
      [
        _HelpSection('Demographics',
            'These values come from registration. They are read-only here.', [
          _HelpEntry(Icons.cake_rounded, 'Age',
              'Calculated automatically from date of birth on the day you run an analysis.'),
          _HelpEntry(Icons.badge_rounded, 'Sex',
              'The recorded registration value used by the current model: female or male. Contact support if your record needs correction.'),
          _HelpEntry(Icons.public_rounded, 'Ethnicity',
              'Recorded account information. It is shown for your review and is not an input to the current diabetes or heart model.'),
        ]),
        _HelpSection(
            'Lifestyle',
            'Choose a recorded value or leave it as Not recorded. These fields enrich your health profile but are not direct inputs to the current model versions.',
            [
              _HelpEntry(Icons.smoke_free_rounded, 'Smoking status',
                  'Not recorded, Never, Former, or Current.'),
              _HelpEntry(Icons.fitness_center_rounded, 'Activity level',
                  'Not recorded, Sedentary, Light, Moderate, or Active.'),
              _HelpEntry(Icons.local_bar_rounded, 'Alcohol use',
                  'Not recorded, None, Occasional, or Regular.'),
            ]),
        _HelpSection(
            'Body measurements',
            'Enter measured values with the units shown. BMI is calculated from height and weight; do not enter an invented BMI.',
            [
              _HelpEntry(Icons.height_rounded, 'Height',
                  'Centimetres (cm); used with weight to calculate BMI for diabetes analysis.'),
              _HelpEntry(Icons.monitor_weight_rounded, 'Weight',
                  'Kilograms (kg); used with height to calculate BMI.'),
              _HelpEntry(Icons.straighten_rounded, 'Waist circumference',
                  'Centimetres (cm); required by the current diabetes model.'),
            ]),
        _HelpSection(
            'Vitals',
            'Record current readings. Systolic and diastolic pressure should come from the same blood-pressure measurement.',
            [
              _HelpEntry(Icons.favorite_rounded, 'Systolic blood pressure',
                  'Upper pressure reading in mmHg; used by both disease models.'),
              _HelpEntry(
                  Icons.favorite_border_rounded,
                  'Diastolic blood pressure',
                  'Lower pressure reading in mmHg; used by the diabetes model.'),
              _HelpEntry(Icons.monitor_heart_rounded, 'Heart rate',
                  'Beats per minute (bpm); stored as a vital, not a current model input.'),
              _HelpEntry(Icons.air_rounded, 'Oxygen saturation',
                  'Percentage (%); stored as a vital, not a current model input.'),
              _HelpEntry(Icons.thermostat_rounded, 'Temperature',
                  'Degrees Celsius (°C); stored as a vital, not a current model input.'),
            ]),
        _HelpSection(
            'Laboratory results',
            'Use actual measured laboratory values. If a required result is missing, the backend will request it rather than invent a value.',
            [
              _HelpEntry(Icons.water_drop_rounded, 'Fasting glucose',
                  'mg/dL; the current heart model uses whether this reading exceeds its validated threshold.'),
              _HelpEntry(Icons.biotech_rounded, 'Total cholesterol',
                  'mg/dL; required by the current heart model.'),
            ]),
        _HelpSection(
            'Choose analysis', 'The button runs only the selected model.', [
          _HelpEntry(Icons.bloodtype_rounded, 'Diabetes',
              'Uses age, sex, BMI, waist circumference, and systolic/diastolic blood pressure.'),
          _HelpEntry(Icons.favorite_rounded, 'Heart disease',
              'Uses age, sex, systolic blood pressure, total cholesterol, and a fasting-glucose category.'),
          _HelpEntry(Icons.monitor_heart_outlined, 'Already diagnosed?',
              'If you reported a diagnosis of the selected condition, a badge and switch offer a seven-day health trends report. You can still choose to run the risk model.'),
        ]),
      ],
      'Enter only real measurements. The result is a model estimate, not a diagnosis. Do not change treatment based on this screen alone.',
    ),
    'Prediction Result': _HelpContent(
      'Risk analysis result',
      'This screen presents the selected model’s score, its threshold classification, and feature contributions calculated from that same model run.',
      [
        _HelpSection(
            'Analysis types',
            'The two models use different input sets and training data; their scores should not be treated as interchangeable.',
            [
              _HelpEntry(Icons.bloodtype_rounded, 'Diabetes',
                  'Age, sex, BMI, waist circumference, systolic pressure, and diastolic pressure.'),
              _HelpEntry(Icons.favorite_rounded, 'Heart disease',
                  'Age, sex, systolic pressure, total cholesterol, and fasting-glucose category.'),
            ]),
        _HelpSection(
            'Reading your result',
            'The displayed factors correspond to the model that produced the score.',
            [
              _HelpEntry(Icons.donut_large_rounded, 'Score and classification',
                  'The percentage is the model output. Elevated or below-threshold uses that model’s validated decision threshold.'),
              _HelpEntry(
                  Icons.bar_chart_rounded,
                  'Primary contributing factors',
                  'Bars show each input’s share of the absolute model log-odds contributions. Raises and lowers describe direction relative to the model training baseline.'),
              _HelpEntry(Icons.psychology_outlined, 'Interpretation',
                  'Names the strongest score-raising and score-lowering inputs from the same calculation. A large bar is not proof of cause or a treatment target.'),
              _HelpEntry(Icons.history_rounded, 'Prediction history',
                  'Your saved result can be revisited through Prediction History.'),
              _HelpEntry(Icons.picture_as_pdf_outlined, 'PDF report',
                  'Open the PDF for this analysis here or from its saved prediction. The preview offers sharing and saving.'),
            ]),
      ],
      'This is decision support, not a diagnosis or a prediction of certainty. Review concerning results and any treatment decisions with a qualified clinician.',
    ),
    'Nutrition': _HelpContent(
      'Nutrition',
      'Track food, water, blood glucose and insulin doses you have taken. Generate Meal Plan opens separate, flexible guidance based on your latest risk analyses.',
      [
        _HelpSection('Food log',
            'Add one food or ingredient at a time to the appropriate meal.', [
          _HelpEntry(Icons.search_rounded, 'Search foods',
              'Find products in Open Food Facts or search foods you have logged before. Your search terms and selected product barcode are sent to Open Food Facts. You can instead enter a new food using values from its label per 100 g.'),
          _HelpEntry(Icons.scale_rounded, 'Amount eaten',
              'Enter the amount in grams. The app scales the per-100 g values to that amount.'),
          _HelpEntry(Icons.track_changes_rounded, 'Calorie goal',
              'Set your own daily target. The bullseye marks it on the calorie scale.'),
        ]),
        _HelpSection('Trends', 'Totals use only your saved food entries.', [
          _HelpEntry(Icons.bar_chart_rounded, 'Macro balance',
              'The colored bar shows the share of logged energy from carbs, fat, and protein. The displayed ranges are general adult references, not a personal prescription.'),
          _HelpEntry(Icons.show_chart_rounded, 'Seven day intake',
              'Bars show logged calories for each of the last seven days, including today. A zero can mean no foods were logged.'),
          _HelpEntry(Icons.water_drop_outlined, 'Water',
              'Tap +250 ml to log a drink. The daily total, individual entries with times, and seven-day chart use your saved water entries. Set a personal goal with the bullseye; the scale spans 0 to 4,000 ml.'),
        ]),
        _HelpSection(
            'Blood Glucose',
            'Patient-entered meter readings and insulin doses are tracked separately from verified laboratory results.',
            [
              _HelpEntry(Icons.bloodtype_outlined, 'Reading types',
                  'Select Fasting, Post-meal or General and enter the measured blood glucose in mg/dL. The app does not infer a reading type.'),
              _HelpEntry(Icons.vaccines_rounded, 'Insulin doses',
                  'Log an insulin dose already taken in units (U). This is not a blood insulin test and does not provide dosing advice.'),
              _HelpEntry(Icons.show_chart_rounded, 'Seven-day trends',
                  'Glucose charts show the latest reading of each type per day. The insulin chart shows the sum of logged doses for that day. A gap means no entry.'),
            ]),
      ],
      'Open Food Facts is community contributed; check product labels. Glucose and insulin logging does not diagnose a condition or change treatment. Seek professional advice for concerning readings or dose questions.',
    ),
    'Mindfulness': _HelpContent(
      'Mindfulness',
      'Use Mood to record how you feel, Breathing for timed guided exercises, and Meditation to play soundscapes and review your session history.',
      [
        _HelpSection('Mood', 'Entries belong to your patient account.', [
          _HelpEntry(Icons.mood_rounded, 'Current mood',
              'The animated icon and text show your most recent entry today. Earlier entries appear with their times.'),
          _HelpEntry(Icons.add_reaction_outlined, 'Log Mood',
              'Choose Amazing, Good, Fine, Bad or Horrible, then select a suggested emotion and reason or type your own.'),
          _HelpEntry(Icons.bar_chart_rounded, 'Seven-day graph',
              'Each day’s icon represents the average of moods you logged that day. A gap means no mood was recorded.'),
        ]),
        _HelpSection('Breathing and Meditation',
            'Choose a comfortable pace and stop a session whenever you wish.', [
          _HelpEntry(Icons.air_rounded, 'Breathing',
              'Box, 4-7-8, belly and custom patterns have adjustable durations. The custom pattern also lets you change the inhale, hold and exhale counts. The graph shows session count and total duration over seven days.'),
          _HelpEntry(Icons.self_improvement_rounded, 'Meditation',
              'Browse Sleep, Ambient, Nature and Instrumental soundscapes. Tap a card to play, pause or seek within a track. Ending a session records listening time in the seven-day table.'),
        ]),
      ],
      'Mood tracking is for personal reflection, not diagnosis or treatment. If you feel unsafe or overwhelmed, seek support from a qualified professional or local emergency service.',
    ),
    'Meal Plan': _HelpContent(
      'Meal guidance',
      'This screen builds flexible food-group guidance from your latest saved diabetes and heart-disease analyses. It is generated on your device when opened.',
      [
        _HelpSection(
            'How the focus is chosen',
            'Both latest scores and their model classifications are considered. An elevated result takes priority; otherwise a difference between scores can shift the emphasis. Missing results are never assumed.',
            [
              _HelpEntry(Icons.bloodtype_outlined, 'Glucose-aware',
                  'Emphasizes a balanced plate and consistent quality-carbohydrate portions.'),
              _HelpEntry(Icons.favorite_outline_rounded, 'Heart-aware',
                  'Emphasizes fibre-rich food groups, unsaturated fats, and lower-sodium choices.'),
              _HelpEntry(Icons.restaurant_menu_rounded, 'Combined or balanced',
                  'Combines these principles when both results are elevated or neither needs a stronger emphasis.'),
            ]),
        _HelpSection(
            'What is displayed',
            'The sections describe meal structure, not exact recipes or calorie prescriptions.',
            [
              _HelpEntry(Icons.dining_rounded, 'Meal framework',
                  'Breakfast, midday, and evening guidance uses broad food categories that can suit different preferences.'),
              _HelpEntry(Icons.info_outline_rounded, 'Factors to discuss',
                  'Only relevant score-raising model factors add context. They are statistical contributions, not proven causes.'),
              _HelpEntry(Icons.picture_as_pdf_outlined, 'Generate PDF',
                  'Opens a PDF preview with share and save actions. It contains the currently displayed guidance.'),
            ]),
      ],
      'Educational guidance only. Risk scores cannot determine an individualized diet. Review allergies, medicines, pregnancy, kidney disease, and other needs with a qualified clinician or dietitian.',
    ),
    'Fitness': _HelpContent(
      'Fitness tracking',
      'Daily Activity displays measurements you record. Body Metrics uses your saved health profile height and weight. Generate Fitness Routine opens general activity guidance.',
      [
        _HelpSection('Daily Activity', 'No activity values are estimated.', [
          _HelpEntry(Icons.directions_run_rounded, 'Steps and activity time',
              'Log readings from a tracker or activity record. The colored rings use display scales, not personal goals.'),
          _HelpEntry(Icons.local_fire_department_outlined, 'Activity calories',
              'Only calories entered as activity burn are counted; resting energy expenditure is not estimated.'),
          _HelpEntry(Icons.bar_chart_rounded, 'Seven-day charts',
              'Each chart summarizes your logged entries for that date.'),
        ]),
        _HelpSection('Body Metrics',
            'Saved weight updates also appear in Health Data Input.', [
          _HelpEntry(Icons.monitor_weight_rounded, 'Weight',
              'Record a measured weight. BMI is calculated from weight and your saved height.'),
          _HelpEntry(Icons.accessibility_new_rounded, 'Body composition',
              'Skeletal muscle and body fat can be recorded separately; neither calculates BMI.'),
          _HelpEntry(Icons.show_chart_rounded, 'Weekly body trends',
              'Weight and BMI show the latest recorded reading in each of the past seven calendar weeks. A gap means no reading was recorded that week.'),
        ]),
      ],
      'BMI is a screening measure, not a diagnosis or personalized weight target. Discuss goals and exercise safety with your clinician.',
    ),
    'Fitness Routine': _HelpContent(
      'Fitness guidance',
      'This screen offers a gradual activity framework informed by your latest saved analyses. It does not test exercise readiness.',
      [
        _HelpSection(
            'How the focus is chosen',
            'The latest diabetes and heart-disease scores and classifications guide emphasis; a missing analysis remains missing.',
            [
              _HelpEntry(Icons.directions_walk_rounded, 'Aerobic activity',
                  'Accessible moderate movement spread through the week, starting from a comfortable level.'),
              _HelpEntry(Icons.fitness_center_rounded, 'Strength and balance',
                  'General adult guidance includes strengthening activities on two or more days each week.'),
              _HelpEntry(Icons.health_and_safety_outlined, 'Heart-aware safety',
                  'An elevated heart result calls for discussing vigorous activity or a major increase with a clinician.'),
            ]),
        _HelpSection(
            'Using this screen',
            'Choose activities that suit your ability and any existing clinical restrictions.',
            [
              _HelpEntry(Icons.info_outline_rounded, 'Factors to discuss',
                  'Model contributors are presented as discussion points, not exercise prescriptions.'),
              _HelpEntry(Icons.picture_as_pdf_outlined, 'Generate PDF',
                  'Opens a PDF preview with share and save actions for the same guidance.'),
            ]),
      ],
      'Educational activity guidance only. A model score cannot establish exercise safety. Stop for chest pain, dizziness, or unusual breathlessness and seek medical advice.',
    ),
    'Dashboard': _HelpContent(
        'Patient dashboard',
        'A quick view of your most recently saved risk analyses and health measurements. Returning to this tab refreshes the values.',
        [
          _HelpSection('At a glance',
              'Values come from your account and recorded history.', [
            _HelpEntry(Icons.donut_large_rounded, 'Risk overview',
                'Shows the latest diabetes and heart-disease analysis scores; a missing analysis has no current score.'),
            _HelpEntry(Icons.chat_bubble_outline_rounded, 'Drug enquiries',
                'Counts today’s saved Drug Assistant questions.'),
            _HelpEntry(Icons.monitor_heart_rounded, 'Quick stats',
                'Shows the latest recorded measurements and their available timestamps.'),
            _HelpEntry(Icons.edit_note_rounded, 'Update Health Metrics',
                'Opens the Health Data Input screen.'),
            _HelpEntry(Icons.restaurant_menu_rounded, 'Nutrition',
                'Open food, water, and blood-glucose logs or generate flexible meal guidance from your latest available analyses.'),
            _HelpEntry(Icons.fitness_center_rounded, 'Fitness',
                'Open activity and body metrics or generate a gradual activity framework.'),
            _HelpEntry(Icons.self_improvement_rounded, 'Mindfulness',
                'Open mood, breathing, and meditation tools.'),
            _HelpEntry(Icons.watch_rounded, 'Wearable status',
                'A connected wearable can update supported vitals. The badge shows whether readings are arriving.'),
            _HelpEntry(Icons.notifications_outlined, 'Risk alerts',
                'The notification badge reflects the latest medium or high analysis and opens a filtered history view.'),
          ]),
        ],
        'Risk scores are estimates, not diagnoses. A recent measurement may differ from your current condition.'),
    'Health Trends': _HelpContent(
        'Health trends',
        'Explore recorded measurements across the last seven days. A patient with a reported diagnosis can also open a condition-specific trends report from Health Data Input.',
        [
          _HelpSection(
              'Graphs',
              'Each point represents a stored measurement; a gap is not a zero reading.',
              [
                _HelpEntry(Icons.water_drop_rounded, 'Glucose',
                    'Shows available glucose laboratory readings with their recorded dates and units.'),
                _HelpEntry(Icons.monitor_weight_rounded, 'BMI',
                    'Calculated from recorded height and weight measurements.'),
                _HelpEntry(Icons.favorite_rounded, 'Systolic pressure',
                    'Uses the upper blood-pressure measurement from saved vitals.'),
              ]),
          _HelpSection('Condition-specific report',
              'The report uses saved readings and highlights net increases to discuss, not causes or model contributions.', [
            _HelpEntry(Icons.bar_chart_rounded, 'Readings to review',
                'A first-to-latest increase in glucose, blood pressure or cholesterol is shown with its units and date. One reading cannot establish a trend.'),
            _HelpEntry(Icons.picture_as_pdf_outlined, 'PDF report',
                'Open a PDF summary of the available seven-day readings from the report screen.'),
          ]),
        ],
        'These are historical readings. Discuss unusual or concerning values with a health professional.'),
    'Prediction History': _HelpContent(
        'Prediction history',
        'Review saved risk analyses and how results have changed over time.',
        [
          _HelpSection('Explore results',
              'The trend chart follows the most recently run analysis type.', [
            _HelpEntry(Icons.show_chart_rounded, 'Risk trend',
                'Plots stored scores for one model; it does not represent a clinical measurement.'),
            _HelpEntry(Icons.filter_list_rounded, 'Filters',
                'Choose disease type or score range, and independently sort newest or oldest first.'),
            _HelpEntry(Icons.history_rounded, 'All predictions',
                'Open a saved entry to review its recorded score and time.'),
          ]),
        ],
        'Changes in model scores do not prove that a disease has developed or improved.'),
    'Assistant': _HelpContent(
        'RiskSense Assistant',
        'Ask about a named medicine for reviewed educational evidence. Patient accounts can manage a self-reported medication list and summarize their own recorded health trends with text commands.',
        [
          _HelpSection('How answers work',
              'Evidence availability varies by medicine and question.', [
            _HelpEntry(Icons.medication_rounded, 'Name the medicine',
                'Use a supported generic or recognized brand name; vague descriptions may be ambiguous.'),
            _HelpEntry(Icons.book_outlined, 'Reviewed evidence',
                'Cited source claims appear with an evidence status such as Limited Evidence.'),
            _HelpEntry(Icons.info_outline_rounded, 'Missing evidence',
                'Insufficient Evidence means this specific topic is not covered; it does not establish safety.'),
            _HelpEntry(Icons.forum_outlined, 'Conversation',
                'Messages are saved to the authorized patient conversation.'),
          ]),
          _HelpSection(
              'Medication list commands',
              'These commands use your patient medication records. They do not verify a prescription or change treatment.',
              [
                _HelpEntry(Icons.add_rounded, 'Add medication',
                    'Type: add medication name + optional routine + optional dosage. Example: add medication metformin + every morning + 500 mg.'),
                _HelpEntry(Icons.list_alt_rounded, 'View medication',
                    'Type: view medication. Active saved entries show their recorded routine and dosage when supplied.'),
                _HelpEntry(
                    Icons.remove_circle_outline_rounded,
                    'Remove medication',
                    'Type: remove medication name. Only one exact active name match is deactivated; duplicate names require review.'),
              ]),
          _HelpSection(
              'Your recorded health trends',
              'This is a read-only summary of your authorized measurements from the past seven days. It does not use the Drug Assistant evidence model.',
              [
                _HelpEntry(Icons.show_chart_rounded, 'Show my health trends',
                    'Summarizes available blood pressure, heart rate, fasting laboratory glucose, total cholesterol, weight, and BMI readings with dates.'),
                _HelpEntry(Icons.monitor_heart_outlined, 'Ask about one topic',
                    'For example, type: show my blood pressure trend. Missing readings are never treated as zero.'),
              ]),
        ],
        'Medication entries are patient reported. Removing one from the app does not mean you should stop taking it. Educational information cannot prescribe, diagnose, or establish safety; consult your prescriber or pharmacist.'),
    'My Profile': _HelpContent(
        'My profile',
        'Review account identity, access information, and the shortcut to device settings.',
        [
          _HelpSection('Account details',
              'These values come from backend account records.', [
            _HelpEntry(Icons.person_outline_rounded, 'Identity',
                'View your name, email, and recorded demographics.'),
            _HelpEntry(Icons.badge_outlined, 'Patient ID',
                'Tap to reveal and copy your patient identifier when needed.'),
            _HelpEntry(Icons.verified_user_outlined, 'Access',
                'Review subscription or insurance-linked status and any linked clinician shown.'),
            _HelpEntry(Icons.logout_rounded, 'Sign out',
                'End your local application session.'),
            _HelpEntry(Icons.settings_outlined, 'Settings',
                'Manage appearance, accessibility, risk alerts, password, and signed-in sessions.'),
          ]),
        ],
        'Contact support if account or access details appear incorrect. Do not share your login credentials.'),
    'Admin Console': _HelpContent(
        'Admin console',
        'Operational overview for authorized administrators.',
        [
          _HelpSection('What you can review',
              'These are account and system-management views.', [
            _HelpEntry(Icons.people_outline_rounded, 'Users',
                'Review account totals and navigate to user management.'),
            _HelpEntry(Icons.security_rounded, 'Security events',
                'Inspect recorded audit activity and items requiring attention.'),
            _HelpEntry(Icons.model_training_rounded, 'Models',
                'Review active model versions and availability.'),
          ]),
        ],
        'Administrative privileges do not replace clinical authorization. Verify the target of every action.'),
    'User Management': _HelpContent(
        'User management',
        'Search for accounts and review their access state before acting.',
        [
          _HelpSection('Account controls',
              'Available actions are restricted by your administrator role.', [
            _HelpEntry(Icons.search_rounded, 'Search and filter',
                'Locate the intended account by identifying information and role.'),
            _HelpEntry(Icons.block_rounded, 'Suspend',
                'Restrict access for a selected account; the action is audited.'),
            _HelpEntry(Icons.restore_rounded, 'Restore',
                'Re-enable an eligible suspended account; the action is audited.'),
          ]),
        ],
        'Confirm account identity and the reason for changing access before taking an administrative action.'),
    'Audit Logs': _HelpContent(
        'Audit logs',
        'Review recorded security and operational events.',
        [
          _HelpSection(
              'Reading entries',
              'Events help explain what the system recorded, not every surrounding circumstance.',
              [
                _HelpEntry(Icons.event_rounded, 'Timestamp',
                    'The time the backend recorded the action.'),
                _HelpEntry(Icons.person_search_rounded, 'Actor and resource',
                    'The account and object associated with the event when available.'),
                _HelpEntry(Icons.flag_outlined, 'Event type',
                    'Identifies login, access, model, account, and other audited operations.'),
              ]),
        ],
        'Audit logs may be incomplete context for an incident. Handle them as sensitive operational records.'),
    'Model Management': _HelpContent(
        'Model management',
        'Review registered model versions and control their availability.',
        [
          _HelpSection(
              'Model state', 'Changes affect whether new analyses can run.', [
            _HelpEntry(Icons.memory_rounded, 'Version',
                'Identifies the exact deployed model artifact.'),
            _HelpEntry(Icons.toggle_on_outlined, 'Activation',
                'An active model can serve new authorized requests; changes are audited.'),
            _HelpEntry(Icons.analytics_outlined, 'Metrics',
                'Reported evaluation metrics describe model testing, not an individual prediction.'),
          ]),
        ],
        'Confirm model identity and operational impact before activating or suspending a version.'),
    'Admin Profile': _HelpContent(
        'Admin profile',
        'Review your administrator account and recent recorded activity.',
        [
          _HelpSection('Profile fields',
              'Displayed activity is based on backend records.', [
            _HelpEntry(Icons.badge_outlined, 'Admin ID',
                'Your application administrator identifier.'),
            _HelpEntry(Icons.login_rounded, 'Last login',
                'The most recent recorded successful sign-in timestamp.'),
            _HelpEntry(Icons.history_rounded, 'Last action',
                'The latest recorded administrative event.'),
            _HelpEntry(
                Icons.logout_rounded, 'Sign out', 'End your local session.'),
          ]),
        ],
        'Recent activity may not include every action. Report unrecognized account activity promptly.'),
    'Clinician Dashboard': _HelpContent(
        'Clinician dashboard',
        'Overview of patients and recent information available to your authorized clinician account.',
        [
          _HelpSection('Clinical workflow',
              'Patient details are limited to permitted relationships.', [
            _HelpEntry(Icons.people_alt_outlined, 'Linked patients',
                'Open patients linked to your approved clinician record.'),
            _HelpEntry(Icons.notification_important_outlined, 'Alerts',
                'Open an alert to view its exact saved risk prediction. View All applies the High alerts patient filter.'),
            _HelpEntry(Icons.history_rounded, 'Recent activity',
                'See recent authorized patient events.'),
          ]),
        ],
        'Decision-support signals do not replace a full clinical assessment or professional judgment.'),
    'Patients': _HelpContent(
        'Patients',
        'Find patients linked to your clinician account.',
        [
          _HelpSection('Patient list',
              'Only authorized relationships should be visible.', [
            _HelpEntry(Icons.search_rounded, 'Search',
                'Find a linked patient by available identity fields.'),
            _HelpEntry(Icons.filter_list_rounded, 'Filters',
                'Filter high alerts, Diabetes, Heart Disease, or patients without analyses; sort independently by name or analysis date.'),
            _HelpEntry(Icons.open_in_new_rounded, 'Open record',
                'Review permitted information for a selected patient.'),
          ]),
        ],
        'Access a patient record only for an authorized care purpose.'),
    'Clinician Profile': _HelpContent(
        'Clinician profile',
        'Review your professional and account information.',
        [
          _HelpSection('Identity',
              'These are backend clinician and user-account fields.', [
            _HelpEntry(Icons.badge_outlined, 'RiskSense ID',
                'Your application-specific clinician identifier.'),
            _HelpEntry(Icons.medical_services_outlined, 'Professional details',
                'Review the license, title, specialization, and institution shown.'),
            _HelpEntry(
                Icons.logout_rounded, 'Sign out', 'End your local session.'),
          ]),
        ],
        'Check that your professional details are correct before relying on them.'),
    'Patient Detail': _HelpContent(
        'Patient details',
        'Review information for a patient linked to your clinician account.',
        [
          _HelpSection('Record sections',
              'Displayed information depends on current authorization.', [
            _HelpEntry(Icons.person_outline_rounded, 'Patient summary',
                'Review the patient identity and profile information shown.'),
            _HelpEntry(Icons.monitor_heart_outlined, 'Health data',
                'See available measurements and their timestamps.'),
            _HelpEntry(Icons.analytics_outlined, 'Risk analyses',
                'Open the latest saved Diabetes or Heart Disease result for its actual factors and input snapshot.'),
            _HelpEntry(Icons.picture_as_pdf_outlined, 'PDF summary',
                'Review the POPIA privacy reminder before generating a patient summary PDF.'),
          ]),
        ],
        'Use the full clinical record and professional judgment; model estimates are not diagnoses.'),
    'Demonstration Analysis': _HelpContent(
        'Clinician demonstration analysis',
        'Enter temporary demographic and measurement inputs for a model demonstration.',
        [
          _HelpSection('Data and privacy',
              'The selected model uses only its required fields.', [
            _HelpEntry(Icons.person_outline_rounded, 'Demographics',
                'Enter age and sex for the model; ethnicity is optional context and is not a model feature.'),
            _HelpEntry(Icons.analytics_outlined, 'Analysis',
                'The result is calculated in memory. No patient, vital, laboratory, or prediction record is created.'),
            _HelpEntry(Icons.picture_as_pdf_outlined, 'PDF',
                'The result can be exported locally after the POPIA privacy reminder.'),
          ]),
        ],
        'This demonstration is decision support, not a diagnosis or treatment recommendation.'),
  };

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return IconButton(
      tooltip: 'About this screen',
      icon: Icon(Icons.help_outline_rounded,
          color: AppColors.primaryBlue, size: 23),
      onPressed: () {
        final detail = _content[topic] ??
            _HelpContent(
                topic,
                'Review the information and actions available on this screen.',
                const [],
                'Confirm important health or account information with an appropriate professional.');
        showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.cardWhite,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * .82,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.heroStart, AppColors.heroEnd]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.help_outline_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text(detail.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 19))),
                    IconButton(
                      tooltip: 'Close help',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ]),
                ),
                Flexible(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlue,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: .20)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('ABOUT THIS SCREEN', style: TextStyle(
                            color: AppColors.primaryBlue, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                        const SizedBox(height: 7),
                        Text(detail.intro, style: TextStyle(
                            color: AppColors.textPrimary, height: 1.45)),
                      ]),
                    ),
                    for (final section in detail.sections) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(section.title, style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                          const SizedBox(height: 5),
                          Text(section.context, style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                          for (final entry in section.entries) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceTeal,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.teal.withValues(alpha: .20)),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(entry.icon, size: 21, color: AppColors.teal),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(entry.label, style: TextStyle(
                                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(entry.detail, style: TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                                ])),
                              ]),
                            ),
                          ],
                        ]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.amber.withValues(alpha: .35)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 21),
                        const SizedBox(width: 10),
                        Expanded(child: Text(detail.disclaimer, style: TextStyle(
                            fontSize: 12, color: AppColors.textPrimary, height: 1.4))),
                      ]),
                    ),
                  ]),
                )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: SizedBox(width: double.infinity, child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Done'),
                  )),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
