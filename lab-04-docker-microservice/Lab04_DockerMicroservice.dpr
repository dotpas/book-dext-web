program Lab04_DockerMicroservice;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces;

procedure RunLab04Server;
var
  App: IWebApplication;
begin
  Writeln('================================================================');
  Writeln('  Lab 04: Observable Containerized Microservice Server          ');
  Writeln('================================================================');

  App := WebApplication;

  // 1. Probes de Health Checks (nativos e aliases Kubernetes)
  App.Builder.MapGet('/health',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Healthy","checks":[{"name":"database","status":"Healthy"}]}');
    end);

  App.Builder.MapGet('/health/live',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Healthy","service":"FaturamentoMicroservice"}');
    end);

  App.Builder.MapGet('/healthz/live',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Healthy","service":"FaturamentoMicroservice"}');
    end);

  App.Builder.MapGet('/health/ready',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Ready","db_pool":"OK","redis_cache":"OK"}');
    end);

  App.Builder.MapGet('/healthz/ready',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Ready","db_pool":"OK","redis_cache":"OK"}');
    end);

  // 2. Contrato OpenAPI Swagger JSON
  App.Builder.MapGet('/swagger.json',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"openapi":"3.0.1","info":{"title":"Dext Faturamento Production API","version":"v1.0.0"}}');
    end);

  // 3. Endpoint de Métricas Prometheus
  App.Builder.MapGet('/metrics',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.ContentType := 'text/plain; version=0.0.4';
      Ctx.Response.Write(
        '# HELP http_requests_total Total number of HTTP requests' + sLineBreak +
        '# TYPE http_requests_total counter' + sLineBreak +
        'http_requests_total{method="GET",status="200"} 42' + sLineBreak +
        '# HELP faturas_emitidas_total Total de faturas emitidas' + sLineBreak +
        '# TYPE faturas_emitidas_total counter' + sLineBreak +
        'faturas_emitidas_total 128' + sLineBreak);
    end);

  // 4. API de Faturas
  App.Builder.MapGet('/api/v1/faturas',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"faturas":[{"id":1,"valor":1500.00,"status":"EMITIDA"}]}');
    end);

  Writeln('[SERVER] Servidor Lab 04 ativo em http://localhost:8080');
  App.Run(8080);
end;

begin
  try
    RunLab04Server;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
