unit Lab03Security;

interface

uses
  System.SysUtils,
  Dext.Auth.JWT,
  Dext.Auth.Identity;

type
  TLab03SecurityHelper = class
  public
    class function HasAlcada(User: IClaimsPrincipal; const MinAlcada: Double): Boolean;
    class function GetTenant(User: IClaimsPrincipal): string;
  end;

implementation

{ TLab03SecurityHelper }

class function TLab03SecurityHelper.HasAlcada(User: IClaimsPrincipal; const MinAlcada: Double): Boolean;
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

class function TLab03SecurityHelper.GetTenant(User: IClaimsPrincipal): string;
var
  TenantClaim: TClaim;
begin
  if (User = nil) or (not User.Identity.IsAuthenticated) then
    Exit('');

  TenantClaim := User.FindClaim('tenant_id');
  Result := TenantClaim.Value;
end;

end.
