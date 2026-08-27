program Chapter02_InvoicesMinimalAPI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.Results,
  Dext.Json;

type
  TNovaFaturaDto = record
    ClienteId: Integer;
    Valor: Currency;
    Vencimento: string;
  end;

procedure RegisterInvoiceEndpoints(App: IWebApplication);
begin
  // === MODELO DIRETO (IHttpContext) ===

  // 1. Rota Fixa: Resumo de Faturamento (GET)
  App.Builder.MapGet('/api/v1/faturas/resumo',
    procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Json(
        '{"totalFaturas":150,"valorTotal":45890.50,"pendentes":12}');
    end);

  // 2. Rota com Parâmetro {id} (GET)
  App.Builder.MapGet('/api/v1/faturas/{id}',
    procedure(Ctx: IHttpContext)
    var
      Id: Integer;
    begin
      Id := StrToIntDef(Ctx.Request.RouteParams['id'], 0);

      if Id <= 0 then
      begin
        Ctx.Response.Status(400).Json(
          '{"erro":"Identificador de fatura deve ser positivo."}');
        Exit;
      end;

      if Id = 999 then
      begin
        Ctx.Response.Status(404).Json(
          Format('{"erro":"Fatura %d nao encontrada no sistema."}', [Id]));
        Exit;
      end;

      Ctx.Response.Status(200).Json(
        Format('{"id":%d,"clienteId":42,"status":"PAGA"}', [Id]));
    end);

  // 3. Rota com Query String (?status=...&limite=...) (GET)
  App.Builder.MapGet('/api/v1/faturas',
    procedure(Ctx: IHttpContext)
    var
      StatusFiltro: string;
      Limite: Integer;
    begin
      StatusFiltro := Ctx.Request.Query['status'];
      if StatusFiltro = '' then
        StatusFiltro := 'TODAS';

      Limite := StrToIntDef(Ctx.Request.Query['limite'], 20);

      Ctx.Response.Status(200).Json(
        Format('{"filtro":"%s","limite":%d,"itens":[]}',
               [StatusFiltro, Limite]));
    end);

  // 4. Exclusão de Fatura com Código 204 (DELETE)
  App.Builder.MapDelete('/api/v1/faturas/{id}',
    procedure(Ctx: IHttpContext)
    var
      Id: Integer;
    begin
      Id := StrToIntDef(Ctx.Request.RouteParams['id'], 0);

      if Id <= 0 then
      begin
        Ctx.Response.Status(400).Json(
          '{"erro":"ID de fatura invalido para exclusao."}');
        Exit;
      end;

      Ctx.Response.StatusCode := 204;
    end);

  // === MODELO DECLARATIVO E TIPADO (IResult & Results) ===

  // 5. Consulta Tipada com IResult (GET semântico)
  App.Builder.MapGet<Integer, IResult>('/api/v1/faturas/semantica/{id}',
    function(Id: Integer): IResult
    begin
      if Id <= 0 then
        Exit(Results.BadRequest('Identificador de fatura deve ser positivo.'));

      if Id = 999 then
        Exit(Results.NotFound(Format('Fatura %d nao encontrada.', [Id])));

      Result := Results.Ok(Format('{"id":%d,"clienteId":42,"status":"PAGA","estilo":"Funcional"}', [Id]));
    end);

  // 6. Criação Tipada com DTO e Results.Created (POST)
  App.Builder.MapPost<TNovaFaturaDto, IResult>('/api/v1/faturas',
    function(NovaFatura: TNovaFaturaDto): IResult
    var
      NovoIdGerado: Integer;
    begin
      if NovaFatura.Valor <= 0 then
        Exit(Results.BadRequest('{"erro":"O valor da fatura deve ser positivo."}'));

      NovoIdGerado := 105;

      Result := Results.Created(
        '/api/v1/faturas/' + NovoIdGerado.ToString,
        Format('{"id":%d,"clienteId":%d,"status":"EMITIDA"}',
               [NovoIdGerado, NovaFatura.ClienteId]));
    end);
end;

begin
  try
    Writeln('Iniciando Servidor Minimal API de Faturas - Capitulo 02...');
    var App := WebApplication;

    RegisterInvoiceEndpoints(App);

    Writeln('[SERVER] Endpoints registrados em http://localhost:8080:');
    Writeln('  - GET    /api/v1/faturas/resumo');
    Writeln('  - GET    /api/v1/faturas/{id}');
    Writeln('  - GET    /api/v1/faturas/semantica/{id} (Funcional com IResult)');
    Writeln('  - GET    /api/v1/faturas?status=...&limite=...');
    Writeln('  - POST   /api/v1/faturas');
    Writeln('  - DELETE /api/v1/faturas/{id}');

    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro: ', E.Message);
  end;
end.
