import 'package:url_launcher/url_launcher.dart';

/// Opens the same support address from settings and model availability dialogs.
Future<bool> launchDeveloperEmail() => launchUrl(Uri(
      scheme: 'mailto',
      path: 'shivenreddyxi@gmail.com',
      queryParameters: {'subject': 'RiskSense AI support'},
    ));
