unit Lab02Entities;

interface

uses
  Dext.Entity;

type
  [Table('clientes')]
  TCustomer = class
  private
    FId: Int64;
    FName: string;
  public
    [PK]
    property Id: Int64 read FId write FId;
    [Column('nome')]
    property Name: string read FName write FName;
  end;

  [Table('faturas')]
  TInvoice = class
  private
    FId: Int64;
    FCustomerId: Int64;
    FAmount: Double;
    FStatus: string;
  public
    [PK]
    property Id: Int64 read FId write FId;
    [Column('customer_id')]
    property CustomerId: Int64 read FCustomerId write FCustomerId;
    [Column('amount')]
    property Amount: Double read FAmount write FAmount;
    [Column('status')]
    property Status: string read FStatus write FStatus;
  end;

implementation

end.
