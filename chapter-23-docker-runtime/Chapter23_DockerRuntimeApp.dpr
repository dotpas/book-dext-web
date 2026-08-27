program Chapter23_DockerRuntimeApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces;

procedure RunDockerRuntimeServer;
var
  App: IWebApplication;
  Env: string;
begin
  Writeln('================================================================');
  Writeln('  Dext Chapter 23: Containers, Docker & Production Runtime      ');
  Writeln('================================================================');

  Env := GetEnvironmentVariable('DEXT_ENVIRONMENT');
  if Env = '' then
    Env := 'Production';

  Writeln(Format('[RUNTIME] Ambiente: %s', [Env]));

  App := WebApplication;

  // 1. Healthcheck de Liveness para Docker/K8s
  App.Builder.MapGet('/healthz/live',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Healthy","runtime":"Linux64/Docker"}');
    end);

  // 2. Healthcheck de Readiness para Docker/K8s
  App.Builder.MapGet('/healthz/ready',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json('{"status":"Ready","database":"Connected","cache":"Connected"}');
    end);

  // 3. Endpoint da API de Faturamento
  App.Builder.MapGet('/api/v1/info',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Status(200).Json(Format('{"app":"Dext Faturamento","environment":"%s","version":"1.0.0"}', [Env]));
    end);

  Writeln('[SERVER] Servidor conteinerizavel ativo em http://localhost:8080');
  App.Run(8080);
end;

begin
  try
    RunDockerRuntimeServer;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
