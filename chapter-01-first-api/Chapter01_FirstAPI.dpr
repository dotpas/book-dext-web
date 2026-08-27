program Chapter01_FirstAPI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Web;

var
  App: IWebApplication;
begin
  try
    Writeln('Iniciando Servidor Dext na porta 8080...');

    // Cria a aplicacao web minimalista
    App := WebApplication;

    // Registra o primeiro endpoint na raiz
    App.Builder.MapGet('/',
      procedure(Ctx: IHttpContext)
      begin
        Ctx.Response.Write('Olá, Dext Web!');
      end);

    // Inicia o servidor escutando na porta 8080
    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro ao iniciar servidor: ', E.Message);
  end;
end.
