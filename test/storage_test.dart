import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_food/data/datasources/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('Legacy OpenRouter key migrates to encrypted storage without being reused for OpenCode', () async {
    SharedPreferences.setMockInitialValues({
      'brainfood_ai_api_key': 'legacy-test',
    });
    expect(await LocalStorageService.loadProviderKey('opencode'), '');
    expect(
      await LocalStorageService.loadProviderKey('openrouter'),
      'legacy-test',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('brainfood_ai_api_key'), isFalse);
  });
  test(
    'Provider keys are isolated and local mode does not expose a key',
    () async {
      await LocalStorageService.saveAiConfiguration(
        'opencode',
        'example',
        'zen-test',
      );
      await LocalStorageService.saveAiConfiguration(
        'openrouter',
        'example',
        'router-test',
      );
      expect(await LocalStorageService.loadApiKey(), 'router-test');
      expect(await LocalStorageService.loadProviderKey('opencode'), 'zen-test');
      await LocalStorageService.saveAiConfiguration('local', '', '');
      expect(await LocalStorageService.loadApiKey(), '');
      expect(
        await LocalStorageService.loadProviderKey('openrouter'),
        'router-test',
      );
    },
  );
}
