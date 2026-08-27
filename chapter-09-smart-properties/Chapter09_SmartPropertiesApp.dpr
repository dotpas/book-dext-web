program Chapter09_SmartPropertiesApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Core.SmartTypes,
  Dext.Entity,
  Dext.Entity.Core,
  Dext.Entity.Prototype,
  Dext.Specifications.Types,
  SmartInvoiceEntity in 'SmartInvoiceEntity.pas',
  SmartFaturamentoDbContext in 'SmartFaturamentoDbContext.pas';

procedure RunSmartPropertiesDemo;
var
  Db: TFaturamentoDbContext;
  Inv1, Inv2, Inv3: TSmartInvoice;
  PendingInvoices, HighValueInvoices: IList<TSmartInvoice>;
  Inv: TSmartInvoice;
  F: TSmartInvoice;
begin
  Writeln('====================================================');
  Writeln('  Dext Smart Properties & AST Expressions Demo      ');
  Writeln('====================================================');

  Db := TFaturamentoDbContext.Create(
    DbContextOptions
      .UseSQLite(':memory:')
      .SnakeCase);
  try
    Writeln('[1] Inicializando schema SQLite em memoria...');
    Db.EnsureCreated;

    // 1. Inserir faturas de teste
    Inv1 := TSmartInvoice.Create;
    Inv1.Id := 1;
    Inv1.CustomerId := 10;
    Inv1.Amount := 450.00;
    Inv1.Status := 'PENDENTE';
    Db.Invoices.Add(Inv1);

    Inv2 := TSmartInvoice.Create;
    Inv2.Id := 2;
    Inv2.CustomerId := 10;
    Inv2.Amount := 2500.00;
    Inv2.Status := 'PENDENTE';
    Db.Invoices.Add(Inv2);

    Inv3 := TSmartInvoice.Create;
    Inv3.Id := 3;
    Inv3.CustomerId := 20;
    Inv3.Amount := 5000.00;
    Inv3.Status := 'PAGA';
    Db.Invoices.Add(Inv3);

    Writeln('[2] Persistindo 3 faturas via SaveChanges...');
    Db.SaveChanges;

    // 'F' obtém a entidade protótipo para consultas tipo-seguras
    F := Prototype.Entity<TSmartInvoice>;

    // 2. Filtrar por Expressão Smart Property (F.Status = 'PENDENTE')
    Writeln('[3] Consultando faturas com Status = "PENDENTE"...');
    PendingInvoices := Db.Invoices
      .Where(F.Status = 'PENDENTE')
      .ToList;

    for Inv in PendingInvoices do
      Writeln(Format('    [PENDENTE] ID: %d | Cliente: %d | Valor: R$ %.2f',
        [Integer(Inv.Id), Integer(Inv.CustomerId), Double(Currency(Inv.Amount))]));

    // 3. Filtrar por Expressão Numérica e Composta (F.Amount >= 2000.0)
    Writeln('[4] Consultando faturas de alto valor (F.Amount >= 2000.0)...');
    HighValueInvoices := Db.Invoices
      .Where(F.Amount >= 2000.0)
      .ToList;

    for Inv in HighValueInvoices do
      Writeln(Format('    [ALTO VALOR] ID: %d | Cliente: %d | Valor: R$ %.2f | Status: %s',
        [Integer(Inv.Id), Integer(Inv.CustomerId), Double(Currency(Inv.Amount)), string(Inv.Status)]));

    if (PendingInvoices.Count = 2) and (HighValueInvoices.Count = 2) then
      Writeln('[SUCESSO] Consultas baseadas em Smart Properties validadas com exito!')
    else
      Writeln('[FALHA] Divergencia nos resultados das expressoes.');
  finally
    Db.Free;
  end;
end;

begin
  try
    RunSmartPropertiesDemo;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
