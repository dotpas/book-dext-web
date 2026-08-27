unit HealthCheckServices;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.SyncObjs,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  Dext.Web,
  Dext.Web.Interfaces;

var
  RequestCounter: Int64 = 0;
  ErrorCounter: Int64 = 0;
  TotalDurationMs: Int64 = 0;
  MaxDurationMs: Int64 = 0;
  StartTime: TDateTime;
  DbOnlineState: Int64 = 1; // 1 = Online, 0 = Offline

type
  THostingMetricsMiddleware = class(TMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

  IDatabaseHealthCheck = interface
    ['{B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E}']
    function CheckHealth(TimeoutMs: Integer; out LatencyMs: Integer; out ErrorMsg: string): Boolean;
  end;

  TDatabaseHealthCheck = class(TInterfacedObject, IDatabaseHealthCheck)
  public
    function CheckHealth(TimeoutMs: Integer; out LatencyMs: Integer; out ErrorMsg: string): Boolean;
  end;

implementation

{ THostingMetricsMiddleware }

procedure THostingMetricsMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
var
  Stopwatch: TStopwatch;
  ElapsedMs, CurrentMax: Int64;
begin
  TInterlocked.Increment(RequestCounter);
  Stopwatch := TStopwatch.StartNew;
  try
    ANext(AContext);
  finally
    Stopwatch.Stop;
    ElapsedMs := Stopwatch.ElapsedMilliseconds;
    TInterlocked.Add(TotalDurationMs, ElapsedMs);

    repeat
      CurrentMax := TInterlocked.Read(MaxDurationMs);
      if ElapsedMs <= CurrentMax then Break;
    until TInterlocked.CompareExchange(MaxDurationMs, ElapsedMs, CurrentMax) = CurrentMax;

    if AContext.Response.StatusCode >= 400 then
      TInterlocked.Increment(ErrorCounter);
  end;
end;

{ TDatabaseHealthCheck }

function TDatabaseHealthCheck.CheckHealth(TimeoutMs: Integer; out LatencyMs: Integer; out ErrorMsg: string): Boolean;
var
  Sw: TStopwatch;
  Conn: TFDConnection;
  Query: TFDQuery;
begin
  Sw := TStopwatch.StartNew;

  if TInterlocked.Read(DbOnlineState) = 0 then
  begin
    Sw.Stop;
    LatencyMs := Integer(Sw.ElapsedMilliseconds);
    ErrorMsg := 'SQL State 08001: Conexao recusada pelo driver de banco de dados SQLite (Host indisponivel).';
    Exit(False);
  end;

  Conn := TFDConnection.Create(nil);
  try
    try
      Conn.DriverName := 'SQLite';
      Conn.Params.Values['Database'] := ExtractFilePath(ParamStr(0)) + 'healthcheck.sqlite';
      Conn.Params.Values['OpenMode'] := 'ReadWriteCreate';
      Conn.Params.Values['LockingMode'] := 'Normal';
      Conn.Params.Values['BusyTimeout'] := IntToStr(TimeoutMs);
      Conn.ResourceOptions.CmdExecTimeout := TimeoutMs;
      Conn.Connected := True;

      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Conn;
        Query.SQL.Text := 'SELECT 1 AS probe;';
        Query.Open;
        Sw.Stop;
        LatencyMs := Integer(Sw.ElapsedMilliseconds);
        ErrorMsg := '';
        Result := True;
      finally
        Query.Free;
      end;
    except
      on E: Exception do
      begin
        Sw.Stop;
        LatencyMs := Integer(Sw.ElapsedMilliseconds);
        ErrorMsg := Format('Erro no probe de banco: %s (%s)', [E.Message, E.ClassName]);
        Result := False;
      end;
    end;
  finally
    Conn.Free;
  end;
end;

end.
