unit CustomerEndpoints;

interface

uses
  System.SysUtils,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.Results,
  CustomerContracts;

procedure RegisterCustomerEndpoints(App: IWebApplication);

implementation

procedure RegisterCustomerEndpoints(App: IWebApplication);
begin
  // 1. POST: Cadastrar Cliente (Validação Automática via TValidator)
  App.Builder.MapPost<TCustomerCreateDto, IResult>(
    '/api/v1/clientes',
    function(Dto: TCustomerCreateDto): IResult
    var
      NovoId: Integer;
    begin
      NovoId := 42; // ID simulado gerado na persistência
      Result := Results.Created(
        Format('/api/v1/clientes/%d', [NovoId]),
        Format('{"id": %d, "nome": "%s", "status": "ATIVO"}', 
               [NovoId, Dto.Name]));
    end);

  // 2. GET por ID: Consulta de Cliente
  App.Builder.MapGet<Integer, IResult>(
    '/api/v1/clientes/{id}',
    function(id: Integer): IResult
    begin
      if id <= 0 then
        Exit(Results.BadRequest('ID de cliente invalido.'));

      if id = 999 then
        Exit(Results.NotFound(
          Format('Cliente %d nao localizado no sistema.', [id])));

      Result := Results.Ok(
        Format('{"id": %d, "nome": "Empresa Alfa", "status": "ATIVO"}', 
               [id]));
    end);

  // 3. GET com Query Multi-Fonte: Listagem Paginada
  App.Builder.MapGet<TCustomerQueryDto, IResult>(
    '/api/v1/clientes',
    function(Query: TCustomerQueryDto): IResult
    var
      PageLimit: Integer;
    begin
      if Query.TenantId = '' then
        Exit(Results.BadRequest('O cabecalho X-Tenant-ID e mandatorio.'));

      PageLimit := Query.Limit;
      if PageLimit <= 0 then
        PageLimit := 20;

      Result := Results.Ok(
        Format('{"tenant": "%s", "status": "%s", "limite": %d}', 
               [Query.TenantId, Query.Status, PageLimit]));
    end);

  // 4. DELETE: Inativação de Cliente
  App.Builder.MapDelete<Integer, IResult>(
    '/api/v1/clientes/{id}',
    function(id: Integer): IResult
    begin
      if id <= 0 then
        Exit(Results.BadRequest('Identificador invalido.'));

      Result := Results.NoContent; // 204 No Content
    end);
end;

end.
