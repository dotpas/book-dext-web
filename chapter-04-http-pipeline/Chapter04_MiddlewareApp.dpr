program Chapter04_MiddlewareApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.SecurityHeaders,
  TimingMiddleware;

begin
  try
    Writeln('Iniciando Servidor com Pipeline de Middlewares...');
    var App := WebApplication;

    var Env := GetEnvironmentVariable('DEXT_ENVIRONMENT');
    if Env = '' then
      Env := 'Production';

    if Env = 'Development' then
      App.Builder.UseDeveloperExceptionPage
    else
      App.Builder.UseExceptionHandler(
        ExceptionHandlerOptions
          .Development(False)
          .IncludeStackTrace(False)
          .LogExceptions(True)
      );

    App.Builder
      .UseSecurityHeaders(
        SecurityHeadersOptions
          .Hsts(31536000, True)
          .ContentTypeOptions('nosniff')
          .FrameOptions('SAMEORIGIN')
      )
      .UseHttpLogging(
        HttpLoggingOptions
          .LogHeaders(True)
          .LogRequestBody(False)
          .RedactHeaders(['authorization', 'cookie', 'set-cookie', 'x-api-key'])
      )
      .UseCors(
        CorsOptions
          .Origins(['https://app.empresa.com', 'https://admin.empresa.com',
                   'http://localhost:8080'])
          .Methods(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])
          .Headers(['Content-Type', 'Authorization', 'X-Requested-With'])
          .AllowCredentials
          .MaxAge(86400)
      )
      .UseCompression(
        CompressionOptions
          .MinimumSize(512)
          .EnableForHttps(False)
      )
      .UseMiddleware(TTimingMiddleware);

    App.Builder.MapGet('/api/v1/faturas/resumo',
      procedure(Ctx: IHttpContext)
      begin
        Results.Context(Ctx).Ok('{"status":"ok","faturas_processadas":120}');
      end);

    App.Builder.MapGet('/api/v1/error-demo',
      procedure(Ctx: IHttpContext)
      begin
        raise EValidationException.Create('Exemplo de erro tratado via RFC 9457');
      end);

    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro: ', E.Message);
  end;
end.
