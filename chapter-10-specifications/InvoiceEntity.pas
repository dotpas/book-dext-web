unit InvoiceEntity;

interface

uses
  Dext.Entity;

type
  [Table('faturas')]
  TInvoice = class
  private
    FId: Integer;
    FCustomerId: Integer;
    FAmount: Currency;
    FStatus: string;
  public
    [PK]
    [Column('id')]
    property Id: Integer read FId write FId;

    [Column('cliente_id')]
    property CustomerId: Integer read FCustomerId write FCustomerId;

    [Column('valor')]
    property Amount: Currency read FAmount write FAmount;

    [Column('status')]
    property Status: string read FStatus write FStatus;
  end;

implementation

end.
