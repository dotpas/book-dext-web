unit InvoiceSpecifications;

interface

uses
  Dext.Specifications.Types;

type
  TInvoiceSpecs = class
  public
    class function Pending: TFluentExpression; static;
    class function HighValue(const MinAmount: Currency): TFluentExpression; static;
  end;

implementation

{ TInvoiceSpecs }

class function TInvoiceSpecs.Pending: TFluentExpression;
begin
  Result := (TPropExpression.Create('Status') = 'PENDENTE');
end;

class function TInvoiceSpecs.HighValue(const MinAmount: Currency): TFluentExpression;
begin
  Result := (TPropExpression.Create('Amount') > MinAmount);
end;

end.
