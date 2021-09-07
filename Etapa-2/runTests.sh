#!/bin/bash

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
        sleep 0.0001

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
#TODO: testInvalidInput "int f() { int id1 <= false; }"

for literalValue in ${literalValues[@]}; do
    testValidInput "int f() { id = $literalValue; }"
done
#TODO: "int f() { id1 = <expressão>; }"

for literalValue in ${literalValues[@]}; do
    testValidInput "int f() { id[1] = $literalValue; }"
done
#TODO: "int f() { id1[<expressão>] = true; }"

testValidInput "int f() { int id1 <= id2; int id1 <= id2; }"
testValidInput "int f() { id = true; id = true; }"
testValidInput "int f() { id = true; int id1 <= id2; }"
testValidInput "int f() { int id1 <= id2; id = true; }"

testValidInput "int f() { input id1; }"
testValidInput "int f() { output id1; }"

for literalValue in ${literalValues[@]}; do
    testValidInput "int f() { output $literalValue; }"
done

# Chamada de função
# Uma chamada de funcão consiste no nome da função, seguida de argumentos entre parenteses separados por vírgula. [...]

testValidInput "int f() { funcName(); }"
testValidInput "int f() { funcName(id1); }"
testValidInput "int f() { funcName(id1, id2, id3); }"

for literalValue in ${literalValues[@]}; do
    testValidInput "int f() { funcName($literalValue); }"
done

testValidInput "int f() { funcName(1, 'z', 5.0); }"

# Um argumento pode ser uma expressao. 
#TODO: testValidInput "int f() { funcName(<expressao>); }"

# Comandos de Shift

# Sendo numero um literal inteiro positivo, temos os exemplos válidos abaixo.
# Os exemplos são dados com <<, mas as entradas são sintaticamente válidas tambem para >>.
# O numero deve ser representado por um literal inteiro.
# identificador << número
# identificador[expressão] << número

testValidInput "int f() { id << 1; }"
testValidInput "int f() { id >> 1; }"
testValidInput "int f() { id[1] << 1; }"
testValidInput "int f() { id[1] >> 1; }"

testValidInput "int f() { id << +1; }"
testValidInput "int f() { id >> +1; }"
testValidInput "int f() { id[1] << +1; }"
testValidInput "int f() { id[1] >> +1; }"

# TODO: Block negative values
# testInvalidInput "int f() { id << -1; }"
# testInvalidInput "int f() { id >> -1; }"
# testInvalidInput "int f() { id[1] << -1; }"
# testInvalidInput "int f() { id[1] >> -1; }"

# TODO: testValidInput "int f() { id[<expressão>] << +1; }"

echo "RESULTS:"
echo "Passed tests: $successfulTestsCounter"
echo "Failed tests: $failedTestsCounter"

make clean