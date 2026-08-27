unit Lab02QueryService;

interface

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Entity,
  Dext.Specifications.Types,
  Lab02Entities,
  Lab02DbContext;

type
  IInvoiceLabQueryService = interface
    ['{8A9B1C2D-3E4F-5A6B-7C8D-9E0F1A2B3C4D}']
    function ListarFaturasParaCobranca(
      const ClienteId: Int64;
      const MinAmount: Double): IList<TInvoice>;
  end;

  TInvoiceLabQueryService = class(TInterfacedObject, IInvoiceLabQueryService)
  private
    FDb: TFaturamentoDbContext;
  public
    constructor Create(Db: TFaturamentoDbContext);
    function ListarFaturasParaCobranca(
      const ClienteId: Int64;
      const MinAmount: Double): IList<TInvoice>;
  end;

implementation

{ TInvoiceLabQueryService }

constructor TInvoiceLabQueryService.Create(Db: TFaturamentoDbContext);
begin
  inherited Create;
  FDb := Db;
end;

function TInvoiceLabQueryService.ListarFaturasParaCobranca(
  const ClienteId: Int64;
  const MinAmount: Double): IList<TInvoice>;
var
  QuerySpec: TFluentExpression;
begin
  QuerySpec := (TPropExpression.Create('CustomerId') = ClienteId) and
               (TPropExpression.Create('Status') = 'PENDENTE') and
               (TPropExpression.Create('Amount') >= MinAmount);

  Result := FDb.Invoices.Where(QuerySpec).ToList;
end;

end.
