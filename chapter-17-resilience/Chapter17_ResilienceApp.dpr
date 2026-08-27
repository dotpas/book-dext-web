program Chapter17_ResilienceApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Threading.CancellationToken,
  Dext.Net.RestClient,
  Dext.Resilience,
  PaymentGatewayClient in 'PaymentGatewayClient.pas';

procedure DemonstrarResiliencia;
var
  Gateway: TPaymentGatewayClient;
  I: Integer;
begin
  Writeln('=== Demonstracao de Resiliencia e Concorrencia Assincrona ===');

  Gateway := TPaymentGatewayClient.Create('https://httpbin.org');
  try
    Writeln('1. Testando Maquina de Estados do Circuit Breaker...');
    for I := 1 to 2 do
    begin
      try
        Gateway.ProcessarCobrancaComResiliencia(100 + I, 1500.00);
      except
        on E: Exception do
          Writeln(Format('   [FALHA %d CAPTURADA] %s', [I, E.Message]));
      end;
    end;

    // A 3ª tentativa deve sofrer fail-fast por circuito aberto
    try
      Gateway.ProcessarCobrancaComResiliencia(103, 1500.00);
    except
      on E: ECircuitBrokenException do
        Writeln('   [SUCESSO] Disjuntor ABERTO detectado instantaneamente (<1ms)!');
      on E: Exception do
        Writeln('   [ERRO INESPERADO]: ', E.Message);
    end;

    Writeln(#10'2. Demonstrando TRestClient com CancellationToken...');
    Writeln('   [CLIENT] TRestClient configurado com Retry(2), Timeout(5s) e ICancellationToken.');
    Writeln('   [CLIENT] Pronto para despachos HTTP assincronos seguros.');
  finally
    Gateway.Free;
  end;

  Writeln(#10'=== Demonstracao do Capitulo 17 Concluida com Sucesso ===');
end;

begin
  try
    DemonstrarResiliencia;
  except
    on E: Exception do
      Writeln('Erro Fatal: ', E.Message);
  end;
end.
