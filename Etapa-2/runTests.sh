#!/bin/bash

# Turma L
# Guilherme de Oliveira (00278301)
# Jean Pierre Comerlatto Darricarrere (00182408)

testCounter=0
successfulTestsCounter=0
failedTestsCounter=0

SUCCESS=0
FAIL=1

buildCompiler () {
    make
    result=$?

    if [ $result -ne 0 ]
    then
        echo "Build failed!"
        exit $result
    fi

    echo ""
}

runTestScript () {
    givenInput=$1
    expectedValue=$2

    ((testCounter++))
    echo "Test $testCounter"

    escapedInput="$givenInput"
    escapedInput="${escapedInput//"["/"\\["}"
    escapedInput="${escapedInput//"]"/"\\]"}"
    escapedInput="${escapedInput//"\""/"\\\""}"

    script='
        set timeout 1

        set givenInput "'${escapedInput}'"

        spawn -noecho "./etapa2" 
        send_user "Input: "
        send -- "$givenInput\n"

        # Await max time for response (fixes bug of false-positives)
        sleep 0.001

        expect {
            "syntax error" {
                # return exit code from spawned process
                catch wait result
                exit [lindex $result 3]
            }
            -ex "\r" { }
        }

        close

        # return exit code from spawned process
        catch wait result
        exit [lindex $result 3]
    '

    expect -c "$script"
    result=$?

    if [ $result -eq $expectedValue ]
    then
        echo "SUCCESS!"
        ((successfulTestsCounter++))
    else
        echo "TEST FAILED!"
        ((failedTestsCounter++))
        exit
    fi
    
    echo ""
}

testValidInput () { 
    runTestScript "$1" 0
}

testInvalidInput () { 
    runTestScript "$1" 1
}

buildCompiler

basicTypes=("int" "char" "float" "bool" "string")
literalValues=("1" "'c'" "1.0" "true" "false" "\"string\"")

# global variable declarations
for type in ${basicTypes[@]}; do
    testValidInput "$type v1;"
    testInvalidInput "$type;"

    testValidInput "static $type v1;"
    testInvalidInput "static $type;"

    testValidInput "$type v1, v2;"
    testValidInput "$type v1, v2, v3;"
    testInvalidInput "$type v1,;"
    testInvalidInput "$type ,v1;"

    testValidInput "$type v1[3];"
    testValidInput "$type v1[+3];"
    #TODO: testInvalidInput "$type v1[0];"
    #TODO: testInvalidInput "$type v1[-1];"

    testValidInput "$type v1[1], v2[2], v3[3];"
    testValidInput "static $type v1[1], v2, v3[3];"
    testValidInput "$type v1, v2[+5], v3;"
done

# Function header declaration
testValidInput "int functionName(int a) { }"
testValidInput "int functionName(int a, bool b) { }"
testValidInput "int functionName(int a, bool b, string c) { }"
testValidInput "int functionName(const int a, bool b) { }"
testValidInput "int functionName(int a, const bool b) { }"
testInvalidInput "int functionName(int a[5]) { }"
testInvalidInput "int functionName(int a,) { }"
testInvalidInput "int functionName(,int a) { }"

for basicType in ${basicTypes[@]}; do
    testValidInput "$basicType functionName() { }"
    testValidInput "$basicType functionName($basicType a) { }"
    testValidInput "static $basicType functionName() { }"
    testValidInput "static $basicType functionName($basicType a) { }"
done

# Command block / commands
for basicType in ${basicTypes[@]}; do
    testValidInput "int f() { $basicType id; }"
    testValidInput "int f() { static $basicType id; }"
    testValidInput "int f() { const $basicType id; }"
    testValidInput "int f() { static const $basicType id; }"
done

testValidInput "int f() { int id; }"
testValidInput "int f() { int id1; int id2; }"
testValidInput "int f() { int id1; int id2; int id3; }"
testValidInput "int f() { int id1, id2; }"
testValidInput "int f() { int id1, id2, id3; }"

testValidInput "int f() { int id1 <= id2; }"
testValidInput "int f() { int id1 <= id2, id3 <= id4; }"
testValidInput "int f() { int id1 <= id2, id3 <= id4, id5 <= id6; }"
testValidInput "int f() { int id1 <= 0; }"
testValidInput "int f() { float id1 <= 0.0; }"
testValidInput "int f() { char id1 <= 'c'; }"
testValidInput "int f() { string id1 <= \"c\"; }"
testValidInput "int f() { bool id1 <= false; }"
testValidInput "int f() { bool id1 <= true; }"

# 3.3 Bloco de Comandos

# Um bloco de comandos e definido entre chaves, e consiste em uma sequencia,
# possivelmente vazia, de comandos simples cada um terminado por ponto-e-v??rgula.
# Um bloco de comandos e considerado como um comando ??nico simples, recursivamente,
# e pode ser utilizado em qualquer constru????o que aceite um comando simples.

testValidInput "int f() { { }; }"
testValidInput "int f() { { id = 1; }; }"
testValidInput "int f() { { { }; }; }"
testValidInput "int f() { { { { id = 1; }; }; }; }"

# Comando de Atribui????o

# Existe apenas uma forma de atribui????o para identificadores.
# Identificadores podem receber valores assim
# (primeiro caso de um identificador simples; segundo caso de um identificador que e um vetor):
# identificador = express??o
# identificador[express??o] = express??o

expressionExamples=("id" "1" "1.0" "f()" "1+id" "id1==id2")

for expressionExample in ${expressionExamples[@]}; do
    testValidInput "int f() { id = $expressionExample; }"
done

for expressionExample in ${expressionExamples[@]}; do
    testValidInput "int f() { id[1] = $expressionExample; }"
done

for expressionExample in ${expressionExamples[@]}; do
    testValidInput "int f() { id[$expressionExample] = 1; }"
done

testValidInput "int f() { int id1 <= id2; int id1 <= id2; }"
testValidInput "int f() { id = 1; id = 3; }"
testValidInput "int f() { id = 2; int id1 <= 4; }"
testValidInput "int f() { int id1 <= id2; id = 7; }"

testValidInput "int f() { input id1; }"
testValidInput "int f() { output id1; }"

for literalValue in ${literalValues[@]}; do
    testValidInput "int f() { output $literalValue; }"
done

# Chamada de fun????o
# Uma chamada de func??o consiste no nome da fun????o, seguida de argumentos entre parenteses separados por v??rgula. [...]

testValidInput "int f() { funcName(); }"
testValidInput "int f() { funcName(id1); }"
testValidInput "int f() { funcName(id1, id2, id3); }"

for literalValue in ${literalValues[@]}; do
    testValidInput "int f() { funcName($literalValue); }"
done

testValidInput "int f() { funcName(1, 'z', 5.0); }"

# Um argumento pode ser uma expressao. 
testValidInput "int f() { funcName(1 + 1 + 1); }"

# Comandos de Shift

# Sendo numero um literal inteiro positivo, temos os exemplos v??lidos abaixo.
# Os exemplos s??o dados com <<, mas as entradas s??o sintaticamente v??lidas tambem para >>.
# O numero deve ser representado por um literal inteiro.
# identificador << n??mero
# identificador[express??o] << n??mero

testValidInput "int f() { id << 1; }"
testValidInput "int f() { id >> 1; }"
testValidInput "int f() { id[1] << 1; }"
testValidInput "int f() { id[1] >> 1; }"

testValidInput "int f() { id << +1; }"
testValidInput "int f() { id >> +1; }"
testValidInput "int f() { id[1] << +1; }"
testValidInput "int f() { id[1] >> +1; }"

testValidInput "int f() { id[1 + 1] << +1; }"

# TODO: Block negative values
# testInvalidInput "int f() { id << -1; }"
# testInvalidInput "int f() { id >> -1; }"
# testInvalidInput "int f() { id[1] << -1; }"
# testInvalidInput "int f() { id[1] >> -1; }"

# Comando de Retorno, Break, Continue

# Retorno ?? a palavra reservada return seguida de uma express??o.
testValidInput "int f() { return 5 + 5; }"

# Os comandos break e continue sao simples.
testValidInput "int f() { break; }"
testValidInput "int f() { continue; }"

# Comandos de Controle de Fluxo

# A linguagem possui constru????es condicionais, iterativas e de
# sele????o para controle estruturado de fluxo. As condicionais
# incluem o if com o else opcional, assim:
# if (<express??o>) bloco
# if (<express??o>) bloco else bloco

testValidInput "int f() { if (1 + 1) { } }"
testValidInput "int f() { if (1 + 1) { id = 1; } }"
testValidInput "int f() { if (5 + 5 + 5) { id = 1; } }"
testValidInput "int f() { if (1 + 1) { id = 1; } else { id = 2; } }"

# As constru????es iterativas s??o as seguintes no formato:
# for (atrib: <express??o>: <atrib>) bloco
# while (<express??o>) do bloco

testValidInput "int f() { for (x = 10 : x <= 10 : x = x + 1) { } }"
testValidInput "int f() { for (x = 10 : x <= 10 : x = x + 1) { id = 1; } }"
testInvalidInput "int f() { for (10 + 10 : x <= 10 : x = x + 1) { id = 1; } }"
testInvalidInput "int f() { for (x = 10 : x <= 10 : 10 + 10) { id = 1; } }"

testValidInput "int f() { while (1 + 1) do { } }"
testValidInput "int f() { while (1 + 1) do { id = 1; } }"

# Os dois marcadores atrib do comando for representa
# o comando de atribui????o, unico aceito nestas posi????es. 
# Em todas as constru????es de controle de fluxo, o termo bloco
# indica um bloco de comandos. Este n??o tem ponto-e-v??rgula nestas situa????es. 

#TODO :
# testValidInput "int f() { while (1 + 1) do { id = 1; }; }"
# testValidInput "int f() { while (1 + 1) do { 
#         id = 1; 
#     } }"

# Expr. Aritm??ticas, L??gicas

# As express??es podem ser de dois tipos: aritm??ticas e l??gicas.
# As expressoes aritm??ticas podem ter como operandos: 

#    (a) identificadores, opcionalmente seguidos de expressao inteira entre colchetes, para acesso a vetores;
#    (b) literais num??ricos como inteiro e ponto-flutuante;
#    (c) chamada de fun????o.

expressionArgs=("1" "1.0" "id" "id[1]" "func()" "func(1)" "func(id)" "func(1,5)" "id[id1+id2]" "func(id1+id2)")

# As express??es aritm??ticas podem ser formadas recursivamente com operadores aritmeticos, assim como permitem o
# uso de parenteses para for??ar uma associatividade ou precedencia diferente daquela tradicional.
# A associatividade ?? a esquerda.

testValidInput "int f() { id = (1 + 1) + 1; }"
testValidInput "int f() { id = ((1 + 1) + 1); }"
testValidInput "int f() { id = (1 + (1) + 1); }"
testValidInput "int f() { id = (1 + (1 + 1)); }"

testValidInput "int f() { id = &(1 + 1); }"
testValidInput "int f() { id = !(1 == 1) || 2; }"
testValidInput "int f() { id = !(!1 == !1) || 2; }"

# Express??es l??gicas podem ser formadas atrav??s dos operadores relacionais aplicados a express??es aritm??ticas,
testValidInput "int f() { x = 1 + 1 == 2;}"

# ou de operadores l??gicos aplicados a express??es l??gicas, recursivamente.
testValidInput "int f() { x = 1 == 1 && 2 == 2;}"

# Outras express??es podem ser formadas considerando variaveis l??gicas do tipo bool.
testValidInput "int f() { x = isOpen;}"
testValidInput "int f() { x = isOpen != isClosed;}"
testValidInput "int f() { x = isOpen == !isClosed;}"

# A descri????o sint??tica deve aceitar qualquer operadores e subexpressao de um desses
# tipos como v??lidos, deixando para a an??lise semantica das proximas etapas do projeto
# a tarefa de verificar a validade dos operandos e operadores.

# Os operadores s??o os seguintes:

# ??? Unarios (todos prefixados)
#   ??? + sinal positivo expl??cito
#   ??? - inverte o sinal
#   ??? ! nega????o l??gica
#   ??? & acesso ao endere??o da vari??vel
#   ??? * acesso ao valor do ponteiro
#   ??? ? avalia uma expressao para true ou false
#   ??? # acesso a um identificador como uma tabela hash

#TODO: testValidInput "int f() {1+1;}"

unaryOperators=("+" "-" "!" "?")
for unaryOperator in ${unaryOperators[@]}; do
    testValidInput "int f() { 1 + ${unaryOperator}id; }"
    testValidInput "int f() { 1 + ${unaryOperator}func(); }"
    testValidInput "int f() { 1 + ${unaryOperator}1; }"
    testValidInput "int f() { 1 + ${unaryOperator}1.0; }"
done

testValidInput "int f() { 1 + &id; }"
testValidInput "int f() { 1 + \*id; }"
testValidInput "int f() { 1 + #id; }"
testValidInput "int f() { 1 + \*&\*&id; }"

# ??? Bin??rios
#   ??? + soma
#   ??? - subtra????o
#   ??? * multiplica????o
#   ??? / divis??o
#   ??? % resto da divis??o inteira
#   ??? | bitwise OR
#   ??? & bitwise AND
#   ??? ?? exponencia????o
#   ??? todos os comparadores relacionais
#   ??? todos os operadores logicos ( && para o e l??gico, || para o ou l??gico) 

argBinaryOperator=("+" "-" "\*" "/" "%" "|" "&" "^" "!=" "==" "<=" ">=" "&&" "||")
for expressionArg in ${expressionArgs[@]}; do
for binaryOperator in ${argBinaryOperator[@]}; do
    testValidInput "int f() { $expressionArg $binaryOperator $expressionArg; }"
    testValidInput "int f() { $expressionArg $binaryOperator $expressionArg $binaryOperator $expressionArg; }"
done
done

# ??? Tern??rios
#   ??? ? seguido de :, conforme a sintaxe express??o ? express??o : express??o

testValidInput "int f() { id = id ? 1 : 2 ; }"
testValidInput "int f() { id = 1 + 1 ? id : 2.0 ; }"
testValidInput "int f() { id = 1 + 1 ? 1 + 1 : 2.0 ; }"
testValidInput "int f() { id =  1 + 1 ? (1 + 1 ? 1 + 1 : 1+1) : 2 ; }"

# As regras de associatividade e preced??ncia de operadores matem??ticos s??o
# aquelas tradicionais de linguagem de programa????o e da matem??tica.
# Recomenda-se que tais regras sejam j?? incorporadas na solu????o desta etapa,
# ou atrav??s de constru????es gramaticais ou atrav??s de comandos do bison 
# espec??ficos para isso (%left, %right). A solu????o via constru????es gramaticais
# e recomendada. Enfim, nos casos n??o cobertos por esta regra geral, temos as
# seguintes regras de associatividade:

# ??? Associativos ?? direita
#   ??? &, * (acesso ao valor do ponteiro), #

echo "RESULTS:"
echo "Passed tests: $successfulTestsCounter"
echo "Failed tests: $failedTestsCounter"

make clean