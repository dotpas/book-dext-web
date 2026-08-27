program Chapter10_SpecificationsApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Entity,
  Dext.Entity.Core,
  Dext.Entity.Setup,
  Dext.Specifications.Types,
  InvoiceEntity in 'InvoiceEntity.pas',
  FaturamentoDbContext in 'FaturamentoDbContext.pas',
  InvoiceSpecifications in 'InvoiceSpecifications.pas';

procedure RunSpecificationsDemo;
var
  Db: TFaturamentoDbContext;
  Inv1, Inv2, Inv3: TInvoice;
  SpecCombined: TFluentExpression;
  ResultsList: IList<TInvoice>;
  Inv: TInvoice;
begin
  Writeln('====================================================');
  Writeln('  Dext Specifications & Composable Queries Demo     ');
  Writeln('====================================================');

  Db := TFaturamentoDbContext.Create(
    DbContextOptions
      .UseSQLite(':memory:')
      .SnakeCase);
  try
    Writeln('[1] Criando banco de dados e schema de faturas...');
    Db.EnsureCreated;

    // Fatura 1: Pendente e Baixo Valor (R$ 300,00)
    Inv1 := TInvoice.Create;
    Inv1.Id := 1;
    Inv1.CustomerId := 10;
    Inv1.Amount := 300.00;
    Inv1.Status := 'PENDENTE';
    Db.Invoices.Add(Inv1);

    // Fatura 2: Pendente e Alto Valor (R$ 5.500,00)
    Inv2 := TInvoice.Create;
    Inv2.Id := 2;
    Inv2.CustomerId := 10;
    Inv2.Amount := 5500.00;
    Inv2.Status := 'PENDENTE';
    Db.Invoices.Add(Inv2);

    // Fatura 3: Paga e Alto Valor (R$ 12.000,00)
    Inv3 := TInvoice.Create;
    Inv3.Id := 3;
    Inv3.CustomerId := 20;
    Inv3.Amount := 12000.00;
    Inv3.Status := 'PAGA';
    Db.Invoices.Add(Inv3);

    Db.SaveChanges;
    Writeln('    3 faturas gravadas.');

    // Composição Booleana de Especificações Reutilizáveis
    SpecCombined := TInvoiceSpecs.Pending and TInvoiceSpecs.HighValue(1000.00);

    Writeln('[2] Executando consulta com Specification Composta: (Status == PENDENTE AND Amount > 1000)...');
    ResultsList := Db.Invoices.Where(SpecCombined).ToList;

    Writeln(Format('    Total localizado: %d fatura(s)', [ResultsList.Count]));
    for Inv in ResultsList do
      Writeln(Format('    -> ID: %d | Status: %s | Valor: R$ %.2f',
        [Inv.Id, Inv.Status, Inv.Amount]));

    if (ResultsList.Count = 1) and (ResultsList[0].Id = 2) then
      Writeln('[SUCESSO] Specification Pattern validado com exito no Dext Entity!')
    else
      Writeln('[FALHA] Resultado inesperado na consulta por Specification.');
  finally
    Db.Free;
  end;
end;

begin
  try
    RunSpecificationsDemo;
  except
    on E: Exception do
      Writeln(Format('[ERRO FATAL] %s: %s', [E.ClassName, E.Message]));
  end;
end.
