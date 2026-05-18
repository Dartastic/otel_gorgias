// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_gorgias_suppression.dart';

const _tracerName = 'dartastic_otel_libs_gorgias';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class GorgiasResult {
  const GorgiasResult({
    this.itemCount,
    this.total,
    this.channel,
    this.status,
    this.priority,
    this.autoRespondedBy,
    this.integrationKind,
    this.orderRevenueMinor,
    this.currency,
    this.rateLimitRemaining,
    this.requestId,
    this.statusCode,
  });

  /// `data.length`.
  final int? itemCount;

  /// `meta.total_count`.
  final int? total;

  /// `email` / `chat` / `sms` / `facebook` / `instagram` / `whatsapp`
  /// / `phone` / `api`.
  final String? channel;

  /// `open` / `closed` / `spam` / `merged`.
  final String? status;

  /// `low` / `normal` / `urgent`.
  final String? priority;

  /// `rule` / `macro` / `ai_agent` / `human` — Gorgias auto-resolution
  /// attribution dim.
  final String? autoRespondedBy;

  /// `shopify` / `magento` / `bigcommerce` / `klaviyo` / `recharge`
  /// — Gorgias attaches ecommerce context to tickets.
  final String? integrationKind;

  /// Revenue associated with the ticket (orders auto-linked from
  /// Shopify), minor units. Powers Gorgias's revenue-per-ticket KPI.
  final int? orderRevenueMinor;

  /// ISO 4217.
  final String? currency;

  /// `X-RateLimit-Remaining`.
  final int? rateLimitRemaining;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class GorgiasCallResult<T> {
  const GorgiasCallResult({required this.value, this.result});
  final T value;
  final GorgiasResult? result;
}

/// Wraps a Gorgias API call in a CLIENT span. [operation] is one of
/// `tickets.list`, `tickets.get`, `tickets.create`, `tickets.update`,
/// `tickets.messages.list`, `tickets.messages.create`,
/// `customers.list`, `customers.get`, `customers.update`,
/// `integrations.list`, `macros.list`, `macros.run`,
/// `statistics.tickets`, `views.list`, `webhooks.list`,
/// `webhooks.create`.
Future<T> tracedGorgias<T>({
  required String operation,
  required Future<GorgiasCallResult<T>> Function() invoke,
}) async {
  if (gorgiasInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'gorgias',
    'rpc.method': operation,
    'gorgias.operation': operation,
  };

  final span = _tracer().startSpan(
    'gorgias $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'gorgias.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.total != null) {
        extras.add(OTel.attributeInt(
          'gorgias.total',
          r.result!.total!,
        ));
      }
      if (r.result!.channel != null) {
        extras.add(OTel.attributeString(
          'gorgias.channel',
          r.result!.channel!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTel.attributeString(
          'gorgias.ticket.status',
          r.result!.status!,
        ));
      }
      if (r.result!.priority != null) {
        extras.add(OTel.attributeString(
          'gorgias.ticket.priority',
          r.result!.priority!,
        ));
      }
      if (r.result!.autoRespondedBy != null) {
        extras.add(OTel.attributeString(
          'gorgias.auto_responded_by',
          r.result!.autoRespondedBy!,
        ));
      }
      if (r.result!.integrationKind != null) {
        extras.add(OTel.attributeString(
          'gorgias.integration.kind',
          r.result!.integrationKind!,
        ));
      }
      if (r.result!.orderRevenueMinor != null) {
        extras.add(OTel.attributeInt(
          'gorgias.order.revenue.minor',
          r.result!.orderRevenueMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'gorgias.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'gorgias.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'gorgias.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Gorgias HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
