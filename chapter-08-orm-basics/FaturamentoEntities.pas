unit FaturamentoEntities;

interface

uses
  Dext.Entity;

type
  [Table('clientes')]
  TCustomer = class
  private
    FId: Integer;
    FNome: string;
    FEmail: string;
    FDocumento: string;
    FStatus: string;
  public
    [PK, AutoInc, Column('id')]
    property Id: Integer read FId write FId;

    [Column('nome'), MaxLength(100)]
    property Nome: string read FNome write FNome;

    [Column('email'), MaxLength(150)]
    property Email: string read FEmail write FEmail;

    [Column('documento'), MaxLength(14)]
    property Documento: string read FDocumento write FDocumento;

    [Column('status'), MaxLength(20)]
    property Status: string read FStatus write FStatus;
  end;

  [Table('faturas')]
  TInvoice = class
  private
    FId: Integer;
    FClienteId: Integer;
    FValor: Currency;
    FStatus: string;
    FDataEmissao: TDateTime;
  public
    [PK, AutoInc, Column('id')]
    property Id: Integer read FId write FId;

    [Column('cliente_id')]
    property ClienteId: Integer read FClienteId write FClienteId;

    [Column('valor')]
    property Valor: Currency read FValor write FValor;

    [Column('status'), MaxLength(20)]
    property Status: string read FStatus write FStatus;

    [Column('data_emissao')]
    property DataEmissao: TDateTime read FDataEmissao write FDataEmissao;
  end;

implementation

end.
