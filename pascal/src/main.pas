program AutomatosFinitos;

uses
  Tipos, Utilidades, LeitorJSON, Simulador, Conversores, SysUtils;

const
  DEFAULT_JSON_PATH = 'automatos/automato.json';

function ResolverCaminhoJSON(const entrada: string): string;
var
  caminhoLimpo, fallback: string;
begin
  caminhoLimpo := Trim(entrada);
  if caminhoLimpo = '' then
    caminhoLimpo := DEFAULT_JSON_PATH;

  if FileExists(caminhoLimpo) then
    Exit(caminhoLimpo);

  fallback := IncludeTrailingPathDelimiter('automatos') + ExtractFileName(caminhoLimpo);
  if FileExists(fallback) then
    Exit(fallback);

  ResolverCaminhoJSON := caminhoLimpo;
end;

procedure ImprimirAutomato(var automato: TAutomato; titulo: string);
var
  i, j: integer;
begin
  WriteLn;
  WriteLn('=========================');
  WriteLn(titulo);
  WriteLn('=========================');
  WriteLn;
  
  Write('Alfabeto: ');
  for i := 1 to automato.alfabeto.count do
  begin
    Write(automato.alfabeto.items[i]);
    if i < automato.alfabeto.count then
      Write(', ');
  end;
  WriteLn;
  
  Write('Estados: ');
  for i := 1 to automato.estados.count do
  begin
    Write(automato.estados.items[i]);
    if i < automato.estados.count then
      Write(', ');
  end;
  WriteLn;
  
  Write('Estados Iniciais: ');
  for i := 1 to automato.iniciais.count do
  begin
    Write(automato.iniciais.items[i]);
    if i < automato.iniciais.count then
      Write(', ');
  end;
  WriteLn;
  
  Write('Estados Finais: ');
  for i := 1 to automato.finais.count do
  begin
    Write(automato.finais.items[i]);
    if i < automato.finais.count then
      Write(', ');
  end;
  WriteLn;
  
  WriteLn('Transições:');
  for i := 1 to automato.transicoes.count do
  begin
    for j := 1 to automato.transicoes.items[i].destinos.count do
      WriteLn(automato.transicoes.items[i].origem, ' --', 
              automato.transicoes.items[i].simbolo, '--> ', 
              automato.transicoes.items[i].destinos.items[j]);
  end;
  WriteLn('=========================');
  WriteLn;
end;

procedure ConverterMultiParaAFNECLI;
var
  automato: TAutomato;
  modo, caminho: string;
begin
  WriteLn;
  WriteLn('=========================');
  WriteLn('Converter Múltiplos Iniciais → AFN-ε');
  WriteLn('=========================');
  WriteLn;
  
  WriteLn('1 - Carregar AFN de arquivo JSON (ex: automato.json)');
  WriteLn('2 - Informar AFN pelo terminal');
  Write('Escolha o modo (1/2): ');
  ReadLn(modo);
  
  if modo = '1' then
  begin
    Write('Nome do arquivo JSON [automato.json]: ');
    ReadLn(caminho);
    caminho := ResolverCaminhoJSON(caminho);
    
    if not CarregarAutomatoJSON(caminho, automato) then
    begin
      WriteLn('Erro ao carregar JSON.');
      Exit;
    end;
  end
  else if modo = '2' then
  begin
    if not CarregarAutomatoInterativo(automato) then
    begin
      WriteLn('Erro ao criar AFN.');
      Exit;
    end;
  end
  else
  begin
    WriteLn('Opção inválida.');
    Exit;
  end;
  
  if ConverterMultiParaAFNE(automato) then
    ImprimirAutomato(automato, 'AFN-ε Resultante (com 1 estado inicial)');
end;

procedure ConverterAFNEparaAFNCLI;
var
  automato: TAutomato;
  modo, caminho: string;
begin
  InicializarAutomato(automato);
  WriteLn;
  WriteLn('=========================');
  WriteLn('Conversor AFNε → AFN (múltiplos estados iniciais)');
  WriteLn('=========================');
  WriteLn;
  
  WriteLn('1 - Carregar AFN-ε de arquivo JSON (ex: automato.json)');
  WriteLn('2 - Informar AFN-ε pelo terminal');
  Write('Escolha o modo (1/2): ');
  ReadLn(modo);
  
  if modo = '1' then
  begin
    Write('Nome do arquivo JSON [automato.json]: ');
    ReadLn(caminho);
    caminho := ResolverCaminhoJSON(caminho);
    
    if not CarregarAutomatoJSON(caminho, automato) then
    begin
      WriteLn('Erro ao carregar JSON.');
      Exit;
    end;
  end
  else if modo = '2' then
  begin
    if not CarregarAutomatoInterativo(automato) then
    begin
      WriteLn('Erro ao criar AFN-ε.');
      Exit;
    end;
  end
  else
  begin
    WriteLn('Opção inválida.');
    Exit;
  end;
  
  if ConverterAFNEparaAFN(automato) then
  begin
    ImprimirAutomato(automato, 'AFN resultante (sem ε)');
  end;
end;

procedure ConverterAFNparaAFDCLI;
var
  automato, afd: TAutomato;
  modo, caminho: string;
begin
  WriteLn;
  WriteLn('=========================');
  WriteLn('Converter AFN → AFD (método dos subconjuntos)');
  WriteLn('=========================');
  WriteLn;
  
  WriteLn('1 - Carregar AFN de arquivo JSON (ex: automato.json)');
  WriteLn('2 - Informar AFN pelo terminal');
  Write('Escolha o modo (1/2): ');
  ReadLn(modo);
  
  if modo = '1' then
  begin
    Write('Nome do arquivo JSON [automato.json]: ');
    ReadLn(caminho);
    caminho := ResolverCaminhoJSON(caminho);
    
    if not CarregarAutomatoJSON(caminho, automato) then
    begin
      WriteLn('Erro ao carregar JSON.');
      Exit;
    end;
  end
  else if modo = '2' then
  begin
    if not CarregarAutomatoInterativo(automato) then
    begin
      WriteLn('Erro ao criar AFN.');
      Exit;
    end;
  end
  else
  begin
    WriteLn('Opção inválida.');
    Exit;
  end;
  
  if ConverterAFNparaAFD(automato, afd) then
    ImprimirAutomato(afd, 'AFD resultante');
end;

procedure MinimizarAFDCLI;
var
  automato, afd, minimizado: TAutomato;
  modo, caminho: string;
begin
  InicializarAutomato(automato);
  WriteLn;
  WriteLn('=========================');
  WriteLn('Minimizar AFD');
  WriteLn('=========================');
  WriteLn;
  
  WriteLn('1 - Carregar autômato de arquivo JSON (ex: automato.json)');
  WriteLn('2 - Informar autômato pelo terminal');
  Write('Escolha o modo (1/2): ');
  ReadLn(modo);
  
  if modo = '1' then
  begin
    Write('Nome do arquivo JSON [automato.json]: ');
    ReadLn(caminho);
    caminho := ResolverCaminhoJSON(caminho);
    
    if not CarregarAutomatoJSON(caminho, automato) then
    begin
      WriteLn('Erro ao carregar JSON.');
      Exit;
    end;
  end
  else if modo = '2' then
  begin
    if not CarregarAutomatoInterativo(automato) then
    begin
      WriteLn('Erro ao criar autômato.');
      Exit;
    end;
  end
  else
  begin
    WriteLn('Opção inválida.');
    Exit;
  end;
  
  if PossuiTransicoesEpsilon(automato) then
  begin
    WriteLn('Autômato possui transições ε. Convertendo AFN-ε → AFN...');
    if not ConverterAFNEparaAFN(automato) then
      Exit;
  end;
  
  if not EhDeterministico(automato) then
  begin
    WriteLn('Autômato não é determinístico. Convertendo AFN → AFD...');
    if not ConverterAFNparaAFD(automato, afd) then
    begin
      WriteLn('Erro ao converter AFN para AFD.');
      Exit;
    end;
    automato := afd;
  end;
  
  if MinimizarAFD(automato, minimizado) then
    ImprimirAutomato(minimizado, 'AFD minimizado');
end;

procedure TestarPalavraCLIMenu;
var
  automato: TAutomato;
  modo, caminho, modoPalavra: string;
begin
  WriteLn;
  WriteLn('=========================');
  WriteLn('Testar palavra em autômato (JSON ou terminal)');
  WriteLn('=========================');
  WriteLn;
  
  WriteLn('1 - Carregar de arquivo JSON (ex: automato.json)');
  WriteLn('2 - Informar o autômato pelo terminal');
  Write('Escolha o modo (1/2): ');
  ReadLn(modo);
  
  if modo = '1' then
  begin
    Write('Nome do arquivo JSON [automato.json]: ');
    ReadLn(caminho);
    caminho := ResolverCaminhoJSON(caminho);
    
    if not CarregarAutomatoJSON(caminho, automato) then
    begin
      WriteLn('Erro ao carregar JSON.');
      Exit;
    end;
  end
  else if modo = '2' then
  begin
    if not CarregarAutomatoInterativo(automato) then
    begin
      WriteLn('Erro ao criar autômato.');
      Exit;
    end;
  end
  else
  begin
    WriteLn('Opção inválida.');
    Exit;
  end;
  
  WriteLn;
  WriteLn('Como deseja testar palavras?');
  WriteLn('1 - Digitar manualmente');
  WriteLn('2 - Ler de arquivo TXT (uma palavra por linha)');
  Write('Escolha o modo (1/2): ');
  ReadLn(modoPalavra);
  
  if modoPalavra = '2' then
  begin
    Write('Caminho do arquivo TXT: ');
    ReadLn(caminho);
    TestarPalavrasArquivo(automato, caminho);
  end
  else
    TestarPalavraCLI(automato);
end;

procedure MenuPrincipal;
var
  opcao: string;
  opcaoInt, erro: integer;
  continuar: boolean;
begin
  continuar := true;
  opcaoInt := -1;
  
  while continuar do
  begin
    WriteLn;
    WriteLn('=========================');
    WriteLn('          MENU           ');
    WriteLn('=========================');
    WriteLn;
    WriteLn('0 - Converter multiestado inicial para AFN-ε');
    WriteLn('1 - Converter AFN-ε para AFN');
    WriteLn('2 - Converter AFN para AFD');
    WriteLn('3 - Minimizar AFD');
    WriteLn('4 - Testar palavra');
    WriteLn('5 - Sair');
    WriteLn;
    Write('Escolha uma opção: ');
    ReadLn(opcao);
    
    opcaoInt := -1;
    Val(opcao, opcaoInt, erro);
    
    if erro <> 0 then
    begin
      WriteLn('Opção inválida. Tente novamente.');
      Continue;
    end;
    
    case opcaoInt of
      0: ConverterMultiParaAFNECLI;
      1: ConverterAFNEparaAFNCLI;
      2: ConverterAFNparaAFDCLI;
      3: MinimizarAFDCLI;
      4: TestarPalavraCLIMenu;
      5: begin
           WriteLn('Saindo...');
           continuar := false;
         end;
    else
      WriteLn('Opção inválida. Tente novamente.');
    end;
  end;
end;

begin
  MenuPrincipal;
end.
