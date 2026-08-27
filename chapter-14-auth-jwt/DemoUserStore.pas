unit DemoUserStore;

interface

uses
  System.SysUtils;

type
  IDemoUserStore = interface
    ['{E3F2A1C4-B5D6-4E7F-8A9B-0C1D2E3F4A5B}']
    function ValidateCredentials(const AUser, APass: string; out ARole: string): Boolean;
  end;

  TDemoUserStore = class(TInterfacedObject, IDemoUserStore)
  public
    function ValidateCredentials(const AUser, APass: string; out ARole: string): Boolean;
  end;

implementation

{ TDemoUserStore }

function TDemoUserStore.ValidateCredentials(const AUser, APass: string; out ARole: string): Boolean;
begin
  ARole := 'user';
  // Validação de repositório de identidade de demonstração
  if (SameText(AUser, 'admin') or SameText(AUser, 'demo_admin')) and (APass = 'AdminSecret2026!') then
  begin
    ARole := 'admin';
    Exit(True);
  end;

  if (SameText(AUser, 'operador') or SameText(AUser, 'operator')) and (APass = 'OperatorPass123!') then
  begin
    ARole := 'user';
    Exit(True);
  end;

  Result := False;
end;

end.
