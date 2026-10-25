import 'package:agonez/src/errors/user_error_mapper.dart';
import 'package:agonez/src/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final strings = AppLocalizationsEn();

  test('start refusals have messages of their own', () {
    expect(
      messageForErrorCode('prescription_incomplete', strings),
      strings.errorPrescriptionIncomplete,
    );
    expect(
      messageForErrorCode('not_next_track_exposure', strings),
      strings.errorNotNextTrackExposure,
    );
  });

  test('an unknown code has no message, so callers pick the fallback', () {
    expect(messageForErrorCode('something_new', strings), isNull);
    expect(messageForErrorCode(null, strings), isNull);
  });
}
