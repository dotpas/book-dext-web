unit DemoProvider;

interface

uses
  System.SysUtils,
  System.JSON,
  Dext.AI.MCP.Tools,
  Dext.AI.MCP.Attributes,
  Dext.AI.MCP.Types;

type
  TDemoProvider = class(TMCPToolProvider)
  public
    [MCPTool('get-server-status', 'Retorna o status atual do servidor Dext.')]
    function GetServerStatus(const Args: TJSONObject): TMCPToolResult;
  end;

implementation

function TDemoProvider.GetServerStatus(const Args: TJSONObject): TMCPToolResult;
var
  AgentToken, ExpectedToken: string;
begin
  AgentToken := '';
  if (Args <> nil) and (Args.GetValue('agent_token') <> nil) then
    AgentToken := Args.GetValue('agent_token').Value
  else if (Args <> nil) and (Args.GetValue('api_key') <> nil) then
    AgentToken := Args.GetValue('api_key').Value;

  // Carrega chave autorizada EXCLUSIVAMENTE do Secret Store de Ambiente (Sem Fallback Hardcoded)
  ExpectedToken := GetEnvironmentVariable('DEXT_MCP_AGENT_TOKEN');
  if ExpectedToken = '' then
    Exit(TMCPToolResult.Error('Falha de Seguranca MCP: Variavel DEXT_MCP_AGENT_TOKEN nao configurada no Secret Store de Ambiente.'));

  // Validação defensiva de autorização de agente IA via Secret Store
  if not SameText(AgentToken, ExpectedToken) then
    Exit(TMCPToolResult.Error('Acesso nao autorizado a ferramenta MCP. Token de agente IA invalido ou nao reconhecido pelo Secret Store.'));

  Result := TMCPToolResult.Text('Dext MCP Server Ativo e Operacional (Autorizacao de Agente IA Validada via SecretStore de Ambiente).');
end;

end.
