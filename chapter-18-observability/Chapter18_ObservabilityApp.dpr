program Chapter18_ObservabilityApp;

{$APPTYPE CONSOLE}

uses
  {$IFDEF USE_FASTMM5}
  FastMM5,
  {$ENDIF}
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.SyncObjs,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Configuration.Interfaces,
  Dext.Configuration.Core,
  Dext.Configuration.Yaml,
  Dext.Logging,
  HealthCheckServices in 'HealthCheckServices.pas';

procedure RunServer;
var
  Builder: IConfigurationBuilder;
  Config: IConfigurationRoot;
  App: IWebApplication;
  DbChecker: IDatabaseHealthCheck;
begin
  StartTime := Now;
  DbChecker := TDatabaseHealthCheck.Create;

  Writeln('====================================================================');
  Writeln('  Dext Hosting, Observability & Health Checks Server - Cap 18       ');
  Writeln('====================================================================');

  // 1. Carregar configuracao do appsettings.yaml
  var YamlPath := 'appsettings.yaml';
  if not FileExists(YamlPath) then
    YamlPath := ExtractFilePath(ParamStr(0)) + 'appsettings.yaml';

  Builder := TConfigurationBuilder.Create;
  Builder.Add(TYamlConfigurationSource.Create(YamlPath, False));
  Config := Builder.Build;

  Writeln('[CONFIG] Configuração de Observabilidade carregada:');
  Writeln('  - LogLevel: ', Config['Observability:LogLevel']);
  Writeln('  - EnableMetrics: ', Config['Observability:EnableMetrics']);

  App := WebApplication;

  // 2. Registrar Middleware de Métricas RED
  App.Builder.UseMiddleware(THostingMetricsMiddleware);

  // 3. Health Check: Liveness Probe (Kubernetes / Docker)
  App.Builder.MapGet('/health/live',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Json('{"status":"UP","probe":"liveness","uptime_seconds":' +
        IntToStr(Trunc((Now - StartTime) * 86400)) + '}');
    end);

  // 4. Health Check: Readiness Probe Real com Validação Ativa de Conectividade
  App.Builder.MapGet('/health/ready',
    procedure(Ctx: IHttpContext)
    var
      PingLatency: Integer;
      ErrorReason: string;
    begin
      if DbChecker.CheckHealth(1000, PingLatency, ErrorReason) then
      begin
        Ctx.Response.Status(200).Json(Format(
          '{"status":"READY","probe":"readiness","database":"connected","ping_latency_ms":%d}',
          [PingLatency]));
      end
      else
      begin
        Ctx.Response.Status(503).Json(Format(
          '{"status":"NOT_READY","probe":"readiness","database":"disconnected","reason":"%s"}',
          [ErrorReason]));
      end;
    end);

  // Endpoint de simulação de indisponibilidade de banco para validação de testes de infraestrutura (Restrito a Testes/Dev)
  App.Builder.MapPost('/health/toggle-db',
    procedure(Ctx: IHttpContext)
    var
      StateParam, TestKey: string;
      IsOnline: Boolean;
    begin
      TestKey := Ctx.Request.GetHeader('X-Infrastructure-Test-Key');
      if TestKey <> 'infra_test_secret_key' then
      begin
        Ctx.Response.Status(401).Json('{"status":"error","code":401,"message":"Acesso nao autorizado. Header X-Infrastructure-Test-Key invalido."}');
        Exit;
      end;

      StateParam := Ctx.Request.GetQueryParam('online');
      if StateParam = 'false' then
      begin
        TInterlocked.Exchange(DbOnlineState, 0);
        IsOnline := False;
      end
      else
      begin
        TInterlocked.Exchange(DbOnlineState, 1);
        IsOnline := True;
      end;

      Ctx.Response.Json(Format('{"status":"success","db_online":%s}', [BoolToStr(IsOnline, True)]));
    end);

  // 5. Métrica RED Telemetry Endpoint (Rate, Errors, Duration - Thread-Safe & Invariant Locale)
  App.Builder.MapGet('/metrics',
    procedure(Ctx: IHttpContext)
    var
      Reqs, Errs, DurMs, PeakDur: Int64;
      UptimeSec: Double;
      ReqRate, AvgDur, ErrPct: Double;
    begin
      Reqs := TInterlocked.Read(RequestCounter);
      Errs := TInterlocked.Read(ErrorCounter);
      DurMs := TInterlocked.Read(TotalDurationMs);
      PeakDur := TInterlocked.Read(MaxDurationMs);

      UptimeSec := (Now - StartTime) * 86400;
      if UptimeSec < 1.0 then UptimeSec := 1.0;

      ReqRate := Reqs / UptimeSec;

      if Reqs > 0 then
      begin
        AvgDur := DurMs / Reqs;
        ErrPct := (Errs / Reqs) * 100;
      end
      else
      begin
        AvgDur := 0;
        ErrPct := 0;
      end;

      Ctx.Response.Json(Format(
        '{"metrics":{"rate_req_per_sec":%.2f,"total_requests":%d,"total_errors":%d,"error_rate_pct":%.2f,"avg_duration_ms":%.2f,"max_duration_ms":%d}}',
        [ReqRate, Reqs, Errs, ErrPct, AvgDur, PeakDur], TFormatSettings.Invariant));
    end);

  // 6. Endpoint de Encerramento Limpo para Validação de FastMM / Memory Leaks
  App.Builder.MapPost('/admin/shutdown',
    procedure(Ctx: IHttpContext)
    var
      TestKey: string;
    begin
      TestKey := Ctx.Request.GetHeader('X-Infrastructure-Test-Key');
      if TestKey <> 'infra_test_secret_key' then
      begin
        Ctx.Response.Status(401).Json('{"status":"error","message":"Acesso nao autorizado."}');
        Exit;
      end;

      Ctx.Response.Json('{"status":"success","message":"Servidor encerrando de forma limpa para verificacao de memory leaks..."}');

      TThread.CreateAnonymousThread(
        procedure
        begin
          Sleep(200);
          App.Stop;
        end).Start;
    end);

  Writeln('[SERVER] Servidor de Observabilidade ativo em http://localhost:8080');
  Writeln('[SERVER] Endpoints de monitoramento:');
  Writeln('  - GET http://localhost:8080/health/live');
  Writeln('  - GET http://localhost:8080/health/ready');
  Writeln('  - GET http://localhost:8080/metrics');

  App.Run(8080);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    RunServer;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
