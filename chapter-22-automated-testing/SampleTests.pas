unit SampleTests;

interface

uses
  System.SysUtils,
  Dext.Testing,
  Dext.Testing.Runner;

type
  [TestFixture('Exemplo de Testes Unitarios com Dext Testing')]
  TSampleUnitTests = class
  public
    [Test]
    procedure Deve_Validar_Soma_Simples;
    [Test]
    procedure Deve_Validar_Comportamento_Should;
  end;

implementation

procedure TSampleUnitTests.Deve_Validar_Soma_Simples;
begin
  Should(1 + 1).Be(2);
end;

procedure TSampleUnitTests.Deve_Validar_Comportamento_Should;
begin
  Should('Dext Framework').Contain('Dext');
end;

initialization
  TTestRunner.RegisterFixture(TSampleUnitTests);
end.
