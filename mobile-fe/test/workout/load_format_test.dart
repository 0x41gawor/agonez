import 'package:agonez/src/workout/load_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trims zeros only after the decimal point', () {
    // Whole loads used to lose their last digit: 80 showed as "8".
    expect(formatLoad(80), '80');
    expect(formatLoad(100), '100');
    expect(formatLoad(12), '12');
    expect(formatLoad(72.5), '72.5');
    expect(formatLoad(61.25), '61.25');
    expect(formatLoad(0.5), '0.5');
    expect(formatLoad(0), '0');
  });
}
