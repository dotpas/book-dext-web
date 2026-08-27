program Chapter15_AuthorizationApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Auth.JWT,
  Dext.Auth.Identity,
  Dext.Auth.Middleware,
  AuthorizationPolicies in 'AuthorizationPolicies.pas';

procedure RunAuthorizationServer;
var
  App: IWebApplication;
  JwtHandler: TJwtTokenHandler;
begin
  Writeln('================================================================');
  Writeln('  Dext Chapter 15: Policy-Based Authorization & Claims Server   ');
  Writeln('================================================================');

  JwtHandler := TJwtTokenHandler.Create(
    JwtOptions('SuperSecretKeyForChapter15AuthValidation2026!')
      .ExpirationMinutes(60));
  try
    App := WebApplication;

    // 1. Middleware de Autenticação JWT
    App.Builder.UseJwtAuthentication(
      JwtOptions('SuperSecretKeyForChapter15AuthValidation2026!')
        .ExpirationMinutes(60));

    // 2. Endpoint de Emissão de Tokens com Perfis e Alçadas
    App.Builder.MapPost('/api/v1/auth/token',
      procedure(Ctx: IHttpContext)
      var
        Perfil, Token: string;
        Claims: TArray<TClaim>;
      begin
        Perfil := Ctx.Request.Query['perfil'];
        if Perfil = '' then
          Perfil := 'operador';

        if Perfil = 'diretoria' then
        begin
          SetLength(Claims, 3);
          Claims[0] := TClaim.Create('sub', 'diretor_carlos');
          Claims[1] := TClaim.Create('role', 'Diretoria');
          Claims[2] := TClaim.Create('alcada_maxima', '50000.00');
        end
        else
        begin
          SetLength(Claims, 3);
          Claims[0] := TClaim.Create('sub', 'operador_joao');
          Claims[1] := TClaim.Create('role', 'Operador');
          Claims[2] := TClaim.Create('alcada_maxima', '1000.00');
        end;

        Token := JwtHandler.GenerateToken(Claims);
        Ctx.Response.Status(200).Json(Format('{"token":"%s","perfil":"%s"}', [Token, Perfil]));
      end);

    // 3. Rota Geral (Exige autenticação)
    App.Builder.MapGet('/api/v1/faturas',
      procedure(Ctx: IHttpContext)
      begin
        if (Ctx.User = nil) or (not Ctx.User.Identity.IsAuthenticated) then
        begin
          Ctx.Response.Status(401).Json('{"error":"Nao autenticado"}');
          Exit;
        end;

        Ctx.Response.Status(200).Json('{"faturas":[{"id":105,"valor":15000.00,"status":"EMITIDA"}]}');
      end);

    // 4. Rota Crítica com Validação de Alçada e Perfil (Distinção 401 vs 403)
    App.Builder.MapDelete('/api/v1/faturas/{id}',
      procedure(Ctx: IHttpContext)
      begin
        if (Ctx.User = nil) or (not Ctx.User.Identity.IsAuthenticated) then
        begin
          Ctx.Response.Status(401).Json('{"error":"Nao autenticado"}');
          Exit;
        end;

        // Cancelamento crítico exige alçada >= R$ 10.000,00
        if not TAuthorizationHelper.HasAlcada(Ctx.User, 10000.00) then
        begin
          Ctx.Response.Status(403).Json('{"error":"Acesso proibido: Alcada insuficiente para cancelamento critico."}');
          Exit;
        end;

        // Sucesso na autorização -> 204 No Content
        Ctx.Response.StatusCode := 204;
      end);

    Writeln('[SERVER] Servidor de Autorização ativo em http://localhost:8080');
    App.Run(8080);
  finally
    JwtHandler.Free;
  end;
end;

begin
  try
    RunAuthorizationServer;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
