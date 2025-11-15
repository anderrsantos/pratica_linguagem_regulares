# pratica_linguagem_regulares
Prática dos conceitos de Linguagens Regulares dos Autômatos Finitos

## Como executar

Requisitos: Python 3.8+

No Linux:

```
python3 src/main.py
```

## Testar palavra (opção 4 do menu)

Você pode testar palavras de duas formas:

1) Carregar um autômato de um arquivo JSON (ex.: `automato.json`)
2) Informar o autômato pelo terminal (alfabeto, estados, iniciais, finais e transições)

### Formato do JSON

Exemplo de `automato.json` (válido em JSON):

```json
{
	"alfabeto": ["a", "b"],
	"estados": ["Q1", "Q2", "QF"],
	"estadosF": ["QF"],
	"estadosI": ["Q1"],
	"transicoes": [
		["Q1", "Q1", "a"],
		["Q1", "Q2", "b"],
		["Q2", "QF", "a"],
		["Q2", "Q2", "a"],
		["QF", "QF", "a"],
		["QF", "QF", "b"]
	]
}
```

Observações:
- `transicoes` é uma lista de trios `[origem, destino, simbolo]`. Também aceitamos objetos `{ "origem": "Q1", "destino": "Q2", "simbolo": "a" }`.
- O símbolo `"ε"` (epsilon) é suportado para AFN-ε.
- Se você tiver o campo escrito como `alfabet0` (com zero), ele será aceito e mapeado para `alfabeto`.

### Teste pelo terminal

Ao escolher testar pelo terminal, informe:
- Alfabeto: `a,b`
- Estados: `Q1,Q2,QF`
- Estados iniciais: `Q1`
- Estados finais: `QF`
- Transições no formato `origem,simbolo,destino` (use `ε` para epsilon). Digite `fim` para encerrar.

### Critérios de aceitação

O simulador suporta AFN e AFN-ε:
- A palavra é aceita se, após consumir todos os símbolos (com fechos-ε quando existirem), algum estado alcançado é final.
- Símbolos fora do alfabeto fazem a palavra ser rejeitada por padrão.

## Converter Múltiplos Iniciais → AFN-ε (Opção 0 do menu)

Esta opção transforma um autômato que possui múltiplos estados iniciais em um autômato de estado inicial único equivalente.

O processo é simples:

1.  Um **novo estado inicial** é criado (ex: `Q_novo`).
2.  Este novo estado se torna o **único** estado inicial do autômato.
3.  São adicionadas **transições-ε** (lambda) deste novo estado para *cada um* dos estados iniciais originais.
4.  Todo o restante do autômato (alfabeto, estados finais e transições originais) é preservado.

## Converter AFN-ε → AFN (opção 1 do menu)

Agora você pode montar o AFN-ε pelo terminal ou carregar de um arquivo JSON (mesmo formato descrito acima). O conversor aceita:
- `transicoes` como `[origem, simbolo, destino]` ou `[origem, destino, simbolo]` (o código detecta automaticamente o formato) e também objetos `{origem,destino,simbolo}`.
- Campo `alfabet0` como sinônimo de `alfabeto`.

Saída: imprime um AFN equivalente sem transições ε, com estados iniciais expandidos pelo fecho-ε e novos estados finais conforme o fecho.

## Converter AFN → AFD (opção 2 do menu)

Converte um AFN (sem ε) para um AFD via método dos subconjuntos. Você pode:
- Carregar de JSON (mesmo formato do exemplo acima; não use `ε` aqui), ou
- Informar pelo terminal.

Detalhes:
- Estados do AFD são subconjuntos de estados do AFN, nomeados como `q1,q2`.
- Se uma transição não leva a nenhum estado, cria-se um estado morto `∅` que recebe laços para todo símbolo.
- Se seu autômato tiver `ε`, primeiro use a opção 1 (AFN-ε → AFN).

