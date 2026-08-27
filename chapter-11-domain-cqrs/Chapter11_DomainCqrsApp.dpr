program Chapter11_DomainCqrsApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Entity,
  Dext.Entity.Core,
  Dext.Entity.Setup,
  RichInvoiceEntity in 'RichInvoiceEntity.pas',
  DomainFaturamentoDbContext in 'DomainFaturamentoDbContext.pas';

procedure RunDomainCqrsDemo;
var
  Db: TFaturamentoDbContext;
  Invoice: TRichInvoice;
  Loaded: TRichInvoice;
begin
  Writeln('====================================================');
  Writeln('  Dext Domain Model & CQRS Separation Demo          ');
  Writeln('====================================================');

  Db := TFaturamentoDbContext.Create(
    DbContextOptions
      .UseSQLite(':memory:')
      .SnakeCase);
  try
    Writeln('[1] Criando schema SQLite em memoria...');
    Db.EnsureCreated;

    // 1. Command: Emitir Fatura (Regra Rica)
    Writeln('[2] Executando Command: Emitir Fatura ID 100 com valor R$ 1.200,00...');
    Invoice := TRichInvoice.Create(100, 1, 1200.00);
    Db.Invoices.Add(Invoice);
    Db.SaveChanges;

    // 2. Command: Liquidar Fatura com validação de invariante
    Writeln('[3] Executando Command: Liquidar Fatura ID 100 com R$ 1.200,00...');
    Loaded := Db.Invoices.Find(100);
    if Loaded <> nil then
    begin
      Loaded.Liquidate(1200.00);
      Db.SaveChanges;
    end;

    // 3. Query: Leitura direta de projeção
    Writeln('[4] Executando Query: Consultando fatura persistida...');
    Loaded := Db.Invoices.Find(100);
    if (Loaded <> nil) and (Loaded.Status = 'PAGA') and (Loaded.PaidAmount = 1200.00) then
      Writeln('[SUCESSO] Invariantes de dominio e persistencia CQRS validadas com exito!')
    else
      Writeln('[FALHA] Divergencia no estado da entidade rica.');
  finally
    Db.Free;
  end;
end;

begin
  try
    RunDomainCqrsDemo;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
