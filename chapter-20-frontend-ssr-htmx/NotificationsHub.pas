unit NotificationsHub;

interface

uses
  System.SysUtils,
  Dext.Hubs;

type
  TNotificationsHub = class(THub)
  public
    procedure OnConnectedAsync; override;
    procedure OnDisconnectedAsync(const Exception: Exception); override;
    procedure SendNotification(const AMessage: string);
  end;

implementation

procedure TNotificationsHub.OnConnectedAsync;
var
  TenantId: string;
begin
  inherited;
  TenantId := '';

  if Context <> nil then
  begin
    // 1. Tenta extrair das Claims do usuário autenticado na conexão WebSocket
    if (Context.User <> nil) and Context.User.HasClaim('tenant_id') then
      TenantId := Context.User.FindClaim('tenant_id').Value
    // 2. Tenta extrair das propriedades de escopo da conexão
    else if (Context.Items <> nil) and Context.Items.ContainsKey('tenant_id') then
      TenantId := Context.Items['tenant_id'].AsString;

    if TenantId = '' then
    begin
      Writeln(Format('[HUB SECURITY WARNING] Conexão %s sem claim/header de tenant. Rejeitada do agrupamento multi-tenant.', [Context.ConnectionId]));
      Exit;
    end;

    // Associa exclusivamente a conexão ao grupo do tenant autenticado
    Groups.AddToGroupAsync(Context.ConnectionId, TenantId);
    Writeln(Format('[HUB MULTI-TENANT] Conexão %s vinculada estritamente ao grupo do tenant [%s]', [Context.ConnectionId, TenantId]));
  end;
end;

procedure TNotificationsHub.OnDisconnectedAsync(const Exception: Exception);
var
  TenantId: string;
begin
  if Context <> nil then
  begin
    if (Context.User <> nil) and Context.User.HasClaim('tenant_id') then
      TenantId := Context.User.FindClaim('tenant_id').Value
    else if Context.Items.ContainsKey('tenant_id') then
      TenantId := Context.Items['tenant_id'].AsString;

    if TenantId <> '' then
      Groups.RemoveFromGroupAsync(Context.ConnectionId, TenantId);
  end;
  inherited;
end;

procedure TNotificationsHub.SendNotification(const AMessage: string);
begin
  Clients.All.SendAsync('OnNotification', AMessage);
end;

end.
