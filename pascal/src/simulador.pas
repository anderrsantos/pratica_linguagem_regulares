unit Simulador;

interface

uses Tipos, Utilidades, SysUtils;

function TestarPalavra(var automato: TAutomato; palavra: string; var erro: string): boolean;
function ValidarPalavra(var automato: TAutomato; palavra: string; var simbolosInvalidos: string): boolean;
procedure TestarPalavraCLI(var automato: TAutomato);
procedure TestarPalavrasArquivo(var automato: TAutomato; caminhoArquivo: string);

implementation

{ Calcula o fecho-epsilon de um conjunto de estados }
procedure FechoEpsilon(var automato: TAutomato; var estados: TConjuntoEstados);
var
  pilha: TConjuntoEstados;
  atual: string;
  destinos: TDestinos;
  i, j: integer;
  mudou: boolean;
begin
  { Inicializa pilha com os estados atuais }
  pilha := estados;
  
  repeat
    mudou := false;
    for i := 1 to pilha.count do
    begin
      atual := pilha.items[i];
      destinos := ObterDestinos(automato.transicoes, atual, EPSILON);
      
      for j := 1 to destinos.count do
        if not ContemEstado(estados, destinos.items[j]) then
        begin
          AdicionarEstado(estados, destinos.items[j]);
          AdicionarEstado(pilha, destinos.items[j]);
          mudou := true;
        end;
    end;
  until not mudou;
end;

{ Move um conjunto de estados por um símbolo }
function Mover(var automato: TAutomato; var estados: TConjuntoEstados; simbolo: string): TConjuntoEstados;
var
  i, j: integer;
  destinos: TDestinos;
begin
  InicializarConjuntoEstados(Mover);
  
  for i := 1 to estados.count do
  begin
    destinos := ObterDestinos(automato.transicoes, estados.items[i], simbolo);
    for j := 1 to destinos.count do
      AdicionarEstado(Mover, destinos.items[j]);
  end;
end;

function ValidarPalavra(var automato: TAutomato; palavra: string; var simbolosInvalidos: string): boolean;
var
  i, j: integer;
  c: char;
  simbolo: string;
  encontrado: boolean;
begin
  ValidarPalavra := true;
  simbolosInvalidos := '';
  
  for i := 1 to Length(palavra) do
  begin
    c := palavra[i];
    simbolo := c;
    encontrado := false;
    
    for j := 1 to automato.alfabeto.count do
      if automato.alfabeto.items[j] = simbolo then
      begin
        encontrado := true;
        Break;
      end;
    
    if not encontrado then
    begin
      if Pos(simbolo, simbolosInvalidos) = 0 then
      begin
        if Length(simbolosInvalidos) > 0 then
          simbolosInvalidos := simbolosInvalidos + ', ';
        simbolosInvalidos := simbolosInvalidos + simbolo;
      end;
      ValidarPalavra := false;
    end;
  end;
end;

function TestarPalavra(var automato: TAutomato; palavra: string; var erro: string): boolean;
var
  estadosAtuais, proximos: TConjuntoEstados;
  i, j: integer;
  simbolo: string;
  aceita: boolean;
begin
  erro := '';
  TestarPalavra := false;
  
  { Inicializa com o fecho-epsilon dos estados iniciais }
  estadosAtuais := automato.iniciais;
  FechoEpsilon(automato, estadosAtuais);
  
  { Processa cada símbolo da palavra }
  for i := 1 to Length(palavra) do
  begin
    simbolo := palavra[i];
    proximos := Mover(automato, estadosAtuais, simbolo);
    FechoEpsilon(automato, proximos);
    estadosAtuais := proximos;
    
    if estadosAtuais.count = 0 then
      Break;
  end;
  
  { Verifica se algum estado atual é final }
  aceita := false;
  for i := 1 to estadosAtuais.count do
    for j := 1 to automato.finais.count do
      if estadosAtuais.items[i] = automato.finais.items[j] then
      begin
        aceita := true;
        Break;
      end;
  
  TestarPalavra := aceita;
end;

procedure TestarPalavraCLI(var automato: TAutomato);
var
  palavra: string;
  erro, simbolosInvalidos: string;
  aceita: boolean;
begin
  WriteLn;
  WriteLn('Digite palavras para testar. Use ENTER vazio para sair.');
  
  repeat
    Write('Palavra: ');
    ReadLn(palavra);
    
    if Length(palavra) > 0 then
    begin
      if not ValidarPalavra(automato, palavra, simbolosInvalidos) then
        WriteLn('Erro: A palavra contém símbolos fora do alfabeto: ', simbolosInvalidos)
      else
      begin
        aceita := TestarPalavra(automato, palavra, erro);
        if Length(erro) > 0 then
          WriteLn('Erro: ', erro)
        else if aceita then
          WriteLn('Resultado: ACEITA')
        else
          WriteLn('Resultado: REJEITA');
      end;
    end;
  until Length(palavra) = 0;
end;

procedure TestarPalavrasArquivo(var automato: TAutomato; caminhoArquivo: string);
var
  arquivo: Text;
  palavra: string;
  erro, simbolosInvalidos: string;
  aceita: boolean;
  linha: integer;
begin
  {$I-}
  Assign(arquivo, caminhoArquivo);
  Reset(arquivo);
  {$I+}
  
  if IOResult <> 0 then
  begin
    WriteLn('Erro ao ler arquivo TXT: ', caminhoArquivo);
    Exit;
  end;
  
  WriteLn;
  WriteLn('Testando palavras do arquivo ''', caminhoArquivo, ''':');
  WriteLn;
  
  linha := 0;
  while not Eof(arquivo) do
  begin
    ReadLn(arquivo, palavra);
    palavra := Trim(palavra);
    
    if Length(palavra) > 0 then
    begin
      Inc(linha);
      
      if not ValidarPalavra(automato, palavra, simbolosInvalidos) then
        WriteLn(linha, ': ''', palavra, ''' -> ERRO: contém símbolos fora do alfabeto: ', simbolosInvalidos)
      else
      begin
        aceita := TestarPalavra(automato, palavra, erro);
        if aceita then
          WriteLn(linha, ': ''', palavra, ''' -> ACEITA')
        else
          WriteLn(linha, ': ''', palavra, ''' -> REJEITA');
      end;
    end;
  end;
  
  Close(arquivo);
end;

end.
