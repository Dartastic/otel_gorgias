// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_gorgias/otel_gorgias.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_gorgias-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('tickets.create records channel + auto_responded + revenue', () async {
    await tracedGorgias<String>(
      operation: 'tickets.create',
      invoke: () async => const GorgiasCallResult(
        value: 'ok',
        result: GorgiasResult(
          channel: 'email',
          status: 'open',
          priority: 'normal',
          autoRespondedBy: 'ai_agent',
          integrationKind: 'shopify',
          orderRevenueMinor: 12500,
          currency: 'USD',
          rateLimitRemaining: 40,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('gorgias tickets.create')!);
    expect(a['gorgias.channel'], 'email');
    expect(a['gorgias.auto_responded_by'], 'ai_agent');
    expect(a['gorgias.integration.kind'], 'shopify');
    expect(a['gorgias.order.revenue.minor'], 12500);
    expect(a['gorgias.rate_limit.remaining'], 40);
  });

  test('suppression skips spans', () async {
    await runWithoutGorgiasInstrumentationAsync(() async {
      await tracedGorgias<String>(
        operation: 'tickets.list',
        invoke: () async => const GorgiasCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('gorgias '), isEmpty);
  });
}
