program Lab02_PersistenceFaturamento;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Entity,
  Dext.Entity.Core,
  Dext.Entity.Setup,
  Lab02Entities in 'Lab02Entities.pas',
  Lab02DbContext in 'Lab02DbContext.pas',
  Lab02QueryService in 'Lab02QueryService.pas';

procedure RunLab02Demo;
var
  Db: TFaturamentoDbContext;
  Cust: TCustomer;
  Inv1, Inv2: TInvoice;
  QueryService: IInvoiceLabQueryService;
  ResultsList: IList<TInvoice>;
  Inv: TInvoice;
begin
  Writeln('====================================================');
  Writeln('  Lab 02: Persistence Engine & Faturamento Queries Demo ');
  Writeln('====================================================');

  Db := TFaturamentoDbContext.Create(
    DbContextOptions
      .UseSQLite(':memory:')
      .SnakeCase);
  try
    Writeln('[1] Criando schema SQLite em memoria...');
    Db.EnsureCreated;

    Cust := TCustomer.Create;
    Cust.Id := 105;
    Cust.Name := 'Cliente Lab 2';
    Db.Customers.Add(Cust);

    // Fatura 1: Vencida e alto valor (R$ 500,00)
    Inv1 := TInvoice.Create;
    Inv1.Id := 1;
    Inv1.CustomerId := 105;
    Inv1.Amount := 500.00;
    Inv1.Status := 'PENDENTE';
    Db.Invoices.Add(Inv1);

    // Fatura 2: Baixo valor (R$ 50,00)
    Inv2 := TInvoice.Create;
    Inv2.Id := 2;
    Inv2.CustomerId := 105;
    Inv2.Amount := 50.00;
    Inv2.Status := 'PENDENTE';
    Db.Invoices.Add(Inv2);

    Db.SaveChanges;

    // 2. Consulta de Cobrança encapsulada no serviço de domínio usando Specifications
    Writeln('[2] Executando consulta de cobranca com Keyset/Specification...');
    QueryService := TInvoiceLabQueryService.Create(Db);
    ResultsList := QueryService.ListarFaturasParaCobranca(105, 100.0);

    for Inv in ResultsList do
      Writeln(Format('    [COBRANCA] Fatura ID: %d | Valor: R$ %.2f | Status: %s',
        [Inv.Id, Inv.Amount, Inv.Status]));

    if (ResultsList.Count = 1) and (ResultsList[0].Id = 1) then
      Writeln('[SUCESSO] Laboratorio 2: Motor de Persistencia e Consultas aprovado com exito!')
    else
      Writeln('[FALHA] Divergencia na consulta do Laboratorio 2.');
  finally
    Db.Free;
  end;
end;

begin
  try
    RunLab02Demo;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
