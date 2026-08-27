program Chapter08_OrmBasicsApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Entity,
  Dext.Entity.Core,
  Dext.Entity.Setup,
  FaturamentoEntities in 'FaturamentoEntities.pas',
  FaturamentoDbContext in 'FaturamentoDbContext.pas';

procedure RunOrmBasicsDemo;
var
  Db: TFaturamentoDbContext;
  Customer: TCustomer;
  Invoice: TInvoice;
  LoadedInvoice: TInvoice;
  AllInvoices: IList<TInvoice>;
begin
  Writeln('====================================================');
  Writeln('  Dext Entity Basics: Entities & Unit of Work        ');
  Writeln('====================================================');

  Db := TFaturamentoDbContext.Create(
    DbContextOptions
      .UseSQLite(':memory:')
      .SnakeCase);
  try
    Writeln('[1] Inicializando schema SQLite em memoria...');
    Db.EnsureCreated;

    // 1. Inserir Cliente
    Customer := TCustomer.Create;
    Customer.Id := 1;
    Customer.Nome := 'Tech Corp do Brasil';
    Customer.Email := 'contato@techcorp.com.br';
    Customer.Documento := '12345678000190';
    Customer.Status := 'ATIVO';
    Db.Clientes.Add(Customer);

    // 2. Inserir Fatura relacionada
    Invoice := TInvoice.Create;
    Invoice.ClienteId := Customer.Id;
    Invoice.Valor := 1500.75;
    Invoice.Status := 'EMITIDA';
    Invoice.DataEmissao := Now;
    Db.Faturas.Add(Invoice);

    Writeln('[2] Executando Db.SaveChanges (Persistindo Cliente e Fatura)...');
    Db.SaveChanges;

    // 3. Atualizar Status (Change Tracking)
    Writeln(Format('[3] Atualizando status da Fatura %d para "PAGA"...', [Invoice.Id]));
    LoadedInvoice := Db.Faturas.Find(Invoice.Id);
    if LoadedInvoice <> nil then
    begin
      LoadedInvoice.Status := 'PAGA';
      Db.SaveChanges;
      Writeln('    Status atualizado com sucesso via Unit of Work!');
    end;

    // 4. Listar todas as faturas
    Writeln('[4] Consultando faturas gravadas...');
    AllInvoices := Db.Faturas.ToList;
    for Invoice in AllInvoices do
      Writeln(Format('    Fatura ID: %d | Cliente ID: %d | Valor: R$ %.2f | Status: %s',
        [Invoice.Id, Invoice.ClienteId, Invoice.Valor, Invoice.Status]));

    if (AllInvoices.Count = 1) and (AllInvoices[0].Status = 'PAGA') then
      Writeln('[SUCESSO] Operacoes basicas do Dext Entity validadas com exito!')
    else
      Writeln('[FALHA] Divergencia na persistencia do Dext Entity.');
  finally
    Db.Free;
  end;
end;

begin
  try
    RunOrmBasicsDemo;
  except
    on E: Exception do
      Writeln(Format('[ERRO FATAL] %s: %s', [E.ClassName, E.Message]));
  end;
end.
