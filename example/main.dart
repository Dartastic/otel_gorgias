// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_gorgias/otel_gorgias.dart';

/// Traces Gorgias calls with OpenTelemetry.
///
/// `otel_gorgias` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Gorgias call in
/// [tracedGorgias]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'gorgias-example');

  // Wraps a Gorgias API call in a CLIENT span.
  final gorgiasId = await tracedGorgias<String>(
    operation: 'tickets.create',
    invoke: () async {
      // Make the Gorgias call here, then report what it returned.
      const id = 'gorgias_8f3a2c';
      return const GorgiasCallResult(
          value: id,
          result: GorgiasResult(
              itemCount: 3,
              total: 1,
              channel: 'email',
              status: 'open',
              priority: 'low',
              autoRespondedBy: 'rule',
              integrationKind: 'shopify',
              orderRevenueMinor: 1,
              currency: 'usd',
              rateLimitRemaining: 25,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedGorgias tickets.create returned $gorgiasId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGorgiasInstrumentationAsync.
  await runWithoutGorgiasInstrumentationAsync(
    () => tracedGorgias<String>(
      operation: 'tickets.create',
      invoke: () async {
        const id = 'gorgias_8f3a2c';
        return const GorgiasCallResult(
            value: id,
            result: GorgiasResult(
                itemCount: 3,
                total: 1,
                channel: 'email',
                status: 'open',
                priority: 'low',
                autoRespondedBy: 'rule',
                integrationKind: 'shopify',
                orderRevenueMinor: 1,
                currency: 'usd',
                rateLimitRemaining: 25,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
