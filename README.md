# pratica_linguagem_regulares

Repositório didático para manipulação e transformação de autômatos finitos (AFN, AFN-ε e AFD) em Python.

Este projeto contém utilitários de linha de comando que permitem:
- Construir/carregar um autômato (JSON ou terminal);
- Testar palavras em AFN/AFN-ε;
- Converter AFN-ε → AFN (remoção de ε-transições);
- Converter AFN → AFD (método dos subconjuntos);
- Minimizar AFD (algoritmo de Hopcroft).

O foco é didático e as implementações priorizam clareza e tolerância a entradas diversas.

**Requisitos**
- Python 3.8+

**Instalação rápida**
```bash
git clone https://github.com/anderrsantos/pratica_linguagem_regulares.git
cd pratica_linguagem_regulares
# (opcional) criar e ativar venv
python3 -m venv .venv
source .venv/bin/activate
```

**Executando o menu principal**
```bash
python3 src/main.py
```

O menu apresenta as opções:
- `0` - Converter multiestado inicial → AFN-ε
- `1` - Converter AFN-ε → AFN
- `2` - Converter AFN → AFD
- `3` - Minimizar AFD
- `4` - Testar palavra (JSON, terminal ou TXT)
- `5` - Sair

Observação: cada opção tem uma função CLI própria no diretório `src/` (por exemplo `testar_palavra.py` expõe `testar_palavra_cli()`).

**Formato JSON aceito**
Use o seguinte formato mínimo para `Automato.from_json()` (arquivo exemplo: `automato.json`):

```json
{
	"alfabeto": ["a", "b"],
	"estados": ["Q1", "Q2", "QF"],
	"estadosI": ["Q1"],
	"estadosF": ["QF"],
	"transicoes": [
		["Q1", "Q1", "a"],
		["Q1", "Q2", "b"],
		["Q2", "QF", "a"],
		{"origem": "QF", "destino": "QF", "simbolo": "b"}
	]
}
```

- `transicoes` aceita listas `[origem, destino, simbolo]` ou objetos `{"origem","destino","simbolo"}`.
- O projeto aceita também a chave alternativa `"alfabet0"` (mapeada para `alfabeto`) por tolerância.

**Exemplo de uso (AFN-ε → AFN)**
1. Execute `python3 src/main.py` e escolha a opção `1`.
2. Escolha carregar via JSON ou informar pelo terminal.
3. Se interativo, informe alfabeto, estados, iniciais, finais e transições (use `ε` para epsilon). Digite `fim` para encerrar as transições.

Exemplo interativo (entrada):
```
alfabeto: a,b
estados: q0,q1,q2
estados iniciais: q0
estados finais: q2
transições: q0,ε,q1
						q1,a,q2
						fim
```

Saída esperada (formato de exibição):
```
AFN resultante (sem ε)
Alfabeto: ['a','b']
Estados: ['q0','q1','q2']
Estados Iniciais: ['q0','q1']  # fecho-ε dos iniciais
Estados Finais: ['q2']
Transições:
q0 --a--> q2
q1 --a--> q2
... (dependendo das transições)
```

**Módulos principais (em `src/`)**
- `main.py` — menu interativo que orquestra as operações.
- `testar_palavra.py` — contém a classe `Automato` e `testar_palavra_cli()` para carregar/autômato e testar palavras (JSON/terminal/TXT).
- `converterAFNEpAFN.py` — classe `AFNEpAFN` e CLI para converter AFN-ε → AFN; aceita entrada por JSON ou terminal.
- `converter_multi_para_afne.py` — utilitário para transformar múltiplos estados iniciais em um único inicial com ε-transições.
- `converterAFNparaAFD.py` — conversor AFN → AFD (método dos subconjuntos) com CLI.
- `converter_minimizar_afd.py` — minimização de AFD (algoritmo de Hopcroft) com CLI.

**Limitações conhecidas / Observações**
- Entrada interativa e JSON são tolerantes, mas o código espera formatos específicos — siga o exemplo JSON acima.
- Algumas rotinas imprimem resultados para o terminal (foco didático); não há ainda um formato de exportação padronizado (ex.: JSON de saída).
- O projeto prioriza clareza do algoritmo; há espaço para testes automatizados e melhorias na validação de entradas.
