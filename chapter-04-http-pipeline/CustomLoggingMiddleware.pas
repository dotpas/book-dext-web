unit CustomLoggingMiddleware;

interface

uses
  System.SysUtils,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.Builder;

type
  TCustomLoggingMiddleware = class(TMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

implementation

procedure TCustomLoggingMiddleware.Invoke(
  AContext: IHttpContext; ANext: TRequestDelegate);
begin
  Writeln('[LOG] Requisição iniciada: ', AContext.Request.Path);
  ANext(AContext);
  Writeln('[LOG] Resposta concluída');
end;

end.
