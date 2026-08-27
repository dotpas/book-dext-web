unit Lab02DbContext;

interface

uses
  Dext.Entity,
  Dext.Entity.Core,
  Lab02Entities;

type
  TFaturamentoDbContext = class(TDbContext)
  private
    function GetCustomers: IDbSet<TCustomer>;
    function GetInvoices: IDbSet<TInvoice>;
  public
    property Customers: IDbSet<TCustomer> read GetCustomers;
    property Invoices: IDbSet<TInvoice> read GetInvoices;
  end;

implementation

{ TFaturamentoDbContext }

function TFaturamentoDbContext.GetCustomers: IDbSet<TCustomer>;
begin
  Result := Entities<TCustomer>;
end;

function TFaturamentoDbContext.GetInvoices: IDbSet<TInvoice>;
begin
  Result := Entities<TInvoice>;
end;

end.
