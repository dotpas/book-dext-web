program Chapter12_MultiTenancyApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Entity,
  Dext.Entity.TypeSystem,
  Dext.Specifications.Types,
  Dext.Types.UUID,
  Entities in 'Entities.pas';

procedure TestEntityAndMultiTenancy;
var
  Ctx: TAppDbContext;
  Customer1, Customer2, Customer3: TCustomer;
  AlphaCustomers, BetaCustomers: IList<TCustomer>;
  C: TCustomer;
  Uid: TUUID;
begin
  Writeln('====================================================');
  Writeln('  Dext Entity ORM & Multi-Tenancy Executable Demo   ');
  Writeln('====================================================');

  Uid := TUUID.NewV7;
  Writeln('[LOG] Execucao iniciada com UUID v7: ', Uid.ToString);

  // 1. Configurar banco SQLite em memoria via DbContextOptions
  Ctx := TAppDbContext.Create(
    DbContextOptions
      .UseSQLite(':memory:')
      .SnakeCase);
  try
    Writeln('[1] Criando tabela "customers" no banco SQLite via EnsureCreated...');
    Ctx.EnsureCreated;

    // 2. Persistir registros do Tenant Alpha
    Customer1 := TCustomer.Create;
    Customer1.Id := 1;
    Customer1.Name := 'ACME Brasil Ltda';
    Customer1.Email := 'contato@acme.com.br';
    Customer1.TenantId := 'tenant-alpha';
    Ctx.Customers.Add(Customer1);

    Customer2 := TCustomer.Create;
    Customer2.Id := 2;
    Customer2.Name := 'ACME Global Inc';
    Customer2.Email := 'sales@acme.com';
    Customer2.TenantId := 'tenant-alpha';
    Ctx.Customers.Add(Customer2);

    // 3. Persistir registro do Tenant Beta
    Customer3 := TCustomer.Create;
    Customer3.Id := 3;
    Customer3.Name := 'Beta Logistics S/A';
    Customer3.Email := 'suporte@betalog.com';
    Customer3.TenantId := 'tenant-beta';
    Ctx.Customers.Add(Customer3);

    Writeln('[2] Executando Ctx.SaveChanges (Persistindo 3 entidades no banco)...');
    Ctx.SaveChanges;

    // 4. Consultar com Isolamento de Tenant no ORM (Expressao filtrada no Banco ANTES da materializacao)
    Writeln('[3] Executando consulta filtrada no ORM/Banco para Tenant "tenant-alpha"...');
    AlphaCustomers := Ctx.Customers.Where(TPropExpression.Create('TenantId') = 'tenant-alpha').ToList;
    for C in AlphaCustomers do
      Writeln(Format('    [TENANT-ALPHA] Customer Id: %d | Nome: %s | Email: %s', [C.Id, C.Name, C.Email]));

    Writeln('[4] Executando consulta filtrada no ORM/Banco para Tenant "tenant-beta"...');
    BetaCustomers := Ctx.Customers.Where(TPropExpression.Create('TenantId') = 'tenant-beta').ToList;
    for C in BetaCustomers do
      Writeln(Format('    [TENANT-BETA] Customer Id: %d | Nome: %s | Email: %s', [C.Id, C.Name, C.Email]));

    Writeln(Format('[5] Registros filtrados no ORM -> Tenant Alpha: %d (Esperado: 2) | Tenant Beta: %d (Esperado: 1)',
      [AlphaCustomers.Count, BetaCustomers.Count]));

    if (AlphaCustomers.Count = 2) and (BetaCustomers.Count = 1) then
      Writeln('[SUCESSO] Isolamento de consultas no ORM (WHERE tenant_id = ...) e Persistencia SQLite verificados com exito!')
    else
      Writeln('[FALHA] Divergencia no isolamento de consultas multi-tenant.');

  finally
    Ctx.Free;
  end;
end;

begin
  try
    TestEntityAndMultiTenancy;
  except
    on E: Exception do
      Writeln('[ERRO]: ', E.Message);
  end;
end.
