// dogapp-api の代わりに動作確認するための簡易モックサーバー。
// 実際のdogapp-api(Go実装)とは別物で、開発時の疎通確認専用。
//
// 実行: dart run tool/mock_server.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

final _dogs = [
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
      {'id': '1', 'type': 'vaccine', 'label': '混合ワクチン接種', 'date': '2026-07-12T00:00:00Z'},
      {'id': '2', 'type': 'grooming', 'label': 'トリミング(サマーカット)', 'date': '2026-08-02T00:00:00Z'},
      {'id': '3', 'type': 'vet', 'label': '定期健診', 'date': '2026-08-15T00:00:00Z'},
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
      {'id': '1', 'type': 'grooming', 'label': 'トリミング(全身カット)', 'date': '2026-08-05T00:00:00Z'},
      {'id': '2', 'type': 'vaccine', 'label': '狂犬病予防接種', 'date': '2026-06-20T00:00:00Z'},
    ],
  },
];

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
  response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
}

Future<void> _handle(HttpRequest req) async {
  final segments = req.uri.pathSegments;
  req.response.headers.contentType = ContentType.json;

  // GET /owners/{ownerId}/dogs
  if (req.method == 'GET' && segments.length == 3 && segments[0] == 'owners' && segments[2] == 'dogs') {
    req.response.write(jsonEncode(_dogs));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/ai-check
  if (req.method == 'POST' && segments.length == 3 && segments[0] == 'dogs' && segments[2] == 'ai-check') {
    await utf8.decoder.bind(req).join(); // ボディは読み捨てる(モックのため)
    await Future.delayed(const Duration(milliseconds: 800));
    final result = _aiResults[Random().nextInt(_aiResults.length)];
    req.response.write(jsonEncode(result));
    await req.response.close();
    return;
  }

  // POST /dogs/{dogId}/records
  if (req.method == 'POST' && segments.length == 3 && segments[0] == 'dogs' && segments[2] == 'records') {
    final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final record = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': body['type'],
      'label': body['label'],
      'date': DateTime.now().toIso8601String(),
    };
    req.response.write(jsonEncode(record));
    await req.response.close();
    return;
  }

  req.response.statusCode = 404;
  req.response.write(jsonEncode({'error': 'not found'}));
  await req.response.close();
}
