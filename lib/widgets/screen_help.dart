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
    'Registration': _HelpContent(
      'Create your patient account',
      'Enter your own account details to register. Registration creates a patient account; access to risk analysis still requires an active entitlement.',
      [
        _HelpSection('Identity', 'Use accurate details so your account and health information remain linked to you.', [
          _HelpEntry(Icons.person_outline_rounded, 'Full name', 'Enter your first and last name.'),
          _HelpEntry(Icons.mail_outline_rounded, 'Email address', 'Use an address you can access. It becomes your sign-in name.'),
          _HelpEntry(Icons.cake_outlined, 'Date of birth', 'Used to calculate your age. Choose your actual date of birth.'),
          _HelpEntry(Icons.badge_outlined, 'Gender', 'Choose the option that applies to you. Some analyses require a recorded sex value.'),
        ]),
        _HelpSection('Account security', 'Choose a password you have not reused elsewhere.', [
          _HelpEntry(Icons.lock_outline_rounded, 'Password', 'At least 6 characters, with a capital letter, a number, and a special character.'),
          _HelpEntry(Icons.verified_user_outlined, 'Confirm password', 'Enter exactly the same password again.'),
          _HelpEntry(Icons.check_box_outlined, 'Consent', 'Read and accept the health-data notice before creating the account.'),
        ]),
      ],
      'RiskSense AI provides decision support, not a diagnosis. Registration does not verify a subscription or insurance benefit.'),
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
            ]),
      ],
      'This is decision support, not a diagnosis or a prediction of certainty. Review concerning results and any treatment decisions with a qualified clinician.',
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
                  'Creates a local PDF and opens the device share or save options. It contains the currently displayed guidance.'),
            ]),
      ],
      'Educational guidance only. Risk scores cannot determine an individualized diet. Review allergies, medicines, pregnancy, kidney disease, and other needs with a qualified clinician or dietitian.',
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
                  'Creates a local PDF with the same guidance and opens device share or save options.'),
            ]),
      ],
      'Educational activity guidance only. A model score cannot establish exercise safety. Stop for chest pain, dizziness, or unusual breathlessness and seek medical advice.',
    ),
    'Dashboard': _HelpContent(
        'Patient dashboard',
        'A quick view of your most recently saved health information and analyses.',
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
            _HelpEntry(Icons.restaurant_menu_rounded, 'Meal Plan',
                'Opens flexible food-group guidance based on the latest available model results.'),
            _HelpEntry(Icons.fitness_center_rounded, 'Fitness Routine',
                'Opens a gradual activity framework with safety context.'),
          ]),
        ],
        'Risk scores are estimates, not diagnoses. A recent measurement may differ from your current condition.'),
    'Health Trends': _HelpContent(
        'Health trends',
        'Explore recorded measurements across the last seven calendar days.',
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
        'Drug Assistant',
        'Ask a specific question about a named medication. The assistant retrieves eligible reviewed evidence for the topic you ask about.',
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
        ],
        'Educational information cannot prescribe, diagnose, or decide whether a medicine is safe for you. Consult your prescriber or pharmacist.'),
    'My Profile': _HelpContent(
        'My profile',
        'Review your account identity and current access information.',
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
  Widget build(BuildContext context) => IconButton(
        tooltip: 'About this screen',
        icon: const Icon(Icons.help_outline_rounded,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * .82,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBlue,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.help_outline_rounded,
                            color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(detail.title,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      IconButton(
                        tooltip: 'Close help',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ]),
                  ),
                  Flexible(
                      child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(detail.intro,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.45)),
                          for (final section in detail.sections) ...[
                            const SizedBox(height: 18),
                            Text(section.title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(section.context,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4)),
                            const SizedBox(height: 8),
                            for (final entry in section.entries)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(entry.icon,
                                          size: 21,
                                          color: AppColors.primaryBlue),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(entry.label,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text(entry.detail,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                  height: 1.4)),
                                        ],
                                      )),
                                    ]),
                              ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.amber.withValues(alpha: .22)),
                            ),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      size: 18, color: AppColors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(detail.disclaimer,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.45))),
                                ]),
                          ),
                        ]),
                  )),
                ]),
              ),
            ),
          );
        },
      );
}
