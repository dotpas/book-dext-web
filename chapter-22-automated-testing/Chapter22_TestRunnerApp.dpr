program Chapter22_TestRunnerApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Testing,
  Dext.Testing.Runner,
  SampleTests;

begin
  try
    Writeln('=== Executando Suíte de Testes Dext Testing ===');

    TTestRunner.SetVerbosity(TOutputVerbosity.ovVerbose);
    TTestRunner.RunAll;

    if TTestRunner.Summary.Failed > 0 then
    begin
      Writeln('[CI ERROR] Suíte de testes finalizada com ', TTestRunner.Summary.Failed, ' falha(s).');
      ExitCode := 1;
    end
    else
    begin
      Writeln('[CI SUCCESS] Todos os testes passaram com sucesso.');
      ExitCode := 0;
    end;
  except
    on E: Exception do
    begin
      Writeln('Erro na suíte de testes: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
