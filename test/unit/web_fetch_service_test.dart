import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ambot_ai/core/services/web_fetch_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late WebFetchService service;
  late MockClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://fallback.example.com'));
  });

  setUp(() {
    service = WebFetchService.instance;
    service.reset();
    mockClient = MockClient();
    when(() => mockClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(
              '<html><body><p>ok</p></body></html>',
              200,
              headers: {'content-type': 'text/html'},
            ));
  });

  group('FetchResult', () {
    test('constructor sets all fields', () {
      final r = FetchResult(url: 'https://example.com', content: 'hello', error: null);
      expect(r.url, 'https://example.com');
      expect(r.content, 'hello');
      expect(r.error, isNull);
    });

    test('isSuccess is true when no error and content not empty', () {
      expect(FetchResult(url: 'u', content: 'c').isSuccess, isTrue);
    });

    test('isSuccess is false when error is set', () {
      expect(FetchResult(url: 'u', content: '', error: 'fail').isSuccess, isFalse);
    });

    test('isSuccess is false when content is empty and no error', () {
      expect(FetchResult(url: 'u', content: '').isSuccess, isFalse);
    });

    test('display returns content for success', () {
      final r = FetchResult(url: 'https://x.com', content: 'page text');
      expect(r.display, 'SOURCE (https://x.com):\npage text');
    });

    test('display returns error for failure', () {
      final r = FetchResult(url: 'https://x.com', content: '', error: '404');
      expect(r.display, 'FETCH ERROR (https://x.com): 404');
    });
  });

  group('extractFetchUrls', () {
    test('extracts single URL', () {
      final urls = WebFetchService.extractFetchUrls('Check [FETCH:https://example.com] for details');
      expect(urls, ['https://example.com']);
    });

    test('extracts multiple URLs', () {
      final urls = WebFetchService.extractFetchUrls(
        '[FETCH:https://a.com] and [FETCH:https://b.com]',
      );
      expect(urls, ['https://a.com', 'https://b.com']);
    });

    test('extracts URL without protocol', () {
      final urls = WebFetchService.extractFetchUrls('[FETCH:example.com]');
      expect(urls, ['example.com']);
    });

    test('extracts URL with extra whitespace', () {
      final urls = WebFetchService.extractFetchUrls('[FETCH:  https://x.com  ]');
      expect(urls, ['https://x.com']);
    });

    test('returns empty list when no FETCH tags', () {
      final urls = WebFetchService.extractFetchUrls('Just normal text');
      expect(urls, isEmpty);
    });

    test('is case-insensitive', () {
      final urls = WebFetchService.extractFetchUrls('[fetch:https://x.com] and [FETCH:https://y.com]');
      expect(urls, ['https://x.com', 'https://y.com']);
    });
  });

  group('removeFetchTags', () {
    test('removes single FETCH tag', () {
      final result = WebFetchService.removeFetchTags('Hello [FETCH:https://x.com] world');
      expect(result, 'Hello world');
    });

    test('removes multiple FETCH tags', () {
      final result = WebFetchService.removeFetchTags(
        '[FETCH:https://a.com] and [FETCH:https://b.com] are done',
      );
      expect(result, 'and are done');
    });

    test('returns original text when no tags', () {
      expect(WebFetchService.removeFetchTags('No tags here'), 'No tags here');
    });

    test('handles empty string', () {
      expect(WebFetchService.removeFetchTags(''), isEmpty);
    });

    test('handles only tags', () {
      expect(WebFetchService.removeFetchTags('[FETCH:https://x.com]'), isEmpty);
    });
  });

  group('startTurn', () {
    test('resets turn counter for new turnId', () async {
      service.startTurn('turn-1');
      await service.fetch('https://example.com', client: mockClient);

      service.startTurn('turn-2');
      expect(service.remainingThisTurn, 5);
    });

    test('does not reset counter for same turnId', () async {
      service.startTurn('turn-1');
      await service.fetch('https://example.com', client: mockClient);

      service.startTurn('turn-1');
      expect(service.remainingThisTurn, 4);
    });
  });

  group('rate limiting', () {
    test('starts as true with 5 remaining', () {
      expect(service.canFetch, isTrue);
      expect(service.remainingThisMinute, 5);
    });

    test('becomes false after 5 fetches within a minute', () async {
      for (var i = 0; i < 5; i++) {
        await service.fetch('https://example.com', client: mockClient);
      }

      expect(service.canFetch, isFalse);
      expect(service.remainingThisMinute, 0);
    });

    test('remainingThisTurn decrements with each fetch', () async {
      expect(service.remainingThisTurn, 5);
      await service.fetch('https://example.com', client: mockClient);
      expect(service.remainingThisTurn, 4);
      await service.fetch('https://example.com', client: mockClient);
      expect(service.remainingThisTurn, 3);
    });
  });

  group('fetch', () {
    test('returns content for successful HTML fetch', () async {
      final result = await service.fetch('https://example.com', client: mockClient);
      expect(result.isSuccess, isTrue);
      expect(result.content, contains('ok'));
      expect(result.error, isNull);
    });

    test('returns content for successful JSON fetch', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                '{"name": "test", "value": 42}',
                200,
                headers: {'content-type': 'application/json'},
              ));

      final result = await service.fetch('https://api.example.com/data', client: mockClient);
      expect(result.isSuccess, isTrue);
      expect(result.content, contains('"name"'));
      expect(result.content, contains('"test"'));
    });

    test('normalizes URL without protocol', () async {
      final result = await service.fetch('example.com', client: mockClient);
      expect(result.isSuccess, isTrue);
    });

    test('returns rate limit error when exceeded', () async {
      for (var i = 0; i < 5; i++) {
        await service.fetch('https://example.com', client: mockClient);
      }

      final result = await service.fetch('https://example.com', client: mockClient);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Rate limit reached'));
    });

    test('returns error for non-200 status', () async {
      service.reset();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404, headers: {'content-type': 'text/html'}));

      final result = await service.fetch('https://example.com/404', client: mockClient);
      expect(result.isSuccess, isFalse);
      expect(result.error, 'HTTP 404');
    });

    test('returns error for empty content after stripping', () async {
      service.reset();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                '<html><script>empty</script></html>',
                200,
                headers: {'content-type': 'text/html'},
              ));

      final result = await service.fetch('https://example.com/empty', client: mockClient);
      expect(result.isSuccess, isFalse);
      expect(result.error, 'No readable content found at URL');
    });

    test('truncates long content', () async {
      service.reset();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                '<html><body><p>${'A' * 10000}</p></body></html>',
                200,
                headers: {'content-type': 'text/html'},
              ));

      final result = await service.fetch('https://example.com/long', client: mockClient);
      expect(result.isSuccess, isTrue);
      expect(result.content, contains('[truncated at 8000 chars]'));
    });

    test('returns error on exception', () async {
      service.reset();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('Connection refused'));

      final result = await service.fetch('https://example.com/error', client: mockClient);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Connection refused'));
    });

    test('handles http:// URLs', () async {
      final result = await service.fetch('http://example.com', client: mockClient);
      expect(result.isSuccess, isTrue);
    });

    test('strips HTML tags from content', () async {
      service.reset();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                '<html><body><h1>Title</h1><p>Paragraph</p><ul><li>Item</li></ul></body></html>',
                200,
                headers: {'content-type': 'text/html'},
              ));

      final result = await service.fetch('https://example.com', client: mockClient);
      expect(result.content, contains('Title'));
      expect(result.content, contains('Paragraph'));
      expect(result.content, contains('- Item'));
      expect(result.content, isNot(contains('<')));
    });
  });
}
