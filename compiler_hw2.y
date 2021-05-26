/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */

    struct data {
        int index;
        char *name;
        char *type;
        int address;
        int lineno;
        char *elementType;
    };

    struct data symbol_table[100][100];
    int tail[100] = {0};
    int cur_addr = 0;
    int cur_scope = 0;

    static void create_symbol();
    static void insert_symbol(char *, char *, char *);
    static char *lookup_symbol(char *);
    static void dump_symbol();
    static char *getType(char *);
    static int check_id(char *);
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    char *id;
    char *type;
    char *operator;
}

/* Token without return */
%token AND OR
%token QUO REM 
%token INC DEC
%token EQL NEQ LSS LEQ GTR GEQ
%token ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token TRUE FALSE
%token INT FLOAT BOOL STRING
%token PRINT IF ELSE FOR WHILE
%token SEMICOLON

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <id> IDENT
/* Nonterminal with return, which need to sepcify type */
%type <type> Type TypeName
%type <operator> Unary_op Cmp_op Add_op Mul_op Assign_op
%type <type> Expression Logical_OR_Expr Logical_And_Expr Comparison_Expr Addition_Expr Multiplication_Expr
%type <type> AssignmentExpr UnaryExpr PrimaryExpr Operand Literal IndexExpr ConversionExpr 

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList 
;

StatementList
    : Statement StatementList 
    | Statement
;

Statement
    : DeclarationStmt
    | ExpressionStmt
    | AssignmentStmt
    | IncDecStmt
    | Block
    | IfStmt
    | WhileStmt
    | ForStmt
    | PrintStmt
;

DeclarationStmt
    : Type IDENT SEMICOLON {
        // id has been declared
        if(check_id($2) != -1){
            char errorMessage[100] = "";        
            snprintf(errorMessage,sizeof(errorMessage),
                        "%s redeclared in this block. previous declaration at line %d",
                        $2, check_id($2));
            yyerror(errorMessage);
        }else{
            insert_symbol($2,$1,"-");
        }
        
    }
    | Type IDENT '[' Expression ']' SEMICOLON {
        // id has been declared
        if(check_id($2) != -1){
            char errorMessage[100] = "";        
            snprintf(errorMessage,sizeof(errorMessage),
                        "%s redeclared in this block. previous declaration at line %d",
                        $2, check_id($2));
            yyerror(errorMessage);
        }else{
            insert_symbol($2,"array",$1);
        }
    }
    | Type IDENT ASSIGN Expression SEMICOLON {
        // id has been declared
        if(check_id($2) != -1){
            char errorMessage[100] = "";        
            snprintf(errorMessage,sizeof(errorMessage),
                        "%s redeclared in this block. previous declaration at line %d",
                        $2, check_id($2));
            yyerror(errorMessage);
        }else{
            insert_symbol($2,$1,"-");
        }
    }    
    | Type IDENT '[' Expression ']' ASSIGN Expression SEMICOLON {
        // id has been declared
        if(check_id($2) != -1){
            char errorMessage[100] = "";        
            snprintf(errorMessage,sizeof(errorMessage),
                        "%s redeclared in this block. previous declaration at line %d",
                        $2, check_id($2));
            yyerror(errorMessage);
        }else{
            insert_symbol($2,"array",$1);
        }
    }
;

ExpressionStmt
    : Expression SEMICOLON
;

AssignmentStmt
    : AssignmentExpr SEMICOLON
;
AssignmentExpr
    : Expression Assign_op Expression { 
        // intLit/floatLit cannot be assigned
        if(strcmp($1,"intLit") == 0 || strcmp($1, "floatLit") == 0){
            char errorMessage[100] = "";
            snprintf(errorMessage,sizeof(errorMessage),
                        "cannot assign to %s", getType($3));
            yyerror(errorMessage);
        }
        // mismatched types
        else if(strcmp(getType($1),getType($3)) != 0){
            char errorMessage[100] = "";
            snprintf(errorMessage,sizeof(errorMessage),
                        "invalid operation: %s (mismatched types %s and %s)",
                        $2, getType($1),getType($3));
            yyerror(errorMessage);
        }else{
            $$ = $1;
        }

        printf("%s\n", $2); 
    }
;

IncDecStmt  
    : IncDecExpr SEMICOLON
;
IncDecExpr 
    : Expression INC { printf("INC\n"); }
    | Expression DEC { printf("DEC\n"); }
;

Block
    : '{' { create_symbol(); }
        StatementList 
      '}' { dump_symbol(); }
;

IfStmt
    : IF Condition Block
    | IF Condition Block ELSE IfStmt
    | IF Condition Block ELSE Block
;

WhileStmt
    : WHILE '(' Condition ')' Block
;

Condition
    : Expression {
        // condition must be bool
        if(strcmp(getType($1), "bool") != 0){
            printf("error:%d: non-bool (type %s) used as for condition\n", yylineno+1, getType($1));
        }
    }
;

ForStmt
    : FOR '(' ForClause ')' Block
;
ForClause 
    : AssignmentStmt ExpressionStmt SimpleExpr
;
SimpleExpr
    : AssignmentExpr
    | Expression
    | IncDecExpr
;

PrintStmt
    : PRINT '(' Expression ')' SEMICOLON { printf("PRINT %s\n",getType($3)); }
;

Expression 
    : Logical_OR_Expr { $$ = $1; }
;

Logical_OR_Expr
    : Logical_And_Expr { $$ = $1; }
    | Logical_OR_Expr OR Logical_And_Expr { 
        if(strcmp(getType($1),"bool") == 0 && strcmp(getType($3),"bool") == 0){
            $$ = "boolLit";
        }
        // operator OR not defined
        else{
            char errorMessage[100] = "";
            char *errorType;
            if(strcmp(getType($1),"bool") == 1){
                errorType = getType($1);
            }else{
                errorType = getType($3);
            }
            snprintf(errorMessage,sizeof(errorMessage),
                        "invalid operation: (operator OR not defined on %s)",errorType);
            yyerror(errorMessage);
        }
        printf("OR\n"); 
    }
;

Logical_And_Expr
    : Comparison_Expr { $$ = $1; }
    | Logical_And_Expr AND Comparison_Expr { 
        if(strcmp(getType($1),"bool") == 0 && strcmp(getType($3),"bool") == 0){
            $$ = "boolLit";
        }
        // operator AND not defined
        else{
            char errorMessage[100] = "";
            char *errorType;
            if(strcmp(getType($1),"bool") != 0){
                errorType = getType($1);
            }else{
                errorType = getType($3);
            }
            snprintf(errorMessage,sizeof(errorMessage),
                        "invalid operation: (operator AND not defined on %s)",errorType);
            yyerror(errorMessage);
        }
        printf("AND\n"); 
    }
;

Comparison_Expr
    : Addition_Expr { $$ = $1; }
    | Comparison_Expr Cmp_op Addition_Expr { 
        $$ = "boolLit";
        printf("%s\n", $2); 
    }
;

Addition_Expr
    : Multiplication_Expr { $$ = $1; }
    | Addition_Expr Add_op Multiplication_Expr { 
        if(strcmp(getType($1),getType($3)) == 0){
            $$ = $1;
        }
        // mismatched types
        else{
            char errorMessage[100] = "";
            char *errorOp = $2;
            snprintf(errorMessage,sizeof(errorMessage),
                        "invalid operation: %s (mismatched types %s and %s)",
                        errorOp, getType($1),getType($3));
            yyerror(errorMessage);
        } 
        printf("%s\n", $2); 
    }
;

Multiplication_Expr
    : UnaryExpr { $$ = $1; }
    | Multiplication_Expr Mul_op UnaryExpr { 
        char *errorOp = $2;
        if(strcmp(errorOp,"REM") == 0){
            // operator REM not defined on float
            if(strcmp(getType($1),"float") == 0 || strcmp(getType($3),"float") == 0){
                char errorMessage[100] = "";
                snprintf(errorMessage,sizeof(errorMessage),
                            "invalid operation: (operator REM not defined on float)");
                yyerror(errorMessage);
            }else{
                $$ = $1;
            }
        }else{
            if(strcmp(getType($1),getType($3)) == 0){
                $$ = $1;
            }
            // mismatched types
            else{
                char errorMessage[100] = "";
                snprintf(errorMessage,sizeof(errorMessage),
                            "invalid operation: %s (mismatched types %s and %s)",
                            errorOp, getType($1),getType($3));
                yyerror(errorMessage);
            } 
        }
        printf("%s\n", $2); 
    }
;

UnaryExpr
    : PrimaryExpr        { $$ = $1; }
    | Unary_op UnaryExpr { 
        $$ = $2;
        printf("%s\n",$1); 
    }
;

PrimaryExpr
    : Operand         { $$ = $1; }
    | IndexExpr       { $$ = $1; }
    | ConversionExpr
;

Operand
    : Literal            { $$ = $1; }
    | IDENT              { $$ = lookup_symbol($1); }
    | '(' Expression ')' { $$ = $2; }
;

IndexExpr
    : PrimaryExpr '[' Expression ']' { $$ = $1; }
;

ConversionExpr
    : '(' Type ')' Expression {
        $$ = $2;

        if(strcmp(getType($4),"int") == 0){
            printf("I to ");
        }else{
            printf("F to ");
        }
        if(strcmp($2,"int") == 0){
            printf("I\n");
        }else{
            printf("F\n");
        }
    }
;

Literal
    : INT_LIT {
        $$ = "intLit";
        printf("INT_LIT %d\n", $<i_val>1);
    }
    | FLOAT_LIT {
        $$ = "floatLit";
        printf("FLOAT_LIT %f\n", $<f_val>1);
    }
    | '"' STRING_LIT '"' {
        $$ = "stringLit";
        printf("STRING_LIT %s\n", $<s_val>2);
    }
    | TRUE {
        $$ = "boolLit";
        printf("TRUE\n");
    }
    | FALSE {
        $$ = "boolLit";
        printf("FALSE\n");
    }
;

Unary_op
    : '+' { $$ = "POS"; }
    | '-' { $$ = "NEG"; }
    | '!' { $$ = "NOT"; }
;

Cmp_op
    : EQL { $$ = "EQL"; }
    | NEQ { $$ = "NEQ"; }
    | LSS { $$ = "LSS"; }
    | LEQ { $$ = "LEQ"; }
    | GTR { $$ = "GTR"; }
    | GEQ { $$ = "GEQ"; }
;

Add_op
    : '+' { $$ = "ADD"; }
    | '-' { $$ = "SUB"; } 
;
 
Mul_op
    : '*' { $$ = "MUL"; }
    | QUO { $$ = "QUO"; }
    | REM { $$ = "REM"; }
;

Assign_op
    : ASSIGN { $$ = "ASSIGN"; }
    | ADD_ASSIGN { $$ = "ADD_ASSIGN"; }
    | SUB_ASSIGN { $$ = "SUB_ASSIGN"; }
    | MUL_ASSIGN { $$ = "MUL_ASSIGN"; }
    | QUO_ASSIGN { $$ = "QUO_ASSIGN"; }
    | REM_ASSIGN { $$ = "REM_ASSIGN"; }
;

Type
    : TypeName { $$ = $1; }
;

TypeName
    : INT { $$ = "int"; }
    | FLOAT { $$ = "float"; }
    | STRING { $$ = "string"; }
    | BOOL { $$ = "bool"; }
;


%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yyparse();
    dump_symbol();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol(){
    cur_scope++;
}

static void insert_symbol(char *id, char *type, char *elementType){
    int cur_index = tail[cur_scope];
    symbol_table[cur_scope][cur_index].index = cur_index;
    symbol_table[cur_scope][cur_index].name = id;
    symbol_table[cur_scope][cur_index].type = type;
    symbol_table[cur_scope][cur_index].address = cur_addr;
    symbol_table[cur_scope][cur_index].lineno = yylineno;
    symbol_table[cur_scope][cur_index].elementType = elementType;

    cur_addr++;
    tail[cur_scope]++;
    printf("> Insert {%s} into symbol table (scope level: %d)\n",id,cur_scope);
}

static char *lookup_symbol(char *id){
    bool find_flag = false;
    int match_scope,match_index;
    for(int i=cur_scope;i>=0;i--){
        for(int j=0;j<tail[i];j++){
            if(strcmp(symbol_table[i][j].name , id) == 0){
                printf("IDENT (name=%s, address=%d)\n",
                       symbol_table[i][j].name , symbol_table[i][j].address);
                find_flag = true;
                match_scope = i;
                match_index = j;
                break;
            }
        }
        if(find_flag){
            break;
        }
    }
    if(find_flag){
        char *find_type = symbol_table[match_scope][match_index].type; 
        if(strcmp(find_type,"array") == 0){
            return symbol_table[match_scope][match_index].elementType;
        }else{
            return find_type;
        }
    }else{
        // undefined
        char errorMessage[100] = "";        
        snprintf(errorMessage,sizeof(errorMessage),
                    "undefined: %s", id);
        yyerror(errorMessage);
        return "int"; // set undifined type to int
    }
    
}

static void dump_symbol(){
    printf("> Dump symbol table (scope level: %d)\n",cur_scope);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
            "Index", "Name", "Type", "Address", "Lineno", "Element type");
    for(int i=0;i<tail[cur_scope];i++){
        printf("%-10d%-10s%-10s%-10d%-10d%s\n",
            symbol_table[cur_scope][i].index,
            symbol_table[cur_scope][i].name,
            symbol_table[cur_scope][i].type,
            symbol_table[cur_scope][i].address,
            symbol_table[cur_scope][i].lineno,
            symbol_table[cur_scope][i].elementType);
    }
    // clear table
    tail[cur_scope] = 0;
    cur_scope--;
}

static char *getType(char *input){
    if(strcmp(input,"intLit") == 0){
        return "int";
    }
    if(strcmp(input,"floatLit") == 0){
        return "float";
    }
    if(strcmp(input,"stringLit") == 0){
        return "string";
    }
    if(strcmp(input,"boolLit") == 0){
        return "bool";
    }
    return input;
}

static int check_id(char *id){
    for(int i=0;i<tail[cur_scope];i++){
        if(strcmp(symbol_table[cur_scope][i].name , id) == 0){
            return symbol_table[cur_scope][i].lineno;
        }
    }
    // if not found then return -1
    return -1;
}