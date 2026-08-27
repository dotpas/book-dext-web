program Chapter06_ConfigApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Configuration.Interfaces,
  Dext.Configuration.Core,
  Dext.Configuration.Yaml,
  Dext.Configuration.EnvironmentVariables,
  Dext.Options,
  FaturamentoOptions in 'FaturamentoOptions.pas',
  InvoiceCalculator in 'InvoiceCalculator.pas';

procedure TestConfiguration;
var
  Builder: IConfigurationBuilder;
  Config: IConfigurationRoot;
  PortVal, Gateway: string;
  Options: IOptions<TFaturamentoOptions>;
  Calculator: TInvoiceCalculator;
  Desconto: Currency;
begin
  Writeln('=== Dext Configuration, IOptions & Twelve-Factor Demo ===');

  // 1. Constrói as fontes de configuração hierárquicas
  Builder := TConfigurationBuilder.Create;
  Builder.Add(TYamlConfigurationSource.Create('appsettings.yaml', True));
  Builder.Add(TEnvironmentVariablesConfigurationSource.Create);

  Config := Builder.Build;

  // 2. Leitura Direta de Propriedades Escalares
  PortVal := Config['Server:Port'];
  Gateway := Config['Faturamento:GatewayProvider'];
  Writeln('Porta lida do YAML: ', PortVal);
  Writeln('Provedor de Gateway: ', Gateway);

  // 3. Binding Tipado com IOptions<T>
  var FatOpts := TFaturamentoOptions.Create;
  FatOpts.GatewayProvider := Gateway;
  FatOpts.MaxDiscountPercent := StrToFloatDef(Config['Faturamento:MaxDiscountPercent'], 15.0);
  FatOpts.DefaultCurrency := Config['Faturamento:DefaultCurrency'];
  FatOpts.Validate;

  Options := TOptions<TFaturamentoOptions>.Create(FatOpts);

  // 4. Injeção de Opções no Serviço de Domínio
  Calculator := TInvoiceCalculator.Create(Options);
  try
    Desconto := Calculator.CalcularDescontoMaximo(1000.00);
    Writeln(Format('Desconto maximo para fatura de R$ 1.000,00: R$ %.2f (%.1f%%)',
      [Desconto, FatOpts.MaxDiscountPercent]));
  finally
    Calculator.Free;
  end;
end;

begin
  try
    TestConfiguration;
  except
    on E: Exception do
      Writeln('Erro de Configuracao: ', E.Message);
  end;
end.
