unit Conversores;

interface

uses Tipos, Utilidades, SysUtils;

{ Converter Múltiplos Iniciais → AFN-ε }
function ConverterMultiParaAFNE(var automato: TAutomato): boolean;

{ Converter AFN-ε → AFN }
function ConverterAFNEparaAFN(var automato: TAutomato): boolean;

{ Converter AFN → AFD }
function ConverterAFNparaAFD(var automato: TAutomato; var afd: TAutomato): boolean;

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

function ConverterAFNparaAFD(var automato: TAutomato; var afd: TAutomato): boolean;
var
  i, j, k, m: integer;
  temEpsilon: boolean;
  fila: array[1..MAX_ESTADOS] of TConjuntoEstados;
  visitados: array[1..MAX_ESTADOS] of TConjuntoEstados;
  numFila, numVisitados: integer;
  atual, proximo: TConjuntoEstados;
  nomeAtual, nomeProximo: string;
  destinos: TDestinos;
  encontrado: boolean;
  idxVisitado: integer;
  estadoMorto: boolean;
begin
  ConverterAFNparaAFD := false;
  InicializarAutomato(afd);
  
  { Verifica presença de epsilon }
  temEpsilon := false;
  for i := 1 to automato.transicoes.count do
    if automato.transicoes.items[i].simbolo = EPSILON then
    begin
      temEpsilon := true;
      Break;
    end;
  
  if temEpsilon then
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

end.
