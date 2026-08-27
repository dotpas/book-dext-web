program Chapter13_DataApiApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.DataApi,
  Dext.Entity,
  Dext.Entity.Core,
  DataApiEntities in 'DataApiEntities.pas';

var
  KeeperContext: TAppDataContext = nil;

procedure SeedDatabase;
var
  C1, C2, C3: TCustomer;
begin
  // Mantem conexao 'keeper' aberta para preservar o banco SQLite in-memory durante o ciclo de vida do servidor
  KeeperContext := TAppDataContext.Create(
    DbContextOptions
      .UseSQLite('file:dataapidemo?mode=memory&cache=shared')
      .SnakeCase);
  KeeperContext.EnsureCreated;

  if KeeperContext.Customers.ToList.Count = 0 then
  begin
    Writeln('[SEED] Inserindo dados iniciais no banco de dados SQLite...');
    C1 := TCustomer.Create;
    C1.Id := 1;
    C1.Name := 'Tecnologia Alpha Ltda';
    C1.Email := 'comercial@alpha.com.br';
    KeeperContext.Customers.Add(C1);

    C2 := TCustomer.Create;
    C2.Id := 2;
    C2.Name := 'Sistemas Beta S/A';
    C2.Email := 'contato@beta.com';
    KeeperContext.Customers.Add(C2);

    C3 := TCustomer.Create;
    C3.Id := 3;
    C3.Name := 'Solucoes Gamma Eireli';
    C3.Email := 'financeiro@gamma.com.br';
    KeeperContext.Customers.Add(C3);

    KeeperContext.SaveChanges;
    Writeln('[SEED] 3 clientes gravados com exito.');
  end;
end;

type
  // Middleware de Política da Data API: Define allowlist de verbos e operações autorizadas
  TDataApiPolicyMiddleware = class(TMiddleware)
  public
    procedure Invoke(Ctx: IHttpContext; ANext: TRequestDelegate); override;
  end;

procedure TDataApiPolicyMiddleware.Invoke(Ctx: IHttpContext; ANext: TRequestDelegate);
var
  Method, LimitStr: string;
  LimitVal: Integer;
begin
  if Ctx.Request.Path.StartsWith('/api/v1/customers') then
  begin
    Method := UpperCase(Ctx.Request.Method);

    // 1. Allowlist Estrita de Verbos HTTP (Apenas GET e POST são permitidos)
    if (Method <> 'GET') and (Method <> 'POST') then
    begin
      Ctx.Response.Status(403).Json(Format(
        '{"status":"error","code":403,"message":"Verbo HTTP \"%s\" negado pela allowlist da Data API. Apenas GET e POST sao autorizados."}',
        [Method]));
      Exit;
    end;

    // 2. Política de Validação de Faixa de Paginação (Estritamente de 1 a 100)
    LimitStr := Ctx.Request.GetQueryParam('limit');
    if LimitStr <> '' then
    begin
      if not TryStrToInt(LimitStr, LimitVal) or (LimitVal <= 0) or (LimitVal > 100) then
      begin
        Ctx.Response.Status(400).Json('{"status":"error","code":400,"message":"Parametro limit invalido. Forneca um valor inteiro positivo no intervalo estrito de 1 a 100."}');
        Exit;
      end;
    end;

    // 3. Allowlist Estrita de Campos de Filtro Autorizados na Query String
    var QueryDict := Ctx.Request.GetQuery;
    if (QueryDict <> nil) and (QueryDict.Count > 0) then
    begin
      var Pairs := QueryDict.ToArray;
      for var Pair in Pairs do
      begin
        var LowKey := LowerCase(Pair.Key);
        if (LowKey <> 'id') and (LowKey <> 'name') and (LowKey <> 'email') and
           (LowKey <> 'page') and (LowKey <> 'limit') then
        begin
          Ctx.Response.Status(400).Json(Format(
            '{"status":"error","code":400,"message":"Parametro de filtro \"%s\" nao autorizado pela politica da Data API. Parametros permitidos: id, name, email, page, limit."}',
            [Pair.Key]));
          Exit;
        end;
      end;
    end;
  end;

  ANext(Ctx);
end;

begin
  try
    try
      SeedDatabase;
      var App := WebApplication;

      // 1. Configurar injecao do DbContext no container de DI para a Data API
      App.Services.AddDbContext<TAppDataContext>(
        DbContextOptions
          .UseSQLite('file:dataapidemo?mode=memory&cache=shared')
          .SnakeCase);

      // 2. Aplicar Middleware de Política de Segurança da Data API (Allowlist de operações)
      App.Builder.UseMiddleware(TDataApiPolicyMiddleware);

      // 3. Mapeamento da Data API com controle de exposição
      App.Builder.MapDataApi<TCustomer>('/api/v1/customers',
        DataApiOptions
          .DbContext(TAppDataContext)
          .Allow([amGet, amGetList, amPost]));

      Writeln('[SERVER] Servidor Data API ativo em http://localhost:8080');
      Writeln('[SERVER] Endpoint registrado: /api/v1/customers (Politica: GET/POST Permitidos, DELETE Bloqueado)');
      Writeln('[SERVER] Pressione Ctrl+C para encerrar o servidor.');

      App.Run(8080);
    finally
      if KeeperContext <> nil then
        FreeAndNil(KeeperContext);
    end;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
