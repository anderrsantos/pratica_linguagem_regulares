from collections import deque
from typing import Dict, Set, FrozenSet, Tuple, List

from testar_palavra import Automato


def _subset_name(subset: FrozenSet[str]) -> str:
    if not subset:
        return "∅"
    # Nomeia o subconjunto separado por vírgulas (ex.: q1,q2)
    return ",".join(sorted(subset))


def converter_afn_para_afd(afn: Automato):
    """
    Converte um AFN para um AFD usando o método dos subconjuntos.
    Retorna uma tupla (alfabeto, estados, inicial, finais, transicoes) onde:
      - alfabeto: List[str]
      - estados: List[str]
      - inicial: str (nome do estado subconjunto inicial)
      - finais: List[str]
      - transicoes: Dict[str, Dict[str, str]]  (estado_dfa --simbolo--> estado_dfa)
    """
    # Verifica presença de ε
    for o, mapa in afn.transicoes.items():
        if "ε" in mapa:
            raise ValueError("AFN contém transições ε. Use a conversão AFN-ε → AFN antes (opção 1).")

    alfabeto = sorted(list(afn.alfabeto))

    # Subconjunto inicial = conjunto de estados iniciais do AFN
    inicial_set: FrozenSet[str] = frozenset(afn.iniciais)

    fila: deque[FrozenSet[str]] = deque([inicial_set])
    visitados: Set[FrozenSet[str]] = set()

    dfa_transicoes: Dict[str, Dict[str, str]] = {}
    dfa_estados: Set[str] = set()
    dfa_finais: Set[str] = set()

    tem_estado_morto = False
    DEAD = "∅"  # estado morto/sumidouro

    while fila:
        atual = fila.popleft()
        if atual in visitados:
            continue
        visitados.add(atual)

        atual_nome = _subset_name(atual)
        dfa_estados.add(atual_nome)
        dfa_transicoes.setdefault(atual_nome, {})

        # Determina se é final
        if any(s in afn.finais for s in atual):
            dfa_finais.add(atual_nome)

        for simbolo in alfabeto:
            prox: Set[str] = set()
            for s in atual:
                prox |= afn.transicoes.get(s, {}).get(simbolo, set())

            if not prox:
                # transição vai para estado morto
                dfa_transicoes[atual_nome][simbolo] = DEAD
                tem_estado_morto = True
            else:
                prox_fs = frozenset(prox)
                prox_nome = _subset_name(prox_fs)
                dfa_transicoes[atual_nome][simbolo] = prox_nome
                if prox_fs not in visitados:
                    fila.append(prox_fs)

    # Se usamos estado morto, complete suas transições como laços
    if tem_estado_morto:
        dfa_estados.add(DEAD)
        dfa_transicoes.setdefault(DEAD, {})
        for a in alfabeto:
            dfa_transicoes[DEAD][a] = DEAD

    dfa_inicial = _subset_name(inicial_set)
    return (
        alfabeto,
        sorted(list(dfa_estados)),
        dfa_inicial,
        sorted(list(dfa_finais)),
        dfa_transicoes,
    )


def converter_afn_para_afd_cli():
    print("\n=============================================")
    print("Converter AFN → AFD (método dos subconjuntos)")
    print("=============================================\n")

    print("1 - Carregar AFN de arquivo JSON (ex: automato.json)")
    print("2 - Informar AFN pelo terminal")
    modo = input("Escolha o modo (1/2): ").strip()

    if modo == "1":
        path = input("Caminho do arquivo JSON [automato.json]: ").strip() or "automato.json"
        try:
            afn = Automato.from_json(path)
        except Exception as e:
            print(f"Erro ao carregar JSON: {e}")
            return
    elif modo == "2":
        try:
            afn = Automato.from_interactive()
        except Exception as e:
            print(f"Erro ao criar AFN: {e}")
            return
    else:
        print("Opção inválida.")
        return

    try:
        alfabeto, estados, inicial, finais, trans = converter_afn_para_afd(afn)
    except Exception as e:
        print(f"Erro na conversão: {e}")
        return

    print("\n=========================")
    print("AFD resultante")
    print("=========================\n")
    print("Alfabeto:", alfabeto)
    print("Estados:", estados)
    print("Estado Inicial:", inicial)
    print("Estados Finais:", finais)
    print("Transições:")
    for origem in sorted(trans.keys()):
        for simbolo in alfabeto:
            destino = trans[origem].get(simbolo)
            if destino is not None:
                print(f"{origem} --{simbolo}--> {destino}")
    print("=========================\n")
