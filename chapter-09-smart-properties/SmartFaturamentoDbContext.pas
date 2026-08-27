unit SmartFaturamentoDbContext;

interface

uses
  Dext.Entity,
  Dext.Entity.Core,
  SmartInvoiceEntity;

type
  TFaturamentoDbContext = class(TDbContext)
  private
    function GetInvoices: IDbSet<TSmartInvoice>;
  public
    property Invoices: IDbSet<TSmartInvoice> read GetInvoices;
  end;

implementation

{ TFaturamentoDbContext }

function TFaturamentoDbContext.GetInvoices: IDbSet<TSmartInvoice>;
begin
  Result := Entities<TSmartInvoice>;
end;

end.
