program Chapter07_ControllerApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Web,
  Dext.Web.Interfaces,
  InvoiceController in 'InvoiceController.pas';

begin
  try
    Writeln('Iniciando Servidor de Controllers - Capitulo 07...');
    var App := WebApplication;

    App.Services.AddTransient<TInvoiceController>;
    App.MapControllers;
    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro: ', E.Message);
  end;
end.

