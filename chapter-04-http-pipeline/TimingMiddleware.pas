unit TimingMiddleware;

interface

uses
  System.SysUtils,
  System.Diagnostics,
  Dext.Web,
  Dext.Web.Interfaces;

type
  TTimingMiddleware = class(TMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

implementation

procedure TTimingMiddleware.Invoke(
  AContext: IHttpContext; ANext: TRequestDelegate);
var
  Stopwatch: TStopwatch;
  ElapsedMs: Double;
begin
  Stopwatch := TStopwatch.StartNew;
  try
    ANext(AContext);
  finally
    Stopwatch.Stop;
    ElapsedMs := Stopwatch.Elapsed.TotalMilliseconds;
    
    AContext.Response.AddHeader(
      'X-Response-Time-Ms', FormatFloat('0.00', ElapsedMs));
    
    Writeln(Format('[TIMING] %s %s em %.2f ms (Status: %d)',
      [AContext.Request.Method, AContext.Request.Path,
       ElapsedMs, AContext.Response.StatusCode]));
  end;
end;

end.
