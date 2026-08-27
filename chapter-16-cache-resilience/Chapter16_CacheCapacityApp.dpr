program Chapter16_CacheCapacityApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces,
  RateLimiterService in 'RateLimiterService.pas';

var
  Limiter: TSimpleRateLimiter;
  CachedSummaryJson: string;
  CacheHitCount: Integer;

procedure RunCacheCapacityServer;
var
  App: IWebApplication;
begin
  Writeln('================================================================');
  Writeln('  Dext Chapter 16: Cache, Compression & Rate Limiting Server     ');
  Writeln('================================================================');

  Limiter := TSimpleRateLimiter.Create(5); // Limite de 5 chamadas rápidas
  CachedSummaryJson := '';
  CacheHitCount := 0;

  try
    App := WebApplication;

    // 1. Endpoint com Rate Limiting Defensivo (429 Too Many Requests)
    App.Builder.MapGet('/api/v1/faturas/resumo',
      procedure(Ctx: IHttpContext)
      begin
        if not Limiter.TryAcquire then
        begin
          Ctx.Response.Headers['Retry-After'] := '30';
          Ctx.Response.Headers['X-RateLimit-Limit'] := '5';
          Ctx.Response.Headers['X-RateLimit-Remaining'] := '0';
          Ctx.Response.Status(429).Json('{"error":"Too Many Requests - Limite excedido."}');
          Exit;
        end;

        // 2. Simulação de Cache Hit vs Cache Miss
        if CachedSummaryJson = '' then
        begin
          // Cache Miss: calcula e salva em cache
          CachedSummaryJson := '{"totalFaturas": 1420, "valorTotal": 854000.50, "cache": "MISS"}';
          Ctx.Response.Headers['X-Cache'] := 'MISS';
          Ctx.Response.Status(200).Json(CachedSummaryJson);
        end
        else
        begin
          // Cache Hit: retorna imediatamente do cache
          Inc(CacheHitCount);
          Ctx.Response.Headers['X-Cache'] := 'HIT';
          Ctx.Response.Status(200).Json(Format('{"totalFaturas": 1420, "valorTotal": 854000.50, "cache": "HIT", "hitCount": %d}', [CacheHitCount]));
        end;
      end);

    // 3. Endpoint de Flush de Cache
    App.Builder.MapPost('/api/v1/cache/flush',
      procedure(Ctx: IHttpContext)
      begin
        CachedSummaryJson := '';
        CacheHitCount := 0;
        Limiter.Reset;
        Ctx.Response.Status(200).Json('{"status":"cache_cleared_and_rate_reset"}');
      end);

    Writeln('[SERVER] Servidor de Cache e Capacidade ativo em http://localhost:8080');
    App.Run(8080);
  finally
    Limiter.Free;
  end;
end;

begin
  try
    RunCacheCapacityServer;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
