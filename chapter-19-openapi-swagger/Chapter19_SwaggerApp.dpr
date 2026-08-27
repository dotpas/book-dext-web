program Chapter19_SwaggerApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.OpenAPI.Generator,
  Dext.OpenAPI.Types;

begin
  try
    Writeln('Iniciando Servidor com Documentação Swagger UI - Capitulo 11...');
    var App := WebApplication;

    App.Builder.UseSwagger(
      SwaggerOptions.Title('Dext Faturamento API').Version('v1')
    );

    App.Builder.MapGet('/api/v1/invoices',
      procedure(Ctx: IHttpContext)
      begin
        Ctx.Response.Write('[{"id": "INV-001", "total": 150.00}]');
      end);

    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro: ', E.Message);
  end;
end.
