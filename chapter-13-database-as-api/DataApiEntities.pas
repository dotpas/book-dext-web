unit DataApiEntities;

interface

uses
  Dext.Entity,
  Dext.Entity.Core;

type
  [Table('customers')]
  TCustomer = class
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

  TAppDataContext = class(TDbContext)
  private
    function GetCustomers: IDbSet<TCustomer>;
  public
    property Customers: IDbSet<TCustomer> read GetCustomers;
  end;

implementation

{ TAppDataContext }

function TAppDataContext.GetCustomers: IDbSet<TCustomer>;
begin
  Result := Entities<TCustomer>;
end;

end.
