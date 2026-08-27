program Chapter24_McpServerApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  Dext.AI.MCP.Server,
  Dext.AI.MCP.Protocol,
  Dext.AI.MCP.Tools,
  Dext.AI.MCP.Attributes,
  Dext.AI.MCP.Types,
  DemoProvider in 'DemoProvider.pas';

procedure TestMcpServerAndExecution;
var
  Server: TMCPServer;
  Provider: TDemoProvider;
  ToolResult: TMCPToolResult;
  ToolText: string;
  ToolsJson: TJSONArray;
  ToolCount: Integer;
  DummyArgs: TJSONObject;
  ToolDef: TMCPToolDef;
  HasStatus: Boolean;
begin
  Writeln('====================================================================');
  Writeln('  Dext AI-Native Model Context Protocol (MCP) Server - Cap 24       ');
  Writeln('====================================================================');

  Server := TMCPServer.Create('DextMcpServerDemo', '1.0.0');
  try
    // 1. Registrar o provider com a ferramenta 'get-server-status'
    Provider := TDemoProvider.Create;
    Server.RegisterProvider(Provider);
    Writeln('[1] Provider TDemoProvider registrado com sucesso no Servidor MCP.');

    // 2. Inspecionar as ferramentas registradas em formato JSON
    ToolsJson := Server.Registry.BuildToolsArray;
    try
      ToolCount := ToolsJson.Count;
      Writeln(Format('[2] Total de ferramentas MCP registradas no servidor: %d', [ToolCount]));
      Writeln('    Schema JSON registrado: ', ToolsJson.ToString);
    finally
      ToolsJson.Free;
    end;

    // 3. Buscar e validar definição da ferramenta no Registry
    if Server.Registry.TryGetTool('get-server-status', ToolDef) then
      Writeln(Format('[3] Ferramenta MCP localizada no Registry: %s (%s)', [ToolDef.Name, ToolDef.Description]));

    // 4. Execução da ferramenta via Registry + ResultCallback com Secret Store de Ambiente
    var EnvironmentToken := GetEnvironmentVariable('DEXT_MCP_AGENT_TOKEN');
    if EnvironmentToken = '' then
      raise Exception.Create(
        'Configure DEXT_MCP_AGENT_TOKEN externamente antes de executar o exemplo.');

    Writeln('[4a] Testando ferramenta MCP via Registry com token invalido...');
    DummyArgs := TJSONObject.Create;
    try
      DummyArgs.AddPair('agent_token', 'invalid_token');
      ToolResult := ToolDef.ResultCallback(DummyArgs);
      if Length(ToolResult.Content) > 0 then
        Writeln('    Resultado MCP (Sem Token Esperado): ', ToolResult.Content[0].TextValue);
    finally
      DummyArgs.Free;
    end;

    // Teste 4b: usa exclusivamente o secret herdado do ambiente do processo.
    Writeln('[4b] Executando via Registry com token fornecido pelo ambiente...');
    DummyArgs := TJSONObject.Create;
    try
      DummyArgs.AddPair('agent_token', EnvironmentToken);
      ToolResult := ToolDef.ResultCallback(DummyArgs);
    finally
      DummyArgs.Free;
    end;

    if Length(ToolResult.Content) > 0 then
      ToolText := ToolResult.Content[0].TextValue
    else
      ToolText := '';

    Writeln('    Resultado MCP (Com Token de Ambiente Validado): ', ToolText);

    HasStatus := Pos('Dext MCP Server Ativo', ToolText) > 0;

    if (ToolCount > 0) and HasStatus then
      Writeln('[SUCESSO] Servidor MCP, busca no registry e autorizacao por Secret Store validados com êxito!')
    else
      Writeln('[FALHA] Servidor MCP nao retornou a resposta esperada.');

  finally
    Server.Free;
  end;
end;

begin
  try
    TestMcpServerAndExecution;
  except
    on E: Exception do
      Writeln('[ERRO MCP]: ', E.Message);
  end;
end.
