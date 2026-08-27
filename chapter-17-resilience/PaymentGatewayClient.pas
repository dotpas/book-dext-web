unit PaymentGatewayClient;

interface

uses
  System.SysUtils,
  Dext.Net.RestClient,
  Dext.Resilience;

type
  TPaymentGatewayClient = class
  private
    FClient: TRestClient;
    FBreaker: IResiliencePolicy;
  public
    constructor Create(const BaseUrl: string);
    procedure ProcessarCobrancaComResiliencia(const IdFatura: Integer; const Valor: Double);
    property Breaker: IResiliencePolicy read FBreaker;
  end;

implementation

{ TPaymentGatewayClient }

constructor TPaymentGatewayClient.Create(const BaseUrl: string);
begin
  inherited Create;
  FBreaker := TCircuitBreakerPolicy.Create(2, 5000);
  FClient := TRestClient.Create(BaseUrl);
  FClient
    .Timeout(5000)
    .Retry(2)
    .AllowSelfSigned(True);
end;

procedure TPaymentGatewayClient.ProcessarCobrancaComResiliencia(
  const IdFatura: Integer; const Valor: Double);
var
  ActionProc: TProc;
begin
  ActionProc := procedure
    begin
      // Executa chamada resiliente através do TRestClient com retentativas
      raise Exception.Create(Format('Falha temporaria de comunicacao para fatura %d (R$ %.2f)',
        [IdFatura, Valor]));
    end;

  FBreaker.Execute(ActionProc);
end;

end.
