unit Conversores;

interface

uses Tipos, Utilidades, SysUtils;

{ Converter Múltiplos Iniciais → AFN-ε }
function ConverterMultiParaAFNE(var automato: TAutomato): boolean;

{ Converter AFN-ε → AFN }
function ConverterAFNEparaAFN(var automato: TAutomato): boolean;

{ Converter AFN → AFD }
function ConverterAFNparaAFD(var automato: TAutomato; var afd: TAutomato): boolean;

{ Minimizar AFD }
function MinimizarAFD(var automato: TAutomato; var afdMin: TAutomato): boolean;

function PossuiTransicoesEpsilon(var automato: TAutomato): boolean;
function EhDeterministico(var automato: TAutomato): boolean;

implementation

{ Calcula o fecho-epsilon de um estado específico }
procedure FechoEpsilonEstado(var automato: TAutomato; estado: string; var fecho: TConjuntoEstados);
var
  pilha: array[1..MAX_ESTADOS] of string;
  topoPilha: integer;
  atual: string;
  destinos: TDestinos;
  i: integer;
begin
  InicializarConjuntoEstados(fecho);
  if Length(estado) = 0 then
    Exit;
    
  AdicionarEstado(fecho, estado);
  
  { Inicializa pilha }
  topoPilha := 1;
  pilha[topoPilha] := estado;
  
  while topoPilha > 0 do
  begin
    { Remove do topo da pilha }
    atual := pilha[topoPilha];
    Dec(topoPilha);
    
    { Obtém transições epsilon }
    destinos := ObterDestinos(automato.transicoes, atual, EPSILON);
    
    { Adiciona novos estados ao fecho e à pilha }
    for i := 1 to destinos.count do
      if not ContemEstado(fecho, destinos.items[i]) then
      begin
        AdicionarEstado(fecho, destinos.items[i]);
        if topoPilha < MAX_ESTADOS then
        begin
          Inc(topoPilha);
          pilha[topoPilha] := destinos.items[i];
        end;
      end;
  end;
end;

function ConverterMultiParaAFNE(var automato: TAutomato): boolean;
var
  novoEstado: string;
  i: integer;
  contador: integer;
begin
  ConverterMultiParaAFNE := false;
  
  if automato.iniciais.count <= 1 then
  begin
    WriteLn;
    WriteLn('O autômato possui apenas 1 estado inicial (ou nenhum). Não é um autômato com múltiplos iniciais. Nenhuma conversão foi realizada.');
    Exit;
  end;
  
  { Gera nome único para novo estado inicial }
  novoEstado := 'Q_novo_inicial';
  contador := 0;
  while ContemEstado(automato.estados, novoEstado) do
  begin
    novoEstado := 'Q' + IntToStr(contador) + '_novo';
    Inc(contador);
  end;
  
  WriteLn;
  WriteLn('Autômato original tinha ', automato.iniciais.count, ' estados iniciais.');
  WriteLn('Novo estado inicial único criado: ', novoEstado);
  
  { Adiciona novo estado }
  AdicionarEstado(automato.estados, novoEstado);
  
  { Adiciona transições epsilon do novo estado para todos os estados iniciais antigos }
  for i := 1 to automato.iniciais.count do
    AdicionarTransicao(automato.transicoes, novoEstado, EPSILON, automato.iniciais.items[i]);
  
  { Substitui estados iniciais }
  InicializarConjuntoEstados(automato.iniciais);
  AdicionarEstado(automato.iniciais, novoEstado);
  
  ConverterMultiParaAFNE := true;
end;

function ConverterAFNEparaAFN(var automato: TAutomato): boolean;
var
  i, j, k: integer;
  temEpsilon: boolean;
  fechos: array[1..MAX_ESTADOS] of TConjuntoEstados;
  novasTrans: TTransicoes;
  novosFinais: TConjuntoEstados;
  novosIniciais: TConjuntoEstados;
  destinos: TDestinos;
  fechoTemp: TConjuntoEstados;
  m, n: integer;
begin
  ConverterAFNEparaAFN := false;
  
  { Verifica se há transições epsilon }
  temEpsilon := false;
  for i := 1 to automato.transicoes.count do
    if automato.transicoes.items[i].simbolo = EPSILON then
    begin
      temEpsilon := true;
      Break;
    end;
  
  if not temEpsilon then
  begin
    WriteLn;
    WriteLn('Este autômato já é um AFN normal (não possui transições ε). Nenhuma conversão foi realizada.');
    Exit;
  end;
  
  { Inicializa todos os conjuntos de fechos }
  for i := 1 to MAX_ESTADOS do
    InicializarConjuntoEstados(fechos[i]);
  
  { Calcula fecho-epsilon para cada estado }
  for i := 1 to automato.estados.count do
  begin
    if i <= MAX_ESTADOS then
    begin
      FechoEpsilonEstado(automato, automato.estados.items[i], fechos[i]);
    end;
  end;
  
  
  { Cria nova tabela de transições sem epsilon }
  InicializarTransicoes(novasTrans);
  
  for i := 1 to automato.estados.count do
    for j := 1 to automato.alfabeto.count do
    begin
      { Para cada estado no fecho-epsilon do estado i }
      for k := 1 to fechos[i].count do
      begin
        destinos := ObterDestinos(automato.transicoes, fechos[i].items[k], automato.alfabeto.items[j]);
        
        { Para cada destino, adiciona seu fecho-epsilon }
        for m := 1 to destinos.count do
        begin
          FechoEpsilonEstado(automato, destinos.items[m], fechoTemp);
          { Adiciona todos os estados do fecho como destinos }
          for n := 1 to fechoTemp.count do
            AdicionarTransicao(novasTrans, automato.estados.items[i], automato.alfabeto.items[j], fechoTemp.items[n]);
        end;
      end;
    end;
  
  { Novos estados finais: estados cujo fecho contém um estado final original }
  InicializarConjuntoEstados(novosFinais);
  for i := 1 to automato.estados.count do
    for j := 1 to fechos[i].count do
      if ContemEstado(automato.finais, fechos[i].items[j]) then
      begin
        AdicionarEstado(novosFinais, automato.estados.items[i]);
        Break;
      end;
  
  { Novos estados iniciais: união dos fechos dos estados iniciais originais }
  InicializarConjuntoEstados(novosIniciais);
  for i := 1 to automato.iniciais.count do
  begin
    { Encontra o índice do estado inicial no array de estados }
    for k := 1 to automato.estados.count do
      if automato.estados.items[k] = automato.iniciais.items[i] then
        for j := 1 to fechos[k].count do
          AdicionarEstado(novosIniciais, fechos[k].items[j]);
  end;
  
  { Atualiza autômato }
  automato.transicoes := novasTrans;
  automato.finais := novosFinais;
  automato.iniciais := novosIniciais;
  
  ConverterAFNEparaAFN := true;
end;

{ Funções auxiliares para AFN → AFD }
function NomeSubconjunto(var estados: TConjuntoEstados): string;
var
  i: integer;
begin
  if estados.count = 0 then
    NomeSubconjunto := '∅'
  else
  begin
    NomeSubconjunto := estados.items[1];
    for i := 2 to estados.count do
      NomeSubconjunto := NomeSubconjunto + ',' + estados.items[i];
  end;
end;

function ConjuntosIguais(var c1, c2: TConjuntoEstados): boolean;
var
  i: integer;
begin
  ConjuntosIguais := false;
  if c1.count <> c2.count then
    Exit;
  
  for i := 1 to c1.count do
    if not ContemEstado(c2, c1.items[i]) then
      Exit;
  
  ConjuntosIguais := true;
end;

function PossuiTransicoesEpsilon(var automato: TAutomato): boolean;
var
  i: integer;
begin
  PossuiTransicoesEpsilon := false;
  for i := 1 to automato.transicoes.count do
    if automato.transicoes.items[i].simbolo = EPSILON then
    begin
      PossuiTransicoesEpsilon := true;
      Exit;
    end;
end;

function EhDeterministico(var automato: TAutomato): boolean;
var
  i: integer;
begin
  EhDeterministico := false;
  if automato.iniciais.count <> 1 then
    Exit;
  if PossuiTransicoesEpsilon(automato) then
    Exit;
  for i := 1 to automato.transicoes.count do
    if automato.transicoes.items[i].destinos.count <> 1 then
      Exit;
  EhDeterministico := true;
end;

function ObterIndiceEstado(var automato: TAutomato; estado: string): integer;
var
  i: integer;
begin
  ObterIndiceEstado := -1;
  for i := 1 to automato.estados.count do
    if automato.estados.items[i] = estado then
    begin
      ObterIndiceEstado := i;
      Exit;
    end;
end;

function ConverterAFNparaAFD(var automato: TAutomato; var afd: TAutomato): boolean;
var
  i, j, k, m: integer;
  fila: array[1..MAX_ESTADOS] of TConjuntoEstados;
  visitados: array[1..MAX_ESTADOS] of TConjuntoEstados;
  numFila, numVisitados: integer;
  atual, proximo: TConjuntoEstados;
  nomeAtual, nomeProximo: string;
  destinos: TDestinos;
  encontrado: boolean;
  estadoMorto: boolean;
begin
  ConverterAFNparaAFD := false;
  InicializarAutomato(afd);
  
  { Verifica presença de epsilon }
  if PossuiTransicoesEpsilon(automato) then
  begin
    WriteLn('AFN contém transições ε. Use a conversão AFN-ε → AFN antes (opção 1).');
    Exit;
  end;
  
  { Copia alfabeto }
  afd.alfabeto := automato.alfabeto;
  
  { Inicializa com estados iniciais do AFN }
  numFila := 1;
  numVisitados := 0;
  estadoMorto := false;
  fila[1] := automato.iniciais;
  
  while numFila > 0 do
  begin
    { Remove da fila }
    atual := fila[numFila];
    Dec(numFila);
    
    { Verifica se já foi visitado }
    encontrado := false;
    for i := 1 to numVisitados do
      if ConjuntosIguais(atual, visitados[i]) then
      begin
        encontrado := true;
        Break;
      end;
    
    if encontrado then
      Continue;
    
    { Marca como visitado }
    Inc(numVisitados);
    visitados[numVisitados] := atual;
    
    nomeAtual := NomeSubconjunto(atual);
    AdicionarEstado(afd.estados, nomeAtual);
    
    { Verifica se é final }
    for i := 1 to atual.count do
      if ContemEstado(automato.finais, atual.items[i]) then
      begin
        AdicionarEstado(afd.finais, nomeAtual);
        Break;
      end;
    
    { Processa transições para cada símbolo }
    for j := 1 to automato.alfabeto.count do
    begin
      InicializarConjuntoEstados(proximo);
      
      { Para cada estado no subconjunto atual }
      for k := 1 to atual.count do
      begin
        destinos := ObterDestinos(automato.transicoes, atual.items[k], automato.alfabeto.items[j]);
        for m := 1 to destinos.count do
          AdicionarEstado(proximo, destinos.items[m]);
      end;
      
      if proximo.count = 0 then
      begin
        { Transição vai para estado morto }
        AdicionarTransicao(afd.transicoes, nomeAtual, automato.alfabeto.items[j], '∅');
        estadoMorto := true;
      end
      else
      begin
        nomeProximo := NomeSubconjunto(proximo);
        AdicionarTransicao(afd.transicoes, nomeAtual, automato.alfabeto.items[j], nomeProximo);
        
        { Adiciona à fila se não foi visitado }
        encontrado := false;
        for i := 1 to numVisitados do
          if ConjuntosIguais(proximo, visitados[i]) then
          begin
            encontrado := true;
            Break;
          end;
        
        if not encontrado then
        begin
          Inc(numFila);
          fila[numFila] := proximo;
        end;
      end;
    end;
  end;
  
  { Se há estado morto, adiciona seus laços }
  if estadoMorto then
  begin
    AdicionarEstado(afd.estados, '∅');
    for i := 1 to afd.alfabeto.count do
      AdicionarTransicao(afd.transicoes, '∅', afd.alfabeto.items[i], '∅');
  end;
  
  { Define estado inicial do AFD }
  InicializarConjuntoEstados(afd.iniciais);
  AdicionarEstado(afd.iniciais, NomeSubconjunto(automato.iniciais));
  
  ConverterAFNparaAFD := true;
end;

function MinimizarAFD(var automato: TAutomato; var afdMin: TAutomato): boolean;
var
  numEstados, numSimbolos: integer;
  destinosIdx: array[1..MAX_ESTADOS, 1..MAX_ALFABETO] of integer;
  marcados: array[1..MAX_ESTADOS, 1..MAX_ESTADOS] of boolean;
  finaisBool: array[1..MAX_ESTADOS] of boolean;
  grupos: array[1..MAX_ESTADOS] of integer;
  representante: array[1..MAX_ESTADOS] of integer;
  grupoEstados: array[1..MAX_ESTADOS] of TConjuntoEstados;
  grupoNomes: array[1..MAX_ESTADOS] of string;
  i, j, k: integer;
  destinos: TDestinos;
  di, dj, a, b: integer;
  mudou: boolean;
  grupoEncontrado, grupoCount: integer;
  estadoInicialIdx, grupoInicial: integer;
  repIdx, destIdx, destGrupo: integer;
begin
  MinimizarAFD := false;
  if automato.estados.count = 0 then
  begin
    WriteLn('Autômato não possui estados para minimizar.');
    Exit;
  end;
  
  if not EhDeterministico(automato) then
  begin
    WriteLn('Autômato fornecido não é determinístico. Converta para AFD antes de minimizar.');
    Exit;
  end;
  
  numEstados := automato.estados.count;
  numSimbolos := automato.alfabeto.count;
  
  for i := 1 to MAX_ESTADOS do
  begin
    for j := 1 to MAX_ALFABETO do
      destinosIdx[i][j] := 0;
    for j := 1 to MAX_ESTADOS do
      marcados[i][j] := false;
    grupos[i] := 0;
    representante[i] := 0;
    InicializarConjuntoEstados(grupoEstados[i]);
    grupoNomes[i] := '';
  end;
  
  for i := 1 to numEstados do
    finaisBool[i] := ContemEstado(automato.finais, automato.estados.items[i]);
  
  for i := 1 to numEstados do
    for j := 1 to numSimbolos do
    begin
      destinos := ObterDestinos(automato.transicoes, automato.estados.items[i], automato.alfabeto.items[j]);
      if destinos.count > 0 then
      begin
        destIdx := ObterIndiceEstado(automato, destinos.items[1]);
        if destIdx = -1 then
          destIdx := 0;
        destinosIdx[i][j] := destIdx;
      end
      else
        destinosIdx[i][j] := 0;
    end;
  
  for i := 1 to numEstados do
    for j := i + 1 to numEstados do
      if finaisBool[i] <> finaisBool[j] then
        marcados[i][j] := true;
  
  repeat
    mudou := false;
    for i := 1 to numEstados do
      for j := i + 1 to numEstados do
        if not marcados[i][j] then
        begin
          for k := 1 to numSimbolos do
          begin
            di := destinosIdx[i][k];
            dj := destinosIdx[j][k];
            if (di = 0) and (dj = 0) then
              Continue;
            if (di = 0) xor (dj = 0) then
            begin
              marcados[i][j] := true;
              mudou := true;
              Break;
            end;
            if di = dj then
              Continue;
            a := di;
            b := dj;
            if a > b then
            begin
              a := dj;
              b := di;
            end;
            if marcados[a][b] then
            begin
              marcados[i][j] := true;
              mudou := true;
              Break;
            end;
          end;
        end;
  until not mudou;
  
  grupoCount := 0;
  for i := 1 to numEstados do
  begin
    grupoEncontrado := 0;
    for j := 1 to i - 1 do
      if not marcados[j][i] then
      begin
        grupoEncontrado := grupos[j];
        Break;
      end;
    if grupoEncontrado = 0 then
    begin
      Inc(grupoCount);
      grupos[i] := grupoCount;
      representante[grupoCount] := i;
    end
    else
      grupos[i] := grupoEncontrado;
    AdicionarEstado(grupoEstados[grupos[i]], automato.estados.items[i]);
  end;
  
  InicializarAutomato(afdMin);
  afdMin.alfabeto := automato.alfabeto;
  for i := 1 to grupoCount do
  begin
    grupoNomes[i] := 'Q' + IntToStr(i);
    AdicionarEstado(afdMin.estados, grupoNomes[i]);
  end;
  
  InicializarConjuntoEstados(afdMin.iniciais);
  estadoInicialIdx := ObterIndiceEstado(automato, automato.iniciais.items[1]);
  if estadoInicialIdx <> -1 then
  begin
    grupoInicial := grupos[estadoInicialIdx];
    if grupoInicial <> 0 then
      AdicionarEstado(afdMin.iniciais, grupoNomes[grupoInicial]);
  end;
  
  for i := 1 to grupoCount do
    for j := 1 to grupoEstados[i].count do
      if ContemEstado(automato.finais, grupoEstados[i].items[j]) then
      begin
        AdicionarEstado(afdMin.finais, grupoNomes[i]);
        Break;
      end;
  
  for i := 1 to grupoCount do
  begin
    repIdx := representante[i];
    if repIdx = 0 then
      Continue;
    for j := 1 to numSimbolos do
    begin
      destIdx := destinosIdx[repIdx][j];
      if destIdx = 0 then
        Continue;
      destGrupo := grupos[destIdx];
      if destGrupo = 0 then
        Continue;
      AdicionarTransicao(afdMin.transicoes, grupoNomes[i], automato.alfabeto.items[j], grupoNomes[destGrupo]);
    end;
  end;
  
  MinimizarAFD := true;
end;

end.
