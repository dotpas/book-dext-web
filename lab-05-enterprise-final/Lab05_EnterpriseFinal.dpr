program Lab05_EnterpriseFinal;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces;

procedure RunLab05Server;
var
  App: IWebApplication;
begin
  Writeln('================================================================');
  Writeln('  Lab 05: Dext Enterprise Final Full-Stack Application          ');
  Writeln('================================================================');

  App := WebApplication;

  // 1. Rota customizada de liveness (o probe nativo do middleware e /health)
  App.Builder.MapGet('/healthz/live',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.StatusCode := 200;
      Ctx.Response.Json('{"status":"Healthy","app":"Dext Enterprise"}');
    end);

  // 2. API RESTful de Clientes & Faturamento
  App.Builder.MapGet('/api/v1/faturas',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.StatusCode := 200;
      Ctx.Response.Json(
        '{"total":1,"faturas":[{"id":101,"cliente":"Empresa Alpha","valor":3500.00,"status":"EMITIDA"}]}');
    end);

  // 3. Frontend Server-Side Rendering (HTML)
  App.Builder.MapGet('/',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.ContentType := 'text/html; charset=utf-8';
      Ctx.Response.Write(
        '<!DOCTYPE html>' +
        '<html lang="pt-BR">' +
        '<head><title>Dext Faturamento Enterprise</title></head>' +
        '<body>' +
        '<h1>Painel de Faturamento Dext</h1>' +
        '<p id="status-badge">Sistema Operacional em Producao</p>' +
        '</body>' +
        '</html>');
    end);

  Writeln('[SERVER] Servidor Enterprise Final ativo em http://localhost:8080');
  App.Run(8080);
end;

begin
  try
    RunLab05Server;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
