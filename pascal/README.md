# Projeto Autômatos Finitos - Versão Pascal

Implementação completa em Pascal (sem orientação a objetos) do simulador e conversores de autômatos finitos.

## Estrutura do Projeto

```
pascal/
├── automatos/                 - Arquivos JSON de exemplo
│   ├── automato.json
│   ├── automato_afne.json
│   ├── automato_afd.json
│   └── multi_inicial.json
├── src/                       - Código-fonte Pascal e artefatos auxiliares
│   ├── tipos.pas
│   ├── utilidades.pas
│   ├── leitorjson.pas
│   ├── simulador.pas
│   ├── conversores.pas
│   ├── main.pas
│   └── palavras.txt (arquivo de teste de palavras)
├── Makefile                   - Compilação automatizada
└── README.md                  - Este arquivo
```

## Requisitos

- Free Pascal Compiler (fpc) 3.0 ou superior
- Make (opcional, para compilação automatizada)

## Instalação do Free Pascal

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install fpc
```

### Linux (Fedora/CentOS)
```bash
sudo dnf install fpc
```

## Compilação

### Usando Makefile (recomendado)
```bash
cd pascal
make
```

### Compilação manual
```bash
fpc -O2 -omain.pas
```

## Execução

```bash
./src/automatos
```

Ou com make:
Ou com `make run` (que já chama o executável dentro de `src/`):
```bash
make run
```

## Funcionalidades Implementadas

### Menu Principal

0. **Converter Múltiplos Iniciais → AFN-ε**
   - Transforma autômato com múltiplos estados iniciais em AFN-ε com estado inicial único
   - Cria novo estado com transições-ε para os estados iniciais originais

1. **Converter AFN-ε → AFN**
   - Remove transições epsilon usando fecho-ε
   - Expande estados iniciais e finais conforme fechos

2. **Converter AFN → AFD**
   - Método dos subconjuntos (construção de potências)
   - Cria estado morto (∅) quando necessário
   - Estados do AFD nomeados como "Q1,Q2" (combinação dos estados originais)

3. **Minimizar AFD**
   - Detecta automaticamente AFNs/AFN-ε, convertendo-os antes de minimizar
   - Usa tabela de distinção (particionamento) para obter um AFD equivalente mínimo
   - Estados resultantes recebem nomes `Q1`, `Q2`, ... seguindo o padrão dos demais módulos

4. **Testar Palavra**
   - Suporte a AFN e AFN-ε
   - Teste manual (digitação interativa)
   - Teste por arquivo TXT (uma palavra por linha)
   - Validação de símbolos do alfabeto

5. **Sair**

### Formato de Entrada

#### Arquivo JSON
```json
{
  "alfabeto": ["a", "b"],
  "estados": ["Q1", "Q2", "QF"],
  "estadosF": ["QF"],
  "estadosI": ["Q1"],
  "transicoes": [
    ["Q1", "Q1", "a"],
    ["Q1", "Q2", "b"],
    ["Q2", "QF", "a"]
  ]
}
```

**Observações:**
- Aceita `alfabet0` como sinônimo de `alfabeto`
- Transições no formato `[origem, destino, simbolo]`
- Use `"ε"` para transições epsilon

#### Entrada Interativa
- Alfabeto: `a,b`
- Estados: `Q1,Q2,QF`
- Estados iniciais: `Q1`
- Estados finais: `QF`
- Transições: `origem,simbolo,destino` (digite `fim` para encerrar)

#### Arquivo TXT (para teste de palavras)
```
a
ab
aba
abc
```
Uma palavra por linha.

## Tratamento de Erros

O programa implementa verificações para:

- **Validação de símbolos**: Detecta caracteres fora do alfabeto ao testar palavras
- **Carregamento de arquivos**: Erros ao abrir/ler arquivos JSON ou TXT
- **Conversão AFN-ε → AFN**: Avisa se não há transições epsilon
- **Conversão Multi → AFN-ε**: Avisa se há apenas 1 estado inicial
- **Conversão AFN → AFD**: Bloqueia se houver transições epsilon
- **Menu**: Trata entradas inválidas

## Limitações

- Máximo de 100 estados
- Máximo de 50 símbolos no alfabeto
- Máximo de 500 transições
- Máximo de 50 destinos por transição
- Parser JSON simplificado (não suporta JSON arbitrário)

## Diferenças em Relação à Versão Python

1. **Estruturas de dados estáticas**: Arrays com tamanho fixo em vez de listas dinâmicas
2. **Parser JSON simplificado**: Lê formato específico do projeto, não JSON genérico
3. **Sintaxe Pascal**: Procedures/functions, begin/end, tipos explícitos

## Exemplos de Uso

### Exemplo 1: Converter AFN-ε para AFN
```
1. Execute o programa
2. Escolha opção 1
3. Escolha modo 1 (JSON)
4. Digite "automatos/automato.json" ou caminho do arquivo
5. Veja o AFN resultante sem epsilon
```

### Exemplo 2: Testar palavras de um arquivo
```
1. Execute o programa
2. Escolha opção 4
3. Escolha modo 1 (JSON) para carregar autômato
4. Digite "automatos/automato.json"
5. Escolha modo 2 (arquivo TXT)
6. Digite "src/palavras.txt"
7. Veja resultados para cada palavra
```

## Limpeza

```bash
make clean
```

Remove arquivos objetos (.o), units compiladas (.ppu) e executável.

## Autores

Implementação Pascal baseada na versão Python original.
