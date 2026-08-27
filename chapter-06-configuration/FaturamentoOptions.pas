unit FaturamentoOptions;

interface

uses
  System.SysUtils;

type
  TFaturamentoOptions = class
  private
    FGatewayProvider: string;
    FMaxDiscountPercent: Double;
    FDefaultCurrency: string;
  public
    property GatewayProvider: string read FGatewayProvider write FGatewayProvider;
    property MaxDiscountPercent: Double read FMaxDiscountPercent write FMaxDiscountPercent;
    property DefaultCurrency: string read FDefaultCurrency write FDefaultCurrency;

    procedure Validate;
  end;

implementation

{ TFaturamentoOptions }

procedure TFaturamentoOptions.Validate;
begin
  if FGatewayProvider = '' then
    raise Exception.Create('Faturamento:GatewayProvider e obrigatorio.');

  if (FMaxDiscountPercent < 0) or (FMaxDiscountPercent > 100) then
    raise Exception.Create('Faturamento:MaxDiscountPercent deve ser entre 0 e 100.');
end;

end.
