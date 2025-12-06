unit LeitorJSON;

interface

uses Tipos, Utilidades, SysUtils;

function CarregarAutomatoJSON(caminho: string; var automato: TAutomato): boolean;
function CarregarAutomatoInterativo(var automato: TAutomato): boolean;

implementation

{ Parser JSON simplificado para o formato específico do projeto }
function ExtrairValor(linha: string): string;
var
  pos1, pos2: integer;
begin
  pos1 := Pos(':', linha);
  if pos1 > 0 then
  begin
    pos1 := pos1 + 1;
    linha := Copy(linha, pos1, Length(linha));
    linha := Trim(linha);
    
    { Remove [ ] ou " " }
    if (Length(linha) > 0) and (linha[1] = '[') then
    begin
      pos1 := 2;
      pos2 := Pos(']', linha);
      if pos2 > 0 then
        linha := Copy(linha, pos1, pos2 - pos1);
    end;
    
    { Remove vírgula final }
    if (Length(linha) > 0) and (linha[Length(linha)] = ',') then
      linha := Copy(linha, 1, Length(linha) - 1);
    
    ExtrairValor := Trim(linha);
  end
  else
    ExtrairValor := '';
end;

procedure ProcessarLista(texto: string; var conjunto: TConjuntoEstados);
var
  i: integer;
  elemento: string;
  dentroAspas: boolean;
  count: integer;
begin
  InicializarConjuntoEstados(conjunto);
  dentroAspas := false;
  elemento := '';
  count := 0;
  
  for i := 1 to Length(texto) do
  begin
    if texto[i] = '"' then
      dentroAspas := not dentroAspas
    else if (texto[i] = ',') and (not dentroAspas) then
    begin
      elemento := Trim(elemento);
      { Adiciona sempre, mesmo vazio, incrementando count manualmente para arrays }
      if count < MAX_ESTADOS then
      begin
        Inc(count);
        conjunto.items[count] := elemento;
      end;
      elemento := '';
    end
    else if dentroAspas or (texto[i] <> ' ') then
      elemento := elemento + texto[i];
  end;
  
  { Adiciona último elemento }
  elemento := Trim(elemento);
  if count < MAX_ESTADOS then
  begin
    Inc(count);
    conjunto.items[count] := elemento;
  end;
  conjunto.count := count;
end;

function CarregarAutomatoJSON(caminho: string; var automato: TAutomato): boolean;
var
  arquivo: Text;
  linha: string;
  valor: string;
  partes: TConjuntoEstados;
  i: integer;
begin
  CarregarAutomatoJSON := false;
  InicializarAutomato(automato);
  
  {$I-}
  Assign(arquivo, caminho);
  Reset(arquivo);
  {$I+}
  
  if IOResult <> 0 then
  begin
    WriteLn('Erro: Não foi possível abrir o arquivo ', caminho);
    Exit;
  end;
  
  while not Eof(arquivo) do
  begin
    ReadLn(arquivo, linha);
    linha := Trim(linha);
    
    if Pos('"alfabeto"', linha) > 0 then
    begin
      valor := ExtrairValor(linha);
      ProcessarLista(valor, partes);
      for i := 1 to partes.count do
        AdicionarSimbolo(automato.alfabeto, partes.items[i]);
    end
    else if Pos('"alfabet0"', linha) > 0 then
    begin
      valor := ExtrairValor(linha);
      ProcessarLista(valor, partes);
      for i := 1 to partes.count do
        AdicionarSimbolo(automato.alfabeto, partes.items[i]);
    end
    else if Pos('"estados"', linha) > 0 then
    begin
      valor := ExtrairValor(linha);
      ProcessarLista(valor, automato.estados);
    end
    else if Pos('"estadosI"', linha) > 0 then
    begin
      valor := ExtrairValor(linha);
      ProcessarLista(valor, automato.iniciais);
    end
    else if Pos('"estadosF"', linha) > 0 then
    begin
      valor := ExtrairValor(linha);
      ProcessarLista(valor, automato.finais);
    end
    else if Pos('"transicoes"', linha) > 0 then
    begin
      { Processar transições (array de arrays) }
      while not Eof(arquivo) do
      begin
        ReadLn(arquivo, linha);
        linha := Trim(linha);
        
        if Pos('[', linha) > 0 then
        begin
          { Extrair [origem, destino, simbolo] }
          valor := linha;
          while Pos('[', valor) > 0 do
            Delete(valor, Pos('[', valor), 1);
          while Pos(']', valor) > 0 do
            Delete(valor, Pos(']', valor), 1);
          while Pos('"', valor) > 0 do
            Delete(valor, Pos('"', valor), 1);
          { Remove vírgula final se existir }
          valor := Trim(valor);
          if (Length(valor) > 0) and (valor[Length(valor)] = ',') then
            Delete(valor, Length(valor), 1);
          
          valor := Trim(valor);
          if Length(valor) > 0 then
          begin
            ProcessarLista(valor, partes);
            if partes.count >= 3 then
            begin
              AdicionarTransicao(automato.transicoes, 
                               partes.items[1], 
                               partes.items[3], 
                               partes.items[2]);
            end;
          end;
        end
        else if (Pos(']', linha) > 0) and (Pos('[', linha) = 0) then
          Break;
      end;
    end;
  end;
  
  Close(arquivo);
  CarregarAutomatoJSON := true;
end;

function CarregarAutomatoInterativo(var automato: TAutomato): boolean;
var
  entrada: string;
  partes: TConjuntoEstados;
  i: integer;
  origem, simbolo, destino: string;
  posicoes: array[1..3] of integer;
  idx: integer;
begin
  CarregarAutomatoInterativo := false;
  InicializarAutomato(automato);
  
  WriteLn;
  WriteLn('=========================');
  WriteLn('Construir autômato pelo terminal');
  WriteLn('=========================');
  WriteLn;
  
  Write('Alfabeto (ex: a,b): ');
  ReadLn(entrada);
  ProcessarLista(entrada, partes);
  for i := 1 to partes.count do
    AdicionarSimbolo(automato.alfabeto, partes.items[i]);
  
  Write('Estados (ex: Q1,Q2,QF): ');
  ReadLn(entrada);
  ProcessarLista(entrada, automato.estados);
  
  Write('Estados iniciais (ex: Q1): ');
  ReadLn(entrada);
  ProcessarLista(entrada, automato.iniciais);
  
  Write('Estados finais (ex: QF): ');
  ReadLn(entrada);
  ProcessarLista(entrada, automato.finais);
  
  WriteLn('Informe as transições como ''origem,simbolo,destino''. Use ''ε'' para epsilon. Digite ''fim'' para encerrar.');
  
  repeat
    Write('Transição: ');
    ReadLn(entrada);
    entrada := Trim(entrada);
    
    if (entrada <> 'fim') and (entrada <> 'FIM') and (Length(entrada) > 0) then
    begin
      { Encontrar posições das vírgulas }
      idx := 0;
      for i := 1 to Length(entrada) do
        if entrada[i] = ',' then
        begin
          Inc(idx);
          if idx <= 3 then
            posicoes[idx] := i;
        end;
      
      if idx >= 2 then
      begin
        origem := Trim(Copy(entrada, 1, posicoes[1] - 1));
        simbolo := Trim(Copy(entrada, posicoes[1] + 1, posicoes[2] - posicoes[1] - 1));
        destino := Trim(Copy(entrada, posicoes[2] + 1, Length(entrada)));
        
        if (Length(origem) > 0) and (Length(simbolo) > 0) and (Length(destino) > 0) then
          AdicionarTransicao(automato.transicoes, origem, simbolo, destino)
        else
          WriteLn('Formato inválido. Use origem,simbolo,destino.');
      end
      else
        WriteLn('Formato inválido. Use origem,simbolo,destino.');
    end;
  until (entrada = 'fim') or (entrada = 'FIM');
  
  CarregarAutomatoInterativo := true;
end;

end.
