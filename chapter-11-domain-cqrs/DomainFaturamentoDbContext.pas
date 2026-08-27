unit DomainFaturamentoDbContext;

interface

uses
  Dext.Entity,
  Dext.Entity.Core,
  RichInvoiceEntity;

type
  TFaturamentoDbContext = class(TDbContext)
  private
    function GetInvoices: IDbSet<TRichInvoice>;
  public
    property Invoices: IDbSet<TRichInvoice> read GetInvoices;
  end;

implementation

{ TFaturamentoDbContext }

function TFaturamentoDbContext.GetInvoices: IDbSet<TRichInvoice>;
begin
  Result := Entities<TRichInvoice>;
end;

end.
