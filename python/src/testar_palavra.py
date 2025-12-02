import json
from typing import Dict, Set, Iterable, Tuple, List


EPSILON = "ε"


class Automato:
    """
    Representa um AFN/AFN-ε genérico.

    - estados: conjunto de strings
    - alfabeto: conjunto de símbolos (strings). O símbolo especial 'ε' é opcional.
    - iniciais: conjunto de estados iniciais
    - finais: conjunto de estados finais
    - transicoes: dict no formato: { origem: { simbolo: set(destinos) } }
    """

    def __init__(
        self,
        estados: Iterable[str],
        alfabeto: Iterable[str],
        iniciais: Iterable[str],
        finais: Iterable[str],
        transicoes: Dict[str, Dict[str, Set[str]]],
    ) -> None:
        self.estados: Set[str] = set(estados)
        self.alfabeto: Set[str] = set(alfabeto)
        self.iniciais: Set[str] = set(iniciais)
        self.finais: Set[str] = set(finais)
        # normaliza transicoes com sets
        self.transicoes: Dict[str, Dict[str, Set[str]]] = {}
        for o, mapa in transicoes.items():
            self.transicoes[o] = {}
            for s, ds in mapa.items():
                self.transicoes[o][s] = set(ds)

        self._validar()

    # ------------------------- Carregadores ------------------------- #
    @staticmethod
    def from_json(path: str) -> "Automato":
        """
        Carrega um autômato de um arquivo JSON.

        Formato esperado (exemplo de JSON válido):
        {
          "alfabeto": ["a","b"],
          "estados": ["Q1","Q2","QF"],
          "estadosF": ["QF"],
          "estadosI": ["Q1"],
          "transicoes": [
            ["Q1","Q1","a"],
            ["Q1","Q2","b"],
            ["Q2","QF","a"],
            ["Q2","Q2","a"],
            ["QF","QF","a"],
            ["QF","QF","b"]
          ]
        }

        Também aceita transições como objetos: {"origem":"Q1","destino":"Q2","simbolo":"a"}.
        Aceita chave alternativa "alfabet0" (com zero) mapeando para "alfabeto".
        """
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # tolerância: "alfabet0" -> "alfabeto"
        if "alfabeto" not in data and "alfabet0" in data:
            data["alfabeto"] = data["alfabet0"]

        required = ["alfabeto", "estados", "estadosF", "estadosI", "transicoes"]
        faltando = [k for k in required if k not in data]
        if faltando:
            raise ValueError(f"Chaves faltando no JSON: {', '.join(faltando)}")

        alfabeto = _as_list_of_str(data["alfabeto"], "alfabeto")
        estados = _as_list_of_str(data["estados"], "estados")
        finais = _as_list_of_str(data["estadosF"], "estadosF")
        iniciais = _as_list_of_str(data["estadosI"], "estadosI")
        transicoes_brutas = data["transicoes"]

        transicoes: Dict[str, Dict[str, Set[str]]] = {}
        for item in transicoes_brutas:
            if isinstance(item, list) and len(item) == 3:
                origem, destino, simbolo = item[0], item[1], item[2]
            elif isinstance(item, dict):
                origem = item.get("origem")
                destino = item.get("destino")
                simbolo = item.get("simbolo")
            else:
                raise ValueError(
                    "Transição inválida. Use [origem, destino, simbolo] ou {origem,destino,simbolo}."
                )

            if origem not in transicoes:
                transicoes[origem] = {}
            if simbolo not in transicoes[origem]:
                transicoes[origem][simbolo] = set()
            transicoes[origem][simbolo].add(destino)

        return Automato(estados, alfabeto, iniciais, finais, transicoes)

    @staticmethod
    def from_interactive() -> "Automato":
        print("\n=========================")
        print("Construir autômato pelo terminal")
        print("=========================\n")

        alfabeto = input("Alfabeto (ex: a,b): ").split(",")
        estados = input("Estados (ex: Q1,Q2,QF): ").split(",")
        iniciais = input("Estados iniciais (ex: Q1): ").split(",")
        finais = input("Estados finais (ex: QF): ").split(",")

        print("Informe as transições como 'origem,simbolo,destino'. Use 'ε' para epsilon. Digite 'fim' para encerrar.")
        transicoes: Dict[str, Dict[str, Set[str]]] = {}
        while True:
            linha = input("Transição: ").strip()
            if linha.lower() == "fim":
                break
            try:
                origem, simbolo, destino = [p.strip() for p in linha.split(",")]
            except Exception:
                print("Formato inválido. Use origem,simbolo,destino.")
                continue
            if origem not in transicoes:
                transicoes[origem] = {}
            if simbolo not in transicoes[origem]:
                transicoes[origem][simbolo] = set()
            transicoes[origem][simbolo].add(destino)

        return Automato(estados, alfabeto, iniciais, finais, transicoes)

    # ------------------------- Execução ------------------------- #
    def _validar(self) -> None:
        # Verificações básicas de consistência
        for s in self.iniciais | self.finais:
            if s not in self.estados:
                raise ValueError(f"Estado inválido em iniciais/finais: {s}")

        for o, mapa in self.transicoes.items():
            if o not in self.estados:
                raise ValueError(f"Estado de origem inválido nas transições: {o}")
            for simbolo, destinos in mapa.items():
                if simbolo != EPSILON and simbolo not in self.alfabeto:
                    raise ValueError(f"Símbolo inválido em transição: {simbolo}")
                for d in destinos:
                    if d not in self.estados:
                        raise ValueError(f"Estado de destino inválido nas transições: {d}")

    def _fecho_epsilon(self, estados: Iterable[str]) -> Set[str]:
        fecho: Set[str] = set(estados)
        pilha: List[str] = list(estados)
        while pilha:
            atual = pilha.pop()
            for simbolo, destinos in self.transicoes.get(atual, {}).items():
                if simbolo == EPSILON:
                    for d in destinos:
                        if d not in fecho:
                            fecho.add(d)
                            pilha.append(d)
        return fecho

    def _mover(self, estados: Iterable[str], simbolo: str) -> Set[str]:
        proximos: Set[str] = set()
        for e in estados:
            for d in self.transicoes.get(e, {}).get(simbolo, set()):
                proximos.add(d)
        return proximos

    def aceita(self, palavra: str, rejeitar_simbolo_fora_alfabeto: bool = True) -> bool:
        """
        Simula o autômato sobre a palavra. Suporta ε-transições.
        - Se houver símbolo fora do alfabeto (e não for ε), por padrão rejeita imediatamente.
        - Palavra vazia é aceita se o fecho-ε do conjunto inicial intersectar um estado final.
        """
        if any(c not in self.alfabeto for c in palavra):
            if rejeitar_simbolo_fora_alfabeto:
                return False

        atuais = self._fecho_epsilon(self.iniciais)
        for c in palavra:
            # Movimento por símbolo
            move = self._mover(atuais, c)
            # Fecho-ε após o movimento
            atuais = self._fecho_epsilon(move)
            if not atuais:
                break

        return any(e in self.finais for e in atuais)


def _as_list_of_str(obj, field: str) -> List[str]:
    if isinstance(obj, list):
        return [str(x) for x in obj]
    # tolerância a string única com vírgulas ou representações como "{a, b}"
    if isinstance(obj, str):
        s = obj.strip()
        s = s.strip("{}[]()")
        if "," in s:
            return [p.strip().strip("'\"") for p in s.split(",") if p.strip()]
        if s:
            return [s]
    raise ValueError(f"Campo '{field}' deve ser lista ou string.")


def testar_palavra_cli():
    print("\n=============================================")
    print("Testar palavra em autômato (JSON ou terminal)")
    print("=============================================\n")

    print("1 - Carregar de arquivo JSON (ex: automato.json)")
    print("2 - Informar o autômato pelo terminal")
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
            print(f"Erro ao criar autômato: {e}")
            return
    else:
        print("Opção inválida.")
        return

    print("\nComo deseja testar palavras?")
    print("1 - Digitar manualmente")
    print("2 - Ler de arquivo TXT (uma palavra por linha)")
    modo_palavra = input("Escolha o modo (1/2): ").strip()

    if modo_palavra == "2":
        path_txt = input("Caminho do arquivo TXT: ").strip()
        try:
            with open(path_txt, "r", encoding="utf-8") as f:
                linhas = f.readlines()
        except Exception as e:
            print(f"Erro ao ler arquivo TXT: {e}")
            return
        print(f"\nTestando palavras do arquivo '{path_txt}':\n")
        for idx, linha in enumerate(linhas, 1):
            w = linha.strip()
            if not w:
                continue
            invalidos = [c for c in w if c not in automato.alfabeto]
            if invalidos:
                print(f"{idx}: '{w}' -> ERRO: contém símbolos fora do alfabeto: {', '.join(invalidos)}")
                continue
            aceito = automato.aceita(w)
            print(f"{idx}: '{w}' -> {'ACEITA' if aceito else 'REJEITA'}")
        return

    print("\nDigite palavras para testar. Use ENTER vazio para sair.")
    while True:
        w = input("Palavra: ")
        if w == "":
            break
        invalidos = [c for c in w if c not in automato.alfabeto]
        if invalidos:
            print(f"Erro: A palavra contém símbolos fora do alfabeto: {', '.join(invalidos)}")
            continue
        aceito = automato.aceita(w)
        print("Resultado:", "ACEITA" if aceito else "REJEITA")
