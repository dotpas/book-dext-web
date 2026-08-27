unit AuthorizationPolicies;

interface

uses
  System.SysUtils,
  Dext.Auth.JWT,
  Dext.Auth.Identity;

type
  TAuthorizationHelper = class
  public
    class function HasAlcada(User: IClaimsPrincipal; const MinAlcada: Double): Boolean;
  end;

implementation

{ TAuthorizationHelper }

class function TAuthorizationHelper.HasAlcada(User: IClaimsPrincipal; const MinAlcada: Double): Boolean;
var
  AlcadaClaim: TClaim;
  AlcadaVal: Double;
begin
  if (User = nil) or (not User.Identity.IsAuthenticated) then
    Exit(False);

  AlcadaClaim := User.FindClaim('alcada_maxima');
  AlcadaVal := StrToFloatDef(AlcadaClaim.Value, 0.0, TFormatSettings.Invariant);
  Result := AlcadaVal >= MinAlcada;
end;

end.
