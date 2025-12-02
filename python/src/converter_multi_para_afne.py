from testar_palavra import Automato, EPSILON 

def converter_multi_para_afne_cli():
    print("\n====================================")
    print("Converter Múltiplos Iniciais → AFN-ε")
    print("====================================\n")


    print("1 - Carregar AFN de arquivo JSON (ex: automato.json)")
    print("2 - Informar AFN pelo terminal")
    modo = input("Escolha o modo (1/2): ").strip()

    automato: Automato
    if modo == "1":
        path = input("Caminho do arquivo JSON [automato.json]: ").strip() or "automato.json"
        try:
            automato = Automato.from_json(path)
        except Exception as e:
            print(f"Erro ao carregar JSON: {e}")
            return
    elif modo == "2":
        try:
            automato = Automato.from_interactive()
        except Exception as e:
            print(f"Erro ao criar AFN: {e}")
            return
    else:
        print("Opção inválida.")
        return

    if len(automato.iniciais) <= 1:
        print("\nO autômato já possui 1 ou 0 estados iniciais. Nenhuma conversão necessária.")
        return

    novo_estado_inicial = "Q_novo_inicial"
    i = 0
    while novo_estado_inicial in automato.estados:
        novo_estado_inicial = f"Q{i}_novo"
        i += 1

    print(f"\nAutômato original tinha {len(automato.iniciais)} estados iniciais.")
    print(f"Novo estado inicial único criado: {novo_estado_inicial}")

    antigos_iniciais = set(automato.iniciais)

    automato.estados.add(novo_estado_inicial)
    
    automato.transicoes[novo_estado_inicial] = {
        EPSILON: antigos_iniciais
    }

    automato.iniciais = {novo_estado_inicial}

    print("\n=========================")
    print("AFN-ε Resultante (com 1 estado inicial)")
    print("=========================\n")
    print("Alfabeto:", sorted(list(automato.alfabeto)))
    print("Estados:", sorted(list(automato.estados)))
    print("Estado Inicial:", list(automato.iniciais)[0])
    print("Estados Finais:", sorted(list(automato.finais)))
    print("Transições:")
    
 
    for origem in sorted(list(automato.estados)):
        for simbolo, destinos in automato.transicoes.get(origem, {}).items():
            if destinos:
                print(f"  {origem} --{simbolo}--> {', '.join(sorted(list(destinos)))}")
    print("=========================\n")
