unit Entities;

interface

uses
  System.SysUtils,
  Dext.Entity,
  Dext.Entity.Core,
  Dext.Entity.Tenancy;

type
  [Table('customers')]
  TCustomer = class(TTenantEntity)
  private
    FId: Int64;
    FName: string;
    FEmail: string;
  public
    [PK]
    property Id: Int64 read FId write FId;
    
    [Column('name')]
    property Name: string read FName write FName;

    [Column('email')]
    property Email: string read FEmail write FEmail;
  end;

  TAppDbContext = class(TDbContext)
  private
    function GetCustomers: IDbSet<TCustomer>;
  public
    property Customers: IDbSet<TCustomer> read GetCustomers;
  end;

implementation

function TAppDbContext.GetCustomers: IDbSet<TCustomer>;
begin
  Result := Entities<TCustomer>;
end;

end.
