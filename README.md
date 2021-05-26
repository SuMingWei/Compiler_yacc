# Compiler Parser(`yacc`)

###### tags: `compiler` `lab2`

## Introduction
A parser for ***µC*** language with yacc.

## Enviornment
* For Linux
    * Ubuntu 18.04 LTS
    * Install dependencies:
        ```bash=
        $ sudo apt install gcc flex bison python3 git
        ```
## Yacc Definitions
1. Define token and Types
2. Design μC grammar and implement the related actions
3. Handle semantic errors 

## Symbol Tables
1. Functions
    * `create_symbol`: Create a symbol table when entering a new scope. 
    * `insert_symbol`: Insert an entry for a variable declaration. 
    * `lookup_symbol`: Look up an entry in the symbol table. 
    * `dump_symbol`: Dump all contents in the symbol table of current scope and its entries when exiting a scope. 
2. Scope level
    * The global scope level is zero and is increased by one when entering a new block.
3. Table fields
    ![](https://i.imgur.com/H52DN9c.png)

## µC Specification
* Types:
    ![](https://i.imgur.com/x5sWQJq.png)
* Expressions:
    ![](https://i.imgur.com/BMzaffI.png)
    * Arithmetic operations:
        ![](https://i.imgur.com/6LpXN9Y.png)
    * Primary expressions
        ![](https://i.imgur.com/1GpQ5FI.png)
    * Index expressions
        ![](https://i.imgur.com/SwDGHfG.png)
    * Conversions (Type casting)
        ![](https://i.imgur.com/3JHhVPk.png)
* Statements
    ![](https://i.imgur.com/WkHQR7W.png)
    * Declarations statements
        ![](https://i.imgur.com/iqfn4H1.png)
    * Assignments statements
        ![](https://i.imgur.com/yG4rFtn.png)
    * IncDec statements
        ![](https://i.imgur.com/MjE1Hff.png)
    * Block
        ![](https://i.imgur.com/tk5cNXO.png)
    * If statements
        ![](https://i.imgur.com/0L80Do4.png)
    * While and For statements
        ![](https://i.imgur.com/YMVoZJz.png)
    * Print statements
        ![](https://i.imgur.com/RKDx46e.png)

## How to Debug
* Compile source code and feed the input to your program, then compare with the ground truth.
    ```bash=
    $ make clean && make
    $ ./myparser < input/in01_arithmetic.c > tmp.out 
    $ diff -y tmp.out answer/in01_arithmetic.out
    ```
    ![](https://i.imgur.com/c6ZohIf.png)


## Judge
```bash=
python3 judge/judge.py
```
![](https://i.imgur.com/8gdCRup.png)


    


