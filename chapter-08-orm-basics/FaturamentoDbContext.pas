unit FaturamentoDbContext;

interface

uses
  Dext.Entity,
  Dext.Entity.Core,
  FaturamentoEntities;

type
  TFaturamentoDbContext = class(TDbContext)
  private
    function GetClientes: IDbSet<TCustomer>;
    function GetFaturas: IDbSet<TInvoice>;
  public
    property Clientes: IDbSet<TCustomer> read GetClientes;
    property Faturas: IDbSet<TInvoice> read GetFaturas;
  end;

implementation

{ TFaturamentoDbContext }

function TFaturamentoDbContext.GetClientes: IDbSet<TCustomer>;
begin
  Result := Entities<TCustomer>;
end;

function TFaturamentoDbContext.GetFaturas: IDbSet<TInvoice>;
begin
  Result := Entities<TInvoice>;
end;

end.
