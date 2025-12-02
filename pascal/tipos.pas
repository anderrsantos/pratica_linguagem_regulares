unit Tipos;

interface

const
  MAX_ESTADOS = 50;
  MAX_ALFABETO = 20;
  MAX_TRANSICOES = 200;
  MAX_DESTINOS = 20;
  EPSILON = 'ε';

type
  TConjuntoEstados = record
    items: array[1..MAX_ESTADOS] of string;
    count: integer;
  end;

  TConjuntoSimbolos = record
    items: array[1..MAX_ALFABETO] of string;
    count: integer;
  end;

  TDestinos = record
    items: array[1..MAX_DESTINOS] of string;
    count: integer;
  end;

  TTransicao = record
    origem: string;
    simbolo: string;
    destinos: TDestinos;
  end;

  TTransicoes = record
    items: array[1..MAX_TRANSICOES] of TTransicao;
    count: integer;
  end;

  TAutomato = record
    alfabeto: TConjuntoSimbolos;
    estados: TConjuntoEstados;
    iniciais: TConjuntoEstados;
    finais: TConjuntoEstados;
    transicoes: TTransicoes;
  end;

implementation

end.
