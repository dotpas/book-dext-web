unit FaturamentoDbContext;

interface

uses
  Dext.Entity,
  Dext.Entity.Core,
  InvoiceEntity;

type
  TFaturamentoDbContext = class(TDbContext)
  private
    function GetInvoices: IDbSet<TInvoice>;
  public
    property Invoices: IDbSet<TInvoice> read GetInvoices;
  end;

implementation

{ TFaturamentoDbContext }

function TFaturamentoDbContext.GetInvoices: IDbSet<TInvoice>;
begin
  Result := Entities<TInvoice>;
end;

end.
