import json
from testar_palavra import Automato

# Classe feita por Anderson R. Santos
class AFNEpAFN:
    def __init__(self):
        self.alfabeto = []
        self.estados = []
        self.estados_iniciais = [] 
        self.estados_finais = []
        self.transicoes = {}

        while True:
            try:
                self.tela_inicial()
                if self.verificacao_entradas():
                    break
            except Exception as e:
                print(f"Erro: {e}. Por favor, tente novamente.")

        try:
            self.converter()
        except Exception as e:
            print(f"Erro durante a conversão: {e}")

        try:
            self.tela_final()
        except Exception as e:
            print(f"Erro ao exibir o resultado: {e}")



    def tela_inicial(self):
        print("\n=================================================")
        print("Conversor AFNε → AFN (múltiplos estados iniciais)")
        print("=================================================\n")

        print("1 - Carregar AFN-ε de arquivo JSON (ex: automato.json)")
        print("2 - Informar AFN-ε pelo terminal")
        modo = input("Escolha o modo (1/2): ").strip()

        if modo == '1':
            self._carregar_de_json()
            print("AFNε carregado do JSON.\n")
            return

        # Modo interativo (terminal)
        self.alfabeto = input("Informe o alfabeto (ex: a,b): ").split(',')
        self.estados = input("Informe os estados (ex: q0,q1,q2): ").split(',')
        self.estados_iniciais = input("Informe os estados iniciais (ex: q0,q1): ").split(',')
        self.estados_finais = input("Informe os estados finais (ex: q2): ").split(',')

        print("Informe as transições (formato: estado,simbolo,estado_destino). Use 'ε' para epsilon. Digite 'fim' para encerrar.")
        while True:
            linha = input("Transição: ")
            if linha.lower() == 'fim':
                break
            origem, simbolo, destino = [p.strip() for p in linha.split(',')]
            if (origem, simbolo) not in self.transicoes:
                self.transicoes[(origem, simbolo)] = []
            self.transicoes[(origem, simbolo)].append(destino)
        print("AFNε carregado.\n")

    def _carregar_de_json(self):
        caminho = input("Caminho do arquivo JSON [automato.json]: ").strip() or "automato.json"
        # Reutiliza o carregador já implementado no módulo de teste
        automato = Automato.from_json(caminho)

        # Copia dados para a estrutura esperada pelo conversor
        self.alfabeto = list(automato.alfabeto)
        self.estados = list(automato.estados)
        self.estados_iniciais = list(automato.iniciais)
        self.estados_finais = list(automato.finais)

        # Converter de {origem: {simbolo: {destinos}}} para {(origem, simbolo): [destinos]}
        self.transicoes = {}
        for origem, mapa in automato.transicoes.items():
            for simbolo, destinos in mapa.items():
                self.transicoes[(origem, simbolo)] = list(destinos)

    def _coletar_lista(self, obj):
        # aceita lista JSON ou string separada por vírgulas (com/sem chaves)
        if isinstance(obj, list):
            return [str(x).strip() for x in obj]
        if isinstance(obj, str):
            s = obj.strip().strip('{}[]()')
            if not s:
                return []
            if ',' in s:
                return [p.strip().strip("'\"") for p in s.split(',') if p.strip()]
            return [s]
        raise Exception('Campo deve ser lista ou string.')

    
    def tela_final(self):
        print("\n=========================")
        print("AFN resultante (sem ε)")
        print("=========================\n")
        print("Alfabeto:", self.alfabeto)
        print("Estados:", self.estados)
        print("Estados Iniciais:", self.estados_iniciais)
        print("Estados Finais:", self.estados_finais)
        print("Transições:")
        for estado, transicoes_estado in self.transicoes.items():
            for simbolo, destinos in transicoes_estado.items():
                if destinos:
                    print(f"{estado} --{simbolo}--> {', '.join(sorted(destinos))}")
        print("=========================")

    def verificacao_entradas(self):
        faltando = []
        if not self.alfabeto:
            faltando.append("alfabeto")
        if not self.estados:
            faltando.append("estados")
        if not self.estados_iniciais:
            faltando.append("estados iniciais")
        if not self.estados_finais:
            faltando.append("estados finais")
        if not self.transicoes:
            faltando.append("transições")

        if faltando:
            raise Exception(f"Entradas incompletas: {', '.join(faltando)}")

        # Validação de consistência
        for (origem, simbolo), destinos in self.transicoes.items():
            if origem not in self.estados:
                raise Exception(f"Estado de origem inválido: {origem}")
            if simbolo != 'ε' and simbolo not in self.alfabeto:
                raise Exception(f"Símbolo inválido: {simbolo}")
            for d in destinos:
                if d not in self.estados:
                    raise Exception(f"Estado de destino inválido: {d}")

        return True

    def fecho_epsilon(self, estado):
        fecho = {estado}
        pilha = [estado]
        while pilha:
            atual = pilha.pop()
            for (origem, simbolo), destinos in self.transicoes.items():
                if origem == atual and simbolo == 'ε':
                    for d in destinos:
                        if d not in fecho:
                            fecho.add(d)
                            pilha.append(d)
        return fecho

    def converter(self):
        # Verifica se há alguma transição epsilon
        tem_epsilon = any(simbolo == 'ε' for (origem, simbolo) in self.transicoes)
        if not tem_epsilon:
            print("\nEste autômato já é um AFN normal (não possui transições ε). Nenhuma conversão foi realizada.")
            return

        fechos = {estado: self.fecho_epsilon(estado) for estado in self.estados}
        nova_tabela = {estado: {simbolo: set() for simbolo in self.alfabeto} for estado in self.estados}
        novos_finais = set()

        for estado in self.estados:
            for simbolo in self.alfabeto:
                destinos = set()
                for e in fechos[estado]:
                    if (e, simbolo) in self.transicoes:
                        for d in self.transicoes[(e, simbolo)]:
                            destinos |= self.fecho_epsilon(d)
                nova_tabela[estado][simbolo] = destinos

            # Estado é final se seu fecho contém um estado final original
            if any(f in self.estados_finais for f in fechos[estado]):
                novos_finais.add(estado)

        # Novo conjunto inicial = união dos fechos dos estados iniciais originais
        fecho_iniciais = set()
        for e in self.estados_iniciais:
            fecho_iniciais |= fechos[e]

        self.transicoes = nova_tabela
        self.estados_finais = list(novos_finais)
        self.estados_iniciais = list(fecho_iniciais)  # substitui pelo fecho expandido

