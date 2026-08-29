// dogapp-api の代わりに動作確認するための簡易モックサーバー。
// 実際のdogapp-api(Go実装)とは別物で、開発時の疎通確認専用。
//
// 実行: dart run tool/mock_server.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

final _dogs = <Map<String, dynamic>>[
  {
    'id': 'leo',
    'name': 'レオ',
    'breed': 'スタンダードプードル',
    'color': 'アプリコット',
    'birthYear': 2021,
    'weightHistory': [
      {'month': '3月', 'kg': 24.8},
      {'month': '4月', 'kg': 25.1},
      {'month': '5月', 'kg': 24.9},
      {'month': '6月', 'kg': 25.3},
      {'month': '7月', 'kg': 25.4},
      {'month': '8月', 'kg': 25.2},
    ],
    'records': [
      {
        'id': '1',
        'type': 'vaccine',
        'label': '混合ワクチン接種',
        'date': '2026-07-12T00:00:00Z',
        'cost': 8000,
      },
      {
        'id': '2',
        'type': 'grooming',
        'label': 'トリミング(サマーカット)',
        'date': '2026-08-02T00:00:00Z',
        'cost': 6500,
      },
      {
        'id': '3',
        'type': 'vet',
        'label': '定期健診',
        'date': '2026-08-15T00:00:00Z',
        'cost': 4500,
      },
    ],
  },
  {
    'id': 'noa',
    'name': 'ノア',
    'breed': 'スタンダードプードル',
    'color': 'ブラック',
    'birthYear': 2022,
    'weightHistory': [
      {'month': '3月', 'kg': 22.1},
      {'month': '4月', 'kg': 22.3},
      {'month': '5月', 'kg': 22.6},
      {'month': '6月', 'kg': 22.4},
      {'month': '7月', 'kg': 22.8},
      {'month': '8月', 'kg': 23.0},
    ],
    'records': [
      {
        'id': '1',
        'type': 'grooming',
        'label': 'トリミング(全身カット)',
        'date': '2026-08-05T00:00:00Z',
        'cost': 7000,
      },
      {
        'id': '2',
        'type': 'vaccine',
        'label': '狂犬病予防接種',
        'date': '2026-06-20T00:00:00Z',
        'cost': 3500,
      },
    ],
  },
];

// dogId -> 散歩記録のリスト。プロセスを再起動すると消える簡易ストレージ。
final _walks = <String, List<Map<String, dynamic>>>{};

// dogId -> 今後の予定のリスト。
final _upcoming = <String, List<Map<String, dynamic>>>{
  'leo': [
    {
      'id': '1',
      'dogId': 'leo',
      'type': 'grooming',
      'label': '次回トリミング予約',
      'date': '2026-09-01T00:00:00Z',
    },
    {
      'id': '3',
      'dogId': 'leo',
      'type': 'vet',
      'label': '定期健診フォローアップ',
      'date': '2026-09-10T00:00:00Z',
    },
  ],
  'noa': [
    {
      'id': '2',
      'dogId': 'noa',
      'type': 'medication',
      'label': 'フィラリア予防投薬',
      'date': '2026-08-28T00:00:00Z',
    },
  ],
};

final _aiResults = [
  {
    'level': 'normal',
    'title': '特に気になる所見はありません',
    'detail': '被毛のツヤ・皮膚の赤みともに正常範囲内に見えます。',
  },
  {
    'level': 'watch',
    'title': '軽度の乾燥が見られます',
    'detail': '被毛の一部にパサつきが見られます。1週間ほど様子を見てください。',
  },
  {
    'level': 'concern',
    'title': '赤み・脱毛が疑われます',
    'detail': '皮膚の赤みと部分的な脱毛のような所見が見られます。動物病院での診察をおすすめします。',
  },
];

final _gaitResults = [
  {
    'level': 'normal',
    'title': '歩き方に気になる点はありません',
    'detail': '左右のバランスよく歩けており、足を引きずるような様子は見られません。',
  },
  {
    'level': 'watch',
    'title': 'わずかな歩様の左右差が見られます',
    'detail': '片側の足の着地がやや弱いように見えます。運動後に様子を見て、続くようなら相談してください。',
  },
  {
    'level': 'concern',
    'title': '足を引きずるような動きが見られます',
    'detail': '歩行時に片足をかばうような動きが見られます。関節や足裏の痛みの可能性があるため、早めに動物病院での診察をおすすめします。',
  },
];

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('mock dogapp-api listening on http://localhost:8080');

  await for (final req in server) {
    _addCorsHeaders(req.response);
    if (req.method == 'OPTIONS') {
      req.response.statusCode = 204;
      await req.response.close();
      continue;
    }
    try {
      await _handle(req);
    } catch (e) {
      req.response.statusCode = 500;
      req.response.write(jsonEncode({'error': '$e'}));
      await req.response.close();
    }
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers
      .add('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
  response.headers
      .add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

/// 本物のdogapp-apiと違い、JWTの中身は検証しない
/// (Authorizationヘッダーが付いていればログイン済み扱い)。
/// ローカルでの疎通確認用モックなので、ここでは「未ログイン状態を再現できる」
/// ことだけを目的にしている。
bool _authorized(HttpRequest req) {
  final header = req.headers.value('Authorization');
  return header != null && header.startsWith('Bearer ') && header.length > 7;
}

Future<void> _reject401(HttpRequest req) async {
  req.response.statusCode = 401;
  req.response.write(jsonEncode({'error': 'missing or invalid Authorization header'}));
  await req.response.close();
}

Future<void> _handle(HttpRequest req) async {
  final segments = req.uri.pathSegments;
  req.response.headers.contentType = ContentType.json;

  // POST /auth/signup, POST /auth/login
  if (req.method == 'POST' &&
      segments.length == 2 &&
      segments[0] == 'auth' &&
      (segments[1] == 'signup' || segments[1] == 'login')) {
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final email = body['email'] as String? ?? '';
    req.response.statusCode = segments[1] == 'signup' ? 201 : 200;
    req.response.write(jsonEncode({
      'token': 'mock-token-for-$email',
      'user': {'id': 'mock-user', 'email': email},
    }));
    await req.response.close();
    return;
  }

  // GET /dogs
  if (req.method == 'GET' && segments.length == 1 && segments[0] == 'dogs') {
    if (!_authorized(req)) return _reject401(req);
    req.response.write(jsonEncode(_dogs));
    await req.response.close();
    return;
  }

  // POST /dogs
  if (req.method == 'POST' && segments.length == 1 && segments[0] == 'dogs') {
    if (!_authorized(req)) return _reject401(req);
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final dog = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': body['name'],
      'breed': body['breed'],
      'color': body['color'],
      'birthYear': body['birthYear'],
      'weightHistory': [],
      'records': [],
    };
    _dogs.add(dog);
    req.response.statusCode = 201;
    req.response.write(jsonEncode(dog));
    await req.response.close();
    return;
  }

  // PATCH /dogs/{dogId}
  if (req.method == 'PATCH' && segments.length == 2 && segments[0] == 'dogs') {
    if (!_authorized(req)) return _reject401(req);
    final dogId = segments[1];
    final dog = _dogs.firstWhere((d) => d['id'] == dogId, orElse: () => {});
    if (dog.isEmpty) {
      req.response.statusCode = 404;
      req.response.write(jsonEncode({'error': 'dog not found: $dogId'}));
      await req.response.close();
      return;
    }
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    dog['name'] = body['name'];
    dog['breed'] = body['breed'];
    dog['color'] = body['color'];
    dog['birthYear'] = body['birthYear'];
    req.response.write(jsonEncode(dog));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/weight
  if (req.method == 'POST' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'weight') {
    if (!_authorized(req)) return _reject401(req);
    final dogId = segments[1];
    final dog = _dogs.firstWhere((d) => d['id'] == dogId, orElse: () => {});
    if (dog.isEmpty) {
      req.response.statusCode = 404;
      req.response.write(jsonEncode({'error': 'dog not found: $dogId'}));
      await req.response.close();
      return;
    }
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final entry = {'month': body['month'], 'kg': body['kg']};
    // 既存の体重リストは(シードデータ由来で)Map<String, Object>としか
    // 互換性がない場合があるため、.add()で直接足さず新しいリストで置き換える。
    dog['weightHistory'] = [...(dog['weightHistory'] as List), entry];
    req.response.statusCode = 201;
    req.response.write(jsonEncode(entry));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/ai-check
  if (req.method == 'POST' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'ai-check') {
    if (!_authorized(req)) return _reject401(req);
    await utf8.decoder.bind(req).join(); // ボディは読み捨てる(モックのため)
    await Future.delayed(const Duration(milliseconds: 800));
    final result = _aiResults[Random().nextInt(_aiResults.length)];
    req.response.write(jsonEncode(result));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/gait-check (multipart/form-data、動画ファイル1つ)
  if (req.method == 'POST' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'gait-check') {
    if (!_authorized(req)) return _reject401(req);
    await req.drain(); // 動画バイト列はUTF-8ではないのでdecodeせず読み捨てる
    await Future.delayed(const Duration(milliseconds: 1000));
    final result = _gaitResults[Random().nextInt(_gaitResults.length)];
    req.response.write(jsonEncode(result));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/records
  if (req.method == 'POST' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'records') {
    if (!_authorized(req)) return _reject401(req);
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final record = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': body['type'],
      'label': body['label'],
      'date': DateTime.now().toIso8601String(),
      if (body['cost'] != null) 'cost': body['cost'],
    };
    req.response.write(jsonEncode(record));
    await req.response.close();
    return;
  }

  // GET /dogs/{dogId}/walks
  if (req.method == 'GET' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'walks') {
    if (!_authorized(req)) return _reject401(req);
    final dogId = segments[1];
    req.response.write(jsonEncode(_walks[dogId] ?? []));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/walks
  if (req.method == 'POST' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'walks') {
    if (!_authorized(req)) return _reject401(req);
    final dogId = segments[1];
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final walk = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'dogId': dogId,
      'startedAt': body['startedAt'],
      'durationSeconds': body['durationSeconds'],
      'distanceMeters': body['distanceMeters'],
      'points': body['points'],
    };
    _walks.putIfAbsent(dogId, () => []).insert(0, walk);
    req.response.write(jsonEncode(walk));
    await req.response.close();
    return;
  }

  // GET /upcoming
  if (req.method == 'GET' &&
      segments.length == 1 &&
      segments[0] == 'upcoming') {
    if (!_authorized(req)) return _reject401(req);
    final all = _upcoming.values.expand((e) => e).toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    req.response.write(jsonEncode(all));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/upcoming
  if (req.method == 'POST' &&
      segments.length == 3 &&
      segments[0] == 'dogs' &&
      segments[2] == 'upcoming') {
    if (!_authorized(req)) return _reject401(req);
    final dogId = segments[1];
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'dogId': dogId,
      'type': body['type'],
      'label': body['label'],
      'date': body['date'],
    };
    _upcoming.putIfAbsent(dogId, () => []).add(item);
    req.response.write(jsonEncode(item));
    await req.response.close();
    return;
  }

  req.response.statusCode = 404;
  req.response.write(jsonEncode({'error': 'not found'}));
  await req.response.close();
}
