unit RateLimiterService;

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  TSimpleRateLimiter = class
  private
    FLock: TCriticalSection;
    FMaxRequests: Integer;
    FCurrentCount: Integer;
  public
    constructor Create(const AMax: Integer);
    destructor Destroy; override;
    function TryAcquire: Boolean;
    procedure Reset;
  end;

implementation

{ TSimpleRateLimiter }

constructor TSimpleRateLimiter.Create(const AMax: Integer);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FMaxRequests := AMax;
  FCurrentCount := 0;
end;

destructor TSimpleRateLimiter.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TSimpleRateLimiter.TryAcquire: Boolean;
begin
  FLock.Enter;
  try
    if FCurrentCount < FMaxRequests then
    begin
      Inc(FCurrentCount);
      Result := True;
    end
    else
      Result := False;
  finally
    FLock.Leave;
  end;
end;

procedure TSimpleRateLimiter.Reset;
begin
  FLock.Enter;
  try
    FCurrentCount := 0;
  finally
    FLock.Leave;
  end;
end;

end.
