program Chapter20_RealtimeApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Rtti,
  System.SyncObjs,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Hubs,
  Dext.Web.Hubs.Interfaces,
  Dext.Web.Hubs.Extensions,
  NotificationsHub in 'NotificationsHub.pas';

var
  Counter: Integer = 100;
  CachedHtml: string = '';

type
  TTenantAuthenticationMiddleware = class(TMiddleware)
  public
    procedure Invoke(Ctx: IHttpContext; ANext: TRequestDelegate); override;
  end;

procedure TTenantAuthenticationMiddleware.Invoke(
  Ctx: IHttpContext; ANext: TRequestDelegate);
var
  Authorization, Token, TenantId: string;
begin
  Authorization := Ctx.Request.GetHeader('Authorization');
  if Authorization.StartsWith('Bearer ', True) then
    Token := Authorization.Substring(7)
  else
    Token := '';

  TenantId := '';
  if (Token <> '') and
     (Token = GetEnvironmentVariable('DEXT_DEMO_TENANT_ALPHA_TOKEN')) then
    TenantId := 'tenant_alpha'
  else if (Token <> '') and
          (Token = GetEnvironmentVariable('DEXT_DEMO_TENANT_BETA_TOKEN')) then
    TenantId := 'tenant_beta';

  if TenantId <> '' then
    Ctx.Items.AddOrSetValue('tenant_id', TValue.From<string>(TenantId));

  ANext(Ctx);
end;

begin
  try
    Writeln('====================================================================');
    Writeln('  Dext Server-Driven UI (SSR, HTMX) & WebSockets Server - Cap 13   ');
    Writeln('====================================================================');

    // 0. Cache do HTML em memória no Startup para evitar I/O síncrono por requisição
    var HtmlPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'wwwroot\index.html');
    if not TFile.Exists(HtmlPath) then
      HtmlPath := TPath.Combine(GetCurrentDir, 'wwwroot\index.html');

    if TFile.Exists(HtmlPath) then
      CachedHtml := TFile.ReadAllText(HtmlPath, TEncoding.UTF8);

    var App := WebApplication;
    App.Builder.UseMiddleware(TTenantAuthenticationMiddleware);

    // 1. Rota Raiz: Servir a página interativa wwwroot/index.html (da memória)
    App.Builder.MapGet('/',
      procedure(Ctx: IHttpContext)
      begin
        if CachedHtml <> '' then
        begin
          Ctx.Response.SetContentType('text/html; charset=utf-8');
          Ctx.Response.Write(CachedHtml);
        end
        else
        begin
          Ctx.Response.SetStatusCode(404);
          Ctx.Response.Write('wwwroot/index.html nao encontrado.');
        end;
      end);

    // 2. SSR & HTMX Partial HTML Fragment Endpoint (Thread-Safe via TInterlocked)
    App.Builder.MapGet('/htmx/update-invoice',
      procedure(Ctx: IHttpContext)
      var
        CurrentValue: Integer;
      begin
        CurrentValue := TInterlocked.Increment(Counter);
        Ctx.Response.SetContentType('text/html; charset=utf-8');
        Ctx.Response.Write(Format(
          '<div id="ss-target" class="badge">✅ Fatura INV-%d Atualizada via HTMX (Total: R$ %d,00)</div>',
          [CurrentValue, CurrentValue * 25]));
      end);

    // 3. Mapear WebSockets Hub de Notificacoes
    MapHub(App.Builder, '/hubs/notifications', TNotificationsHub);

    // 4. API Endpoint para disparar Notificação Broadcast via IHubContext real do Framework
    App.Builder.MapPost('/api/v1/trigger-notification',
      procedure(Ctx: IHttpContext)
      var
        HubContext: IHubContext;
        CurrentValue: Integer;
        Msg: string;
      begin
        CurrentValue := TInterlocked.Increment(Counter);
        Msg := Format('⚡ Notificacao em Tempo Real: Fatura INV-%d gerada com sucesso!', [CurrentValue]);

        HubContext := THubExtensions.GetHubContext;
        if HubContext = nil then
        begin
          Ctx.Response.Status(503).Json('{"status":"error","message":"IHubContext indisponivel ou WebSocket Hub nao registrado."}');
          Exit;
        end;

        HubContext.Clients.All.SendAsync('OnNotification', Msg);
        Writeln('    [WEBSOCKET] Mensagem broadcast transmitida aos clientes conectados: ', Msg);

        Ctx.Response.Json(Format(
          '{"status":"success","message":"Notificacao broadcast enviada via IHubContext do WebSocket Hub para INV-%d"}',
          [CurrentValue]));
      end);

    // 5. API Endpoint para disparar Notificação Segmentada por Tenant (Tenant Grouping via Header Autenticado)
    App.Builder.MapPost('/api/v1/trigger-tenant-notification',
      procedure(Ctx: IHttpContext)
      var
        HubContext: IHubContext;
        TenantId, Msg: string;
      begin
        // O middleware deriva o tenant de um Bearer token validado.
        TenantId := '';
        if Ctx.Items.ContainsKey('tenant_id') then
          TenantId := Ctx.Items['tenant_id'].AsString;
        if TenantId = '' then
        begin
          Ctx.Response.Status(401).Json('{"status":"error","code":401,"message":"Acesso negado: Bearer token de tenant ausente ou invalido."}');
          Exit;
        end;

        Msg := Format('🔒 Notificação Segmentada para Tenant [%s]: Alerta de faturamento exclusivo.', [TenantId]);

        HubContext := THubExtensions.GetHubContext;
        if HubContext <> nil then
        begin
          HubContext.Clients.Group(TenantId).SendAsync('OnNotification', Msg);
          Writeln('    [WEBSOCKET] Mensagem segmentada enviada ao grupo do tenant: ', TenantId);
        end;

        Ctx.Response.Json(Format(
          '{"status":"success","tenant":"%s","message":"Notificacao enviada ao grupo do tenant com sucesso"}',
          [TenantId]));
      end);

    Writeln('[SERVER] Servidor Frontend & Real-time ativo em http://localhost:8080');
    Writeln('[SERVER] Abra http://localhost:8080 no seu navegador para testar HTMX e WebSockets!');

    App.Run(8080);
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
