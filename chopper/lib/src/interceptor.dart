import 'dart:async';
import "package:meta/meta.dart";

import 'request.dart';
import 'response.dart';
import 'utils.dart';

@immutable
abstract class ResponseInterceptor {
  FutureOr<Response> onResponse(Response response);
}

@immutable
abstract class RequestInterceptor {
  FutureOr<Request> onRequest(Request request);
}

@immutable
abstract class Converter {
  FutureOr<Request> encode<T>(Request request) async {
    if (request.body != null) {
      return request.replace(body: await encodeEntity<T>(request.body));
    } else if (request.parts.isNotEmpty) {
      final parts = new List(request.parts.length);
      final futures = <Future>[];

      for (int i = 0; i < parts.length; i++) {
        final p = request.parts[i];
        futures.add(encodeEntity(p.value).then((e) {
          parts[i] = PartValue(p.name, e);
        }));
      }

      await Future.wait(futures);
      return request.replace(parts: parts);
    }
    return request;
  }

  Future<Response<T>> decode<T>(Response response) async {
    if (response.body != null) {
      final decoded = await decodeEntity<T>(response.body);
      return response.replaceWithNull<T>(body: decoded);
    }
    return response.replaceWithNull<T>();
  }

  @protected
  Future encodeEntity<T>(T entity);

  @protected
  Future decodeEntity<T>(entity);
}

@immutable
class HeadersInterceptor implements RequestInterceptor {
  final Map<String, String> headers;

  const HeadersInterceptor(this.headers);

  Future<Request> onRequest(Request request) async =>
      applyHeaders(request, headers);
}

typedef FutureOr<Response> ResponseInterceptorFunc<Value>(
    Response<Value> response);
typedef FutureOr<Request> RequestInterceptorFunc(Request request);
