import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;
import '../models/content_models.dart';

class GoogleCalendarService {
  static const _scopes = [
    cal.CalendarApi.calendarScope,
    cal.CalendarApi.calendarEventsScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  Future<void> insertPlanToCalendar(ContentPlan plan) async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) throw StateError('Google sign-in failed');

    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    final api = cal.CalendarApi(client);
    for (final item in plan.items) {
      final event = cal.Event(
        summary: '${item.platform}: ${item.title}',
        description: '${item.description}\n\nScript:\n${item.script}\n\nHashtags: ${item.hashtags.join(' ')}\nTips: ${item.tips}',
        start: cal.EventDateTime(dateTime: item.scheduledAt.toUtc()),
        end: cal.EventDateTime(dateTime: item.scheduledAt.add(const Duration(minutes: 30)).toUtc()),
      );
      await api.events.insert(event, 'primary');
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _baseClient = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _baseClient.send(request);
  }
}

