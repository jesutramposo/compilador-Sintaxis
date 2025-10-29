%option noyywrap


/* librerias importadas */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "y.tab.h"

    void yyerror (char const *s){
        fprintf (stderror, "%s\n", s)
    }
}%


/* que existe en nuestro compilador */
COMIENZO            "utn"
DIGITO              [0-9]
LETRA               [a-zA-Z]
GUIONES             [-_]
CHAR_COMA           [","]
CHAR_PUNTO          ["."] /*NUESTRO PUNTO Y COMA XDDDDDD*/
CHAR_DOS_PUNTOS     [":"]
FIN                 "miutn"

/* operadores */
PARENTESIS_A        [")"]
PARENTESIS_C        ["("]
MULT                ["*"]
SUMA                ["+"]
MENOS               ["-"]
DIVISION            ["/"]

/*comparativos*/


/* nuestros ids*/
IDENTIFICADOR                  {LETRA}({LETRA}|{DIGITO}|{GUIONES})* /*el id de variable puede ser una letra al menos o combinaciones*/
CONST_INT                      ((-?[1-9][0-9]{0,4})|0)
CONST_FLOAT                    {DIGITO}{0,8}{CHAR_COMA}{DIGITO}{1,8}

/* const cadena */
//CONST_STR                      \"[^\n"]*\"




/* tokens (hay que ver como podemos ingresar utn para que empience)*/
%%


%%