unit Startup;

interface

uses
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.SecurityHeaders,
  Dext.Web.Cors,
  CustomerEndpoints;

type
  TStartup = class
  public
    class procedure Configure(App: IWebApplication);
  end;

implementation

{ TStartup }

class procedure TStartup.Configure(App: IWebApplication);
begin
  // 1. Pipeline de Middlewares com Record Builders Canônicos
  App.Builder
    .UseExceptionHandler(
      ExceptionHandlerOptions
        .Development(False)
        .IncludeStackTrace(False)
        .LogExceptions(True))
    .UseSecurityHeaders(
      SecurityHeadersOptions
        .ContentTypeOptions('nosniff')
        .FrameOptions('SAMEORIGIN'))
    .UseCors(
      CorsOptions
        .Origins(['https://app.dextfaturamento.local', 'http://localhost:8080'])
        .Methods(['GET', 'POST', 'DELETE', 'OPTIONS'])
        .Headers(['X-Tenant-ID', 'Content-Type', 'Authorization']));

  // 2. Registro das Rotas / Minimal APIs
  RegisterCustomerEndpoints(App);
end;

end.
