unit InvoiceCalculator;

interface

uses
  Dext.Options,
  FaturamentoOptions;

type
  TInvoiceCalculator = class
  private
    FOptions: TFaturamentoOptions;
  public
    constructor Create(const Options: IOptions<TFaturamentoOptions>);
    function CalcularDescontoMaximo(const ValorTotal: Currency): Currency;
  end;

implementation

{ TInvoiceCalculator }

constructor TInvoiceCalculator.Create(const Options: IOptions<TFaturamentoOptions>);
begin
  inherited Create;
  if Options <> nil then
    FOptions := Options.Value;
end;

function TInvoiceCalculator.CalcularDescontoMaximo(const ValorTotal: Currency): Currency;
begin
  if FOptions <> nil then
    Result := ValorTotal * (FOptions.MaxDiscountPercent / 100.0)
  else
    Result := 0;
end;

end.
