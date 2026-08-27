program Lab03_SecureMultiTenant;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Auth.JWT,
  Dext.Auth.Identity,
  Dext.Auth.Middleware,
  Lab03Security in 'Lab03Security.pas';

procedure RunLab03Server;
var
  App: IWebApplication;
  JwtHandler: TJwtTokenHandler;
begin
  Writeln('================================================================');
  Writeln('  Lab 03: Secure Multi-Tenant CQRS Platform Server              ');
  Writeln('================================================================');

  JwtHandler := TJwtTokenHandler.Create(
    JwtOptions('SuperSecretKeyForLab03SecureMultiTenant2026!')
      .ExpirationMinutes(60));
  try
    App := WebApplication;

    // 1. Autenticação JWT
    App.Builder.UseJwtAuthentication(
      JwtOptions('SuperSecretKeyForLab03SecureMultiTenant2026!')
        .ExpirationMinutes(60));

    // 2. Token de Autenticação com Tenant e Alçadas
    App.Builder.MapPost('/api/v1/auth/token',
      procedure(Ctx: IHttpContext)
      var
        Perfil, Tenant, Token: string;
        Claims: TArray<TClaim>;
      begin
        Perfil := Ctx.Request.Query['perfil'];
        Tenant := Ctx.Request.Query['tenant'];
        if Perfil = '' then Perfil := 'operador';
        if Tenant = '' then Tenant := 'tenant-alfa';

        if Perfil = 'diretoria' then
        begin
          SetLength(Claims, 4);
          Claims[0] := TClaim.Create('sub', 'diretor_lab');
          Claims[1] := TClaim.Create('role', 'Diretoria');
          Claims[2] := TClaim.Create('tenant_id', Tenant);
          Claims[3] := TClaim.Create('alcada_maxima', '50000.00');
        end
        else
        begin
          SetLength(Claims, 4);
          Claims[0] := TClaim.Create('sub', 'operador_lab');
          Claims[1] := TClaim.Create('role', 'Operador');
          Claims[2] := TClaim.Create('tenant_id', Tenant);
          Claims[3] := TClaim.Create('alcada_maxima', '1000.00');
        end;

        Token := JwtHandler.GenerateToken(Claims);
        Ctx.Response.Status(200).Json(Format('{"token":"%s","perfil":"%s","tenant":"%s"}',
          [Token, Perfil, Tenant]));
      end);

    // 3. Consulta de Faturas por Tenant (Exige autenticação)
    App.Builder.MapGet('/api/v1/faturas',
      procedure(Ctx: IHttpContext)
      var
        TenantId: string;
      begin
        if (Ctx.User = nil) or (not Ctx.User.Identity.IsAuthenticated) then
        begin
          Ctx.Response.Status(401).Json('{"error":"Nao autenticado"}');
          Exit;
        end;

        TenantId := TLab03SecurityHelper.GetTenant(Ctx.User);
        Ctx.Response.Status(200).Json(Format('{"tenant":"%s","faturas":[{"id":105,"valor":15000.00,"status":"EMITIDA"}]}',
          [TenantId]));
      end);

    // 4. Cancelamento de Fatura com Alçada (Distinção 401 vs 403)
    App.Builder.MapDelete('/api/v1/faturas/{id}',
      procedure(Ctx: IHttpContext)
      begin
        if (Ctx.User = nil) or (not Ctx.User.Identity.IsAuthenticated) then
        begin
          Ctx.Response.Status(401).Json('{"error":"Nao autenticado"}');
          Exit;
        end;

        if not TLab03SecurityHelper.HasAlcada(Ctx.User, 10000.00) then
        begin
          Ctx.Response.Status(403).Json('{"error":"Acesso proibido: Alcada insuficiente para cancelamento critico."}');
          Exit;
        end;

        Ctx.Response.StatusCode := 204;
      end);

    Writeln('[SERVER] Servidor Lab 03 ativo em http://localhost:8080');
    App.Run(8080);
  finally
    JwtHandler.Free;
  end;
end;

begin
  try
    RunLab03Server;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
