from typing import Dict, List, Set, FrozenSet
from collections import defaultdict, deque
from testar_palavra import Automato
from converterAFNEpAFN import AFNEpAFN
from converterAFNparaAFD import converter_afn_para_afd


def minimizar_afd(alfabeto: List[str], estados: List[str], inicial: str,
                  finais: List[str], transicoes: Dict[str, Dict[str, str]]):
    """
    Minimiza um AFD usando o algoritmo de Hopcroft (partição refinada).

    Algoritmo:
    1. Particiona estados em finais e não-finais
    2. Refina partições iterativamente baseado em equivalência de transições
    3. Estados equivalentes são agrupados no mesmo bloco
    4. Cada bloco final representa um estado do AFD minimizado

    Parâmetros:
        alfabeto: Lista de símbolos do alfabeto
        estados: Lista de nomes dos estados
        inicial: Nome do estado inicial
        finais: Lista de estados finais
        transicoes: Dict[estado][símbolo] -> estado_destino

    Retorna:
        Tupla (alfabeto, estados, inicial, finais, transicoes) do AFD minimizado
        com estados renomeados como S0, S1, S2, ...
    """

    # Validação de entrada
    if not estados:
        raise ValueError("AFD não possui estados")
    if inicial not in estados:
        raise ValueError(f"Estado inicial '{inicial}' não está na lista de estados")

    # Conjunto de estados finais
    finais_set = set(finais)
    nao_finais_set = set(estados) - finais_set

    # Partição inicial P = {F, Q\F}
    P: Set[FrozenSet[str]] = set()
    if finais_set:
        P.add(frozenset(finais_set))
    if nao_finais_set:
        P.add(frozenset(nao_finais_set))

    # Worklist W: começa com partições não-vazias
    W: deque[FrozenSet[str]] = deque(P)

    # Algoritmo de Hopcroft
    while W:
        A = W.popleft()

        for simbolo in alfabeto:
            # X = {q | δ(q, simbolo) ∈ A}
            # Estados cujas transições por 'simbolo' levam a algum estado em A
            X: Set[str] = set()
            for q in estados:
                destino = transicoes.get(q, {}).get(simbolo)
                if destino and destino in A:
                    X.add(q)

            # Para cada bloco Y em P
            P_copy = list(P)
            for Y in P_copy:
                # Interseção e diferença
                Y_inter_X = Y & X
                Y_minus_X = Y - X

                # Se Y intersecta X mas não está contido em X
                if Y_inter_X and Y_minus_X:
                    # Remove Y de P
                    P.discard(Y)

                    # Adiciona as duas partes
                    P.add(frozenset(Y_inter_X))
                    P.add(frozenset(Y_minus_X))

                    # Atualiza worklist
                    if Y in W:
                        W.remove(Y)
                        W.append(frozenset(Y_inter_X))
                        W.append(frozenset(Y_minus_X))
                    else:
                        # Adiciona o menor bloco
                        if len(Y_inter_X) <= len(Y_minus_X):
                            W.append(frozenset(Y_inter_X))
                        else:
                            W.append(frozenset(Y_minus_X))

    # Construir AFD minimizado
    # Mapeia cada estado ao seu bloco
    estado_para_bloco: Dict[str, FrozenSet[str]] = {}
    for bloco in P:
        for estado in bloco:
            estado_para_bloco[estado] = bloco

    # Cria nomes para blocos (S0, S1, ...)
    blocos_lista = sorted(list(P), key=lambda b: (inicial not in b, min(b)))
    bloco_para_nome: Dict[FrozenSet[str], str] = {}
    for idx, bloco in enumerate(blocos_lista):
        bloco_para_nome[bloco] = f"S{idx}"

    # Estado inicial minimizado
    bloco_inicial = estado_para_bloco[inicial]
    novo_inicial = bloco_para_nome[bloco_inicial]

    # Estados finais minimizados
    novos_finais: Set[str] = set()
    for f in finais:
        bloco = estado_para_bloco[f]
        novos_finais.add(bloco_para_nome[bloco])

    # Transições minimizadas
    novas_transicoes: Dict[str, Dict[str, str]] = {}
    for bloco in P:
        # Escolhe um representante do bloco
        representante = min(bloco)
        nome_bloco = bloco_para_nome[bloco]
        novas_transicoes[nome_bloco] = {}

        for simbolo in alfabeto:
            destino = transicoes.get(representante, {}).get(simbolo)
            if destino:
                bloco_destino = estado_para_bloco[destino]
                nome_destino = bloco_para_nome[bloco_destino]
                novas_transicoes[nome_bloco][simbolo] = nome_destino

    novos_estados = sorted(list(bloco_para_nome.values()))
    novos_finais_lista = sorted(list(novos_finais))

    return (alfabeto, novos_estados, novo_inicial, novos_finais_lista, novas_transicoes)


def minimizar_afd_cli():
    """
    Interface CLI para minimização de AFD.
    Permite carregar AFD de JSON ou terminal, converte AFN/AFN-ε se necessário.
    """
    print("\n=========================")
    print("Minimizar AFD")
    print("=========================\n")

    print("1 - Carregar autômato de arquivo JSON (ex: automato.json)")
    print("2 - Informar autômato pelo terminal")
    modo = input("Escolha o modo (1/2): ").strip()

    # Variáveis para armazenar o AFD
    alfabeto = None
    estados = None
    inicial = None
    finais = None
    transicoes = None

    if modo == "1":
        path = input("Caminho do arquivo JSON [automato.json]: ").strip() or "automato.json"
        try:
            automato = Automato.from_json(path)
        except Exception as e:
            print(f"Erro ao carregar JSON: {e}")
            return

        # Verifica se tem epsilon
        tem_epsilon = False
        for origem, mapa in automato.transicoes.items():
            if "ε" in mapa:
                tem_epsilon = True
                break

        if tem_epsilon:
            print("\nO autômato contém transições ε. Convertendo AFN-ε → AFN → AFD...")
            # Converte usando AFNEpAFN (precisamos adaptar)
            try:
                # Cria uma instância modificada que não executa CLI
                afne_converter = _converter_afne_silencioso(automato)
                # Agora converte AFN → AFD
                alfabeto, estados, inicial, finais, transicoes = converter_afn_para_afd(afne_converter)
                print("Conversão concluída.\n")
            except Exception as e:
                print(f"Erro na conversão: {e}")
                return
        else:
            # Verifica se é AFN (múltiplos destinos)
            eh_afn = False
            for origem, mapa in automato.transicoes.items():
                for simbolo, destinos in mapa.items():
                    if len(destinos) > 1:
                        eh_afn = True
                        break
                if eh_afn:
                    break

            if eh_afn or len(automato.iniciais) > 1:
                print("\nO autômato é AFN. Convertendo AFN → AFD...")
                try:
                    alfabeto, estados, inicial, finais, transicoes = converter_afn_para_afd(automato)
                    print("Conversão concluída.\n")
                except Exception as e:
                    print(f"Erro na conversão: {e}")
                    return
            else:
                # Já é AFD, converte para formato esperado
                alfabeto = sorted(list(automato.alfabeto))
                estados = sorted(list(automato.estados))
                inicial = list(automato.iniciais)[0]
                finais = sorted(list(automato.finais))
                transicoes = {}
                for origem in automato.estados:
                    transicoes[origem] = {}
                    for simbolo in automato.alfabeto:
                        destinos = automato.transicoes.get(origem, {}).get(simbolo, set())
                        if destinos:
                            transicoes[origem][simbolo] = list(destinos)[0]

    elif modo == "2":
        print("\nInformando AFD pelo terminal:")
        print("Nota: O autômato deve ser determinístico (sem ε, sem múltiplos destinos)")

        alfabeto_str = input("Alfabeto (ex: a,b): ").strip()
        alfabeto = [s.strip() for s in alfabeto_str.split(',') if s.strip()]

        estados_str = input("Estados (ex: q0,q1,q2): ").strip()
        estados = [s.strip() for s in estados_str.split(',') if s.strip()]

        inicial = input("Estado inicial: ").strip()

        finais_str = input("Estados finais (ex: q2): ").strip()
        finais = [s.strip() for s in finais_str.split(',') if s.strip()]

        transicoes = {}
        print("\nInforme as transições (formato: origem,simbolo,destino).")
        print("Digite 'fim' para encerrar.")

        for estado in estados:
            transicoes[estado] = {}

        while True:
            linha = input("Transição: ").strip()
            if linha.lower() == 'fim':
                break
            try:
                partes = [p.strip() for p in linha.split(',')]
                if len(partes) != 3:
                    print("Formato inválido. Use: origem,simbolo,destino")
                    continue
                origem, simbolo, destino = partes
                if origem not in estados:
                    print(f"Estado de origem '{origem}' não existe.")
                    continue
                if simbolo not in alfabeto:
                    print(f"Símbolo '{simbolo}' não está no alfabeto.")
                    continue
                if destino not in estados:
                    print(f"Estado de destino '{destino}' não existe.")
                    continue
                transicoes[origem][simbolo] = destino
            except Exception as e:
                print(f"Erro ao processar transição: {e}")
    else:
        print("Opção inválida.")
        return

    # Minimiza o AFD
    try:
        print("Minimizando AFD...")
        alfabeto_min, estados_min, inicial_min, finais_min, trans_min = minimizar_afd(
            alfabeto, estados, inicial, finais, transicoes
        )
    except Exception as e:
        print(f"Erro ao minimizar: {e}")
        return

    # Exibe resultado
    print("\n=========================")
    print("AFD Minimizado")
    print("=========================\n")
    print("Alfabeto:", alfabeto_min)
    print("Estados:", estados_min)
    print("Estado Inicial:", inicial_min)
    print("Estados Finais:", finais_min)
    print("Transições:")
    for origem in estados_min:
        for simbolo in alfabeto_min:
            destino = trans_min.get(origem, {}).get(simbolo)
            if destino is not None:
                print(f"  {origem} --{simbolo}--> {destino}")
    print("=========================\n")

    print(f"Estados antes: {len(estados)}")
    print(f"Estados depois: {len(estados_min)}")
    print(f"Redução: {len(estados) - len(estados_min)} estado(s)")


def _converter_afne_silencioso(automato: Automato) -> Automato:
    """
    Converte AFN-ε para AFN sem epsilon (versão silenciosa, sem CLI).
    Retorna um objeto Automato sem ε-transições.
    """

    # Calcula fecho epsilon para cada estado
    def fecho_epsilon(estado):
        fecho = {estado}
        pilha = [estado]
        while pilha:
            atual = pilha.pop()
            destinos_eps = automato.transicoes.get(atual, {}).get('ε', set())
            for d in destinos_eps:
                if d not in fecho:
                    fecho.add(d)
                    pilha.append(d)
        return fecho

    fechos = {estado: fecho_epsilon(estado) for estado in automato.estados}

    # Nova tabela de transições sem epsilon
    nova_tabela = {}
    for estado in automato.estados:
        nova_tabela[estado] = {}
        for simbolo in automato.alfabeto:
            if simbolo == 'ε':
                continue
            destinos = set()
            for e in fechos[estado]:
                dest_por_simbolo = automato.transicoes.get(e, {}).get(simbolo, set())
                for d in dest_por_simbolo:
                    destinos |= fechos[d]
            if destinos:
                nova_tabela[estado][simbolo] = destinos

    # Novos estados finais
    novos_finais = set()
    for estado in automato.estados:
        if any(f in automato.finais for f in fechos[estado]):
            novos_finais.add(estado)

    # Novos estados iniciais (fecho dos iniciais)
    fecho_iniciais = set()
    for e in automato.iniciais:
        fecho_iniciais |= fechos[e]

    # Cria novo autômato
    novo = Automato()
    novo.alfabeto = automato.alfabeto - {'ε'}
    novo.estados = automato.estados
    novo.iniciais = fecho_iniciais
    novo.finais = novos_finais
    novo.transicoes = nova_tabela

    return novo