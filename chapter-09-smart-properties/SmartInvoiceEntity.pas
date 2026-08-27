unit SmartInvoiceEntity;

interface

uses
  Dext.Entity,
  Dext.Core.SmartTypes;

type
  [Table('faturas')]
  TSmartInvoice = class
  private
    FId: IntType;
    FCustomerId: IntType;
    FAmount: CurrencyType;
    FStatus: StringType;
  public
    [PK]
    property Id: IntType read FId write FId;

    [Column('customer_id')]
    property CustomerId: IntType read FCustomerId write FCustomerId;

    [Column('amount')]
    property Amount: CurrencyType read FAmount write FAmount;

    [Column('status')]
    property Status: StringType read FStatus write FStatus;
  end;

implementation

end.
