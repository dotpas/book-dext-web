program Lab01_CustomersApi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Web,
  CustomerContracts in 'CustomerContracts.pas',
  CustomerEndpoints in 'CustomerEndpoints.pas',
  Startup in 'Startup.pas';

begin
  try
    Writeln('Iniciando Microsservico de Clientes - Laboratorio 01...');
    var App := WebApplication;

    TStartup.Configure(App);

    Writeln('[SERVER] Servidor pronto em http://localhost:8080');
    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro fatal: ', E.ClassName, ': ', E.Message);
  end;
end.
