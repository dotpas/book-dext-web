program Chapter14_SecurityJwtApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Configuration.Interfaces,
  Dext.Configuration.Core,
  Dext.Configuration.Yaml,
  Dext.Auth.JWT,
  Dext.Auth.Identity,
  Dext.Auth.Middleware,
  DemoUserStore in 'DemoUserStore.pas';

procedure RunSecurityServer;
var
  Builder: IConfigurationBuilder;
  Config: IConfigurationRoot;
  SecretKey, Issuer, Audience: string;
  JwtHandler: TJwtTokenHandler;
  UserStore: IDemoUserStore;
  App: IWebApplication;
begin
  Writeln('================================================================');
  Writeln('  Dext Security, JWT & Route Authorization Server - Cap 14      ');
  Writeln('================================================================');

  UserStore := TDemoUserStore.Create;

  // 1. Carregar chave e opcoes do arquivo appsettings.yaml (fail-fast estrito)
  Builder := TConfigurationBuilder.Create;
  Builder.Add(TYamlConfigurationSource.Create('appsettings.yaml', True));
  Config := Builder.Build;

  SecretKey := Config['Security:JwtSecret'];
  if (SecretKey = '') or (SecretKey.Length < 32) then
    raise Exception.Create(
      'Configuracao de seguranca invalida: Security:JwtSecret e obrigatorio e deve conter no minimo 32 caracteres no appsettings.yaml.');

  Issuer := Config['Security:Issuer'];
  if Issuer = '' then
    Issuer := 'DextSecurityApp';

  Audience := Config['Security:Audience'];
  if Audience = '' then
    Audience := 'DextAPI';

  Writeln('[CONFIG] Configuração de Segurança carregada do YAML (Fail-Fast Validado):');
  Writeln('  - Issuer: ', Issuer);
  Writeln('  - Audience: ', Audience);

  JwtHandler := TJwtTokenHandler.Create(
    JwtOptions(SecretKey)
      .Issuer(Issuer)
      .Audience(Audience)
      .ExpirationMinutes(60));
  try
    App := WebApplication;

    // 2. Registrar Middleware de Autenticacao JWT
    App.Builder.UseJwtAuthentication(
      JwtOptions(SecretKey)
        .Issuer(Issuer)
        .Audience(Audience)
        .ExpirationMinutes(60));

    // 3. Endpoint publico de Login de Demonstracao (Lê JSON body POST de forma segura)
    App.Builder.MapPost('/api/v1/auth/login',
      procedure(Ctx: IHttpContext)
      var
        Username, Password, Role, Token, RawBody: string;
        Claims: TArray<TClaim>;
        ReqJson, JsonResponse: TJSONObject;
      begin
        Username := '';
        Password := '';

        // Leitura ESTRITA do Corpo JSON (POST Body). Senhas na URL (Query String) sao estritamente Proibidas.
        if (Ctx.Request.Body = nil) or (Ctx.Request.Body.Size = 0) then
        begin
          Ctx.Response.Status(400).Json('{"status":"error","code":400,"message":"Corpo da requisicao POST ausente. Envie payload JSON {\"username\": \"...\", \"password\": \"...\"}"}');
          Exit;
        end;

        var StreamString := TStringStream.Create('', TEncoding.UTF8);
        try
          Ctx.Request.Body.Position := 0;
          StreamString.CopyFrom(Ctx.Request.Body, Ctx.Request.Body.Size);
          RawBody := StreamString.DataString;
        finally
          StreamString.Free;
        end;

        try
          ReqJson := TJSONObject.ParseJSONValue(RawBody) as TJSONObject;
          if ReqJson = nil then
          begin
            Ctx.Response.Status(400).Json('{"status":"error","code":400,"message":"Sintaxe JSON invalida no corpo da requisicao POST."}');
            Exit;
          end;

          try
            if ReqJson.GetValue('username') <> nil then Username := ReqJson.GetValue('username').Value;
            if ReqJson.GetValue('password') <> nil then Password := ReqJson.GetValue('password').Value;
          finally
            ReqJson.Free;
          end;
        except
          Ctx.Response.Status(400).Json('{"status":"error","code":400,"message":"Falha ao decodificar JSON do corpo POST."}');
          Exit;
        end;

        // Validação defensiva via Repositório de Identidade (UserStore)
        if not UserStore.ValidateCredentials(Username, Password, Role) then
        begin
          Ctx.Response.Status(401).Json('{"status":"error","code":401,"message":"Credenciais invalidas. Usuarios de demonstracao: \"admin\" / \"AdminSecret2026!\" ou \"operador\" / \"OperatorPass123!\"."}');
          Exit;
        end;

        SetLength(Claims, 3);
        Claims[0] := TClaim.Create('sub', Username);
        Claims[1] := TClaim.Create('name', 'Usuario ' + Username);
        Claims[2] := TClaim.Create('role', Role);

        Token := JwtHandler.GenerateToken(Claims);

        // Serializacao JSON segura via TJSONObject (Escaping automatico)
        JsonResponse := TJSONObject.Create;
        try
          JsonResponse.AddPair('status', 'success');
          JsonResponse.AddPair('user', Username);
          JsonResponse.AddPair('role', Role);
          JsonResponse.AddPair('token', Token);

          Ctx.Response.Status(200).Json(JsonResponse.ToString);
        finally
          JsonResponse.Free;
        end;
      end);

    // 4. Rota protegida para usuarios autenticados (Exige JWT valido, senao 401)
    App.Builder.MapGet('/api/v1/protected/user',
      procedure(Ctx: IHttpContext)
      var
        JsonResponse: TJSONObject;
      begin
        if (Ctx.User = nil) or (not Ctx.User.Identity.IsAuthenticated) then
        begin
          Ctx.Response.Status(401).Json('{"status":"error","code":401,"message":"Nao autorizado: Token JWT ausente ou invalido."}');
          Exit;
        end;

        JsonResponse := TJSONObject.Create;
        try
          JsonResponse.AddPair('status', 'success');
          JsonResponse.AddPair('message', 'Acesso concedido a rota de usuario!');
          JsonResponse.AddPair('identity', Ctx.User.Identity.Name);

          Ctx.Response.Status(200).Json(JsonResponse.ToString);
        finally
          JsonResponse.Free;
        end;
      end);

    // 5. Rota protegida exclusiva para Role Admin (Exige Role admin, senao 403)
    App.Builder.MapGet('/api/v1/protected/admin',
      procedure(Ctx: IHttpContext)
      begin
        if (Ctx.User = nil) or (not Ctx.User.Identity.IsAuthenticated) then
        begin
          Ctx.Response.Status(401).Json('{"status":"error","code":401,"message":"Nao autorizado: Token JWT ausente."}');
          Exit;
        end;

        if not Ctx.User.IsInRole('admin') then
        begin
          Ctx.Response.Status(403).Json('{"status":"error","code":403,"message":"Acesso proibido: Requer perfil de Administrador."}');
          Exit;
        end;

        Ctx.Response.Status(200).Json('{"status":"success","message":"Bem-vindo ao Painel Administrativo de Seguranca!"}');
      end);

    Writeln('[SERVER] Servidor de Segurança ativo em http://localhost:8080');
    Writeln('[SERVER] Endpoints registrados:');
    Writeln('  - POST http://localhost:8080/api/v1/auth/login?user=demo_admin&pass=secret123');
    Writeln('  - GET  http://localhost:8080/api/v1/protected/user (Retorna 401 sem Bearer token)');
    Writeln('  - GET  http://localhost:8080/api/v1/protected/admin (Retorna 403 para perfil comum)');

    App.Run(8080);
  finally
    JwtHandler.Free;
  end;
end;

begin
  try
    RunSecurityServer;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
