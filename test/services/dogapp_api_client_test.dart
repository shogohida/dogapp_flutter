import 'dart:convert';
import 'dart:typed_data';

import 'package:dogapp/models/dog.dart';
import 'package:dogapp/models/walk.dart';
import 'package:dogapp/services/dogapp_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// http.Responseは既定でLatin1エンコーディングを使うため、日本語を含む
/// レスポンスはcharset=utf-8を明示しないとエンコードエラーになる。
http.Response _jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('HttpDogappApiClient.fetchDogs', () {
    test('GET /owners/{ownerId}/dogs のレスポンスをDogのリストにパースする', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/owners/owner-1/dogs');
        return _jsonResponse([
          {
            'id': 'leo',
            'name': 'レオ',
            'breed': 'スタンダードプードル',
            'color': 'アプリコット',
            'birthYear': 2021,
            'weightHistory': [
              {'month': '3月', 'kg': 24.8},
            ],
            'records': [
              {
                'id': '1',
                'type': 'vaccine',
                'label': '混合ワクチン接種',
                'date': '2026-07-12T00:00:00Z'
              },
            ],
          },
        ]);
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final dogs = await client.fetchDogs('owner-1');

      expect(dogs, hasLength(1));
      expect(dogs.first.id, 'leo');
      expect(dogs.first.name, 'レオ');
      expect(dogs.first.weightHistory.single.kg, 24.8);
      expect(dogs.first.records.single.type, 'vaccine');
    });

    test('2xx以外のステータスコードではApiExceptionを投げる', () async {
      final mock =
          MockClient((request) async => http.Response('server error', 500));
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      expect(() => client.fetchDogs('owner-1'), throwsA(isA<ApiException>()));
    });
  });

  group('HttpDogappApiClient.updateDog', () {
    test('name/breed/color/birthYearをPATCHする', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/dogs/leo');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'レオ2');
        expect(body['breed'], 'トイプードル');
        expect(body['color'], 'ホワイト');
        expect(body['birthYear'], 2020);
        return _jsonResponse({
          'id': 'leo',
          'name': 'レオ2',
          'breed': 'トイプードル',
          'color': 'ホワイト',
          'birthYear': 2020,
        });
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      await client.updateDog(
        dogId: 'leo',
        name: 'レオ2',
        breed: 'トイプードル',
        color: 'ホワイト',
        birthYear: 2020,
      );
    });

    test('2xx以外のステータスコードではApiExceptionを投げる', () async {
      final mock =
          MockClient((request) async => http.Response('server error', 500));
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      expect(
        () => client.updateDog(
          dogId: 'leo',
          name: 'x',
          breed: 'x',
          color: 'x',
          birthYear: 2020,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('HttpDogappApiClient.runAiCheck', () {
    test('画像をBase64化してPOSTし、AICheckResultを返す', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/dogs/leo/ai-check');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['imageBase64'], base64Encode([1, 2, 3]));
        return _jsonResponse(
            {'level': 'watch', 'title': '軽度の乾燥', 'detail': '様子を見てください'});
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final result = await client.runAiCheck(
        dogId: 'leo',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result.level, AICheckLevel.watch);
      expect(result.title, '軽度の乾燥');
    });
  });

  group('HttpDogappApiClient.runGaitCheck', () {
    test('動画をmultipart/form-dataでPOSTし、AICheckResultを返す', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/dogs/leo/gait-check');
        expect(
            request.headers['content-type'], contains('multipart/form-data'));
        // multipartのボディはUTF-8として不正な可能性があるためallowMalformedで読む。
        final rawBody = utf8.decode(request.bodyBytes, allowMalformed: true);
        expect(rawBody, contains('walk.mp4'));
        expect(rawBody, contains('FAKE_VIDEO_BYTES'));
        return _jsonResponse(
            {'level': 'concern', 'title': '足を引きずる動き', 'detail': '動物病院へ'});
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final result = await client.runGaitCheck(
        dogId: 'leo',
        videoBytes: Uint8List.fromList(utf8.encode('FAKE_VIDEO_BYTES')),
        filename: 'walk.mp4',
      );

      expect(result.level, AICheckLevel.concern);
      expect(result.title, '足を引きずる動き');
    });
  });

  group('HttpDogappApiClient.createRecord', () {
    test('type/label/costをPOSTし、作成されたHealthRecordを返す', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/dogs/leo/records');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'vet');
        expect(body['label'], '定期健診');
        expect(body['cost'], 4500.0);
        return _jsonResponse({
          'id': '99',
          'type': 'vet',
          'label': '定期健診',
          'date': '2026-08-27T00:00:00Z',
          'cost': 4500.0,
        });
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final record = await client.createRecord(
          dogId: 'leo', type: 'vet', label: '定期健診', cost: 4500);

      expect(record.id, '99');
      expect(record.type, 'vet');
      expect(record.cost, 4500.0);
    });

    test('costを省略するとリクエストボディにcostフィールドが含まれない', () async {
      final mock = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('cost'), isFalse);
        return _jsonResponse({
          'id': '99',
          'type': 'vaccine',
          'label': 'ワクチン',
          'date': '2026-08-27T00:00:00Z',
        });
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final record = await client.createRecord(
          dogId: 'leo', type: 'vaccine', label: 'ワクチン');

      expect(record.cost, isNull);
    });
  });

  group('HttpDogappApiClient.fetchWalks', () {
    test('GET /dogs/{dogId}/walks のレスポンスをWalkRouteのリストにパースする', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/dogs/leo/walks');
        return _jsonResponse([
          {
            'id': 'w1',
            'dogId': 'leo',
            'startedAt': '2026-08-27T10:00:00Z',
            'durationSeconds': 1200,
            'distanceMeters': 1500.5,
            'points': [
              {'lat': 35.0, 'lng': 139.0, 'timestamp': '2026-08-27T10:00:00Z'},
            ],
          },
        ]);
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final walks = await client.fetchWalks('leo');

      expect(walks, hasLength(1));
      expect(walks.first.distanceMeters, 1500.5);
      expect(walks.first.duration, const Duration(seconds: 1200));
      expect(walks.first.points.single.lat, 35.0);
    });
  });

  group('HttpDogappApiClient.createWalk', () {
    test('開始時刻・距離・GPS点をPOSTし、作成されたWalkRouteを返す', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/dogs/leo/walks');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['durationSeconds'], 600);
        expect(body['distanceMeters'], 800.0);
        expect((body['points'] as List).length, 1);
        return _jsonResponse({
          'id': 'w2',
          'dogId': 'leo',
          'startedAt': '2026-08-27T10:00:00Z',
          'durationSeconds': 600,
          'distanceMeters': 800.0,
          'points': body['points'],
        });
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final walk = await client.createWalk(
        dogId: 'leo',
        startedAt: DateTime.utc(2026, 8, 27, 10),
        duration: const Duration(seconds: 600),
        distanceMeters: 800,
        points: [
          GeoPoint(
              lat: 35.0, lng: 139.0, timestamp: DateTime.utc(2026, 8, 27, 10))
        ],
      );

      expect(walk.id, 'w2');
      expect(walk.distanceMeters, 800.0);
    });
  });

  group('HttpDogappApiClient.fetchUpcoming', () {
    test('GET /owners/{ownerId}/upcoming のレスポンスをUpcomingItemのリストにパースする',
        () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/owners/owner-1/upcoming');
        return _jsonResponse([
          {
            'id': '1',
            'dogId': 'leo',
            'type': 'grooming',
            'label': '次回トリミング予約',
            'date': '2026-09-01T00:00:00Z',
          },
        ]);
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final items = await client.fetchUpcoming('owner-1');

      expect(items, hasLength(1));
      expect(items.first.dogId, 'leo');
      expect(items.first.type, RecordType.grooming);
    });
  });

  group('HttpDogappApiClient.createUpcoming', () {
    test('type/label/dateをPOSTし、作成されたUpcomingItemを返す', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/dogs/leo/upcoming');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'vet');
        expect(body['label'], '定期健診');
        return _jsonResponse({
          'id': '99',
          'dogId': 'leo',
          'type': 'vet',
          'label': '定期健診',
          'date': '2026-09-10T00:00:00Z',
        });
      });
      final client = HttpDogappApiClient(
          httpClient: mock, baseUrl: 'http://localhost:8080');

      final item = await client.createUpcoming(
        dogId: 'leo',
        type: RecordType.vet,
        label: '定期健診',
        date: DateTime.utc(2026, 9, 10),
      );

      expect(item.id, '99');
      expect(item.type, RecordType.vet);
    });
  });
}
