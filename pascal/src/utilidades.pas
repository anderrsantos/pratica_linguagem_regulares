unit Utilidades;

interface

uses Tipos;

{ Funções auxiliares para conjuntos }
function ContemEstado(var conjunto: TConjuntoEstados; estado: string): boolean;
procedure AdicionarEstado(var conjunto: TConjuntoEstados; estado: string);
procedure RemoverEstado(var conjunto: TConjuntoEstados; estado: string);
function ContemSimbolo(var conjunto: TConjuntoSimbolos; simbolo: string): boolean;
procedure AdicionarSimbolo(var conjunto: TConjuntoSimbolos; simbolo: string);
procedure AdicionarDestino(var destinos: TDestinos; destino: string);
function ContemDestino(var destinos: TDestinos; destino: string): boolean;

{ Funções para transições }
function BuscarTransicao(var trans: TTransicoes; origem, simbolo: string): integer;
procedure AdicionarTransicao(var trans: TTransicoes; origem, simbolo, destino: string);
function ObterDestinos(var trans: TTransicoes; origem, simbolo: string): TDestinos;

{ Funções de string }
function Trim(s: string): string;
procedure Split(texto, delimitador: string; var resultado: TConjuntoEstados);

{ Inicializadores }
procedure InicializarConjuntoEstados(var conjunto: TConjuntoEstados);
procedure InicializarConjuntoSimbolos(var conjunto: TConjuntoSimbolos);
procedure InicializarDestinos(var destinos: TDestinos);
procedure InicializarTransicoes(var trans: TTransicoes);
procedure InicializarAutomato(var automato: TAutomato);

implementation

function Trim(s: string): string;
var
  i, inicio, fim: integer;
begin
  inicio := 1;
  fim := Length(s);
  
  while (inicio <= fim) and (s[inicio] = ' ') do
    Inc(inicio);
  
  while (fim >= inicio) and (s[fim] = ' ') do
    Dec(fim);
  
  if inicio > fim then
    Trim := ''
  else
    Trim := Copy(s, inicio, fim - inicio + 1);
end;

procedure Split(texto, delimitador: string; var resultado: TConjuntoEstados);
var
  pos, i: integer;
  parte: string;
begin
  InicializarConjuntoEstados(resultado);
  i := 1;
  
  while i <= Length(texto) do
  begin
    pos := i;
    while (pos <= Length(texto)) and (texto[pos] <> delimitador[1]) do
      Inc(pos);
    
    parte := Trim(Copy(texto, i, pos - i));
    if Length(parte) > 0 then
      AdicionarEstado(resultado, parte);
    
    i := pos + 1;
  end;
end;

procedure InicializarConjuntoEstados(var conjunto: TConjuntoEstados);
begin
  conjunto.count := 0;
end;

procedure InicializarConjuntoSimbolos(var conjunto: TConjuntoSimbolos);
begin
  conjunto.count := 0;
end;

procedure InicializarDestinos(var destinos: TDestinos);
begin
  destinos.count := 0;
end;

procedure InicializarTransicoes(var trans: TTransicoes);
begin
  trans.count := 0;
end;

procedure InicializarAutomato(var automato: TAutomato);
begin
  InicializarConjuntoSimbolos(automato.alfabeto);
  InicializarConjuntoEstados(automato.estados);
  InicializarConjuntoEstados(automato.iniciais);
  InicializarConjuntoEstados(automato.finais);
  InicializarTransicoes(automato.transicoes);
end;

function ContemEstado(var conjunto: TConjuntoEstados; estado: string): boolean;
var
  i: integer;
begin
  ContemEstado := false;
  for i := 1 to conjunto.count do
    if conjunto.items[i] = estado then
    begin
      ContemEstado := true;
      Exit;
    end;
end;

procedure AdicionarEstado(var conjunto: TConjuntoEstados; estado: string);
begin
  if not ContemEstado(conjunto, estado) then
  begin
    if conjunto.count < MAX_ESTADOS then
    begin
      Inc(conjunto.count);
      conjunto.items[conjunto.count] := estado;
    end;
  end;
end;

procedure RemoverEstado(var conjunto: TConjuntoEstados; estado: string);
var
  i, j: integer;
begin
  for i := 1 to conjunto.count do
    if conjunto.items[i] = estado then
    begin
      for j := i to conjunto.count - 1 do
        conjunto.items[j] := conjunto.items[j + 1];
      Dec(conjunto.count);
      Exit;
    end;
end;

function ContemSimbolo(var conjunto: TConjuntoSimbolos; simbolo: string): boolean;
var
  i: integer;
begin
  ContemSimbolo := false;
  for i := 1 to conjunto.count do
    if conjunto.items[i] = simbolo then
    begin
      ContemSimbolo := true;
      Exit;
    end;
end;

procedure AdicionarSimbolo(var conjunto: TConjuntoSimbolos; simbolo: string);
begin
  if not ContemSimbolo(conjunto, simbolo) then
  begin
    if conjunto.count < MAX_ALFABETO then
    begin
      Inc(conjunto.count);
      conjunto.items[conjunto.count] := simbolo;
    end;
  end;
end;

function ContemDestino(var destinos: TDestinos; destino: string): boolean;
var
  i: integer;
begin
  ContemDestino := false;
  for i := 1 to destinos.count do
    if destinos.items[i] = destino then
    begin
      ContemDestino := true;
      Exit;
    end;
end;

procedure AdicionarDestino(var destinos: TDestinos; destino: string);
begin
  if not ContemDestino(destinos, destino) then
  begin
    if destinos.count < MAX_DESTINOS then
    begin
      Inc(destinos.count);
      destinos.items[destinos.count] := destino;
    end;
  end;
end;

function BuscarTransicao(var trans: TTransicoes; origem, simbolo: string): integer;
var
  i: integer;
begin
  BuscarTransicao := -1;
  for i := 1 to trans.count do
    if (trans.items[i].origem = origem) and (trans.items[i].simbolo = simbolo) then
    begin
      BuscarTransicao := i;
      Exit;
    end;
end;

procedure AdicionarTransicao(var trans: TTransicoes; origem, simbolo, destino: string);
var
  idx: integer;
begin
  idx := BuscarTransicao(trans, origem, simbolo);
  
  if idx = -1 then
  begin
    if trans.count < MAX_TRANSICOES then
    begin
      Inc(trans.count);
      trans.items[trans.count].origem := origem;
      trans.items[trans.count].simbolo := simbolo;
      InicializarDestinos(trans.items[trans.count].destinos);
      AdicionarDestino(trans.items[trans.count].destinos, destino);
    end;
  end
  else
    AdicionarDestino(trans.items[idx].destinos, destino);
end;

function ObterDestinos(var trans: TTransicoes; origem, simbolo: string): TDestinos;
var
  idx: integer;
begin
  InicializarDestinos(ObterDestinos);
  idx := BuscarTransicao(trans, origem, simbolo);
  if idx <> -1 then
    ObterDestinos := trans.items[idx].destinos;
end;

end.
