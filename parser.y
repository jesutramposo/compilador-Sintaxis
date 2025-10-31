/* parser.y — bison en espanol con ejecucion basica y manejo de errores lexicos */

%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  int yylex(void);
  void yyerror(const char *s);

  extern int yylineno;

  /* contadores de errores */
  int errores_lexicos = 0;
  int errores_sintacticos = 0;

  /* tabla de variables simple (sin structs) */
  #define MAX_VARS 200
  char* nombres_variables[MAX_VARS];
  int valores_variables[MAX_VARS];
  int cantidad_variables = 0;

  /* flag y texto de ultima cadena sin cerrar (seteado por el lexer) */
  extern int cadena_sin_cerrar_flag;
  extern char *ultima_cadena_sin_cerrar;

  /* funciones de simbolos simples */
  int buscar_indice_variable(const char* nombre) {
    for (int i = 0; i < cantidad_variables; ++i) {
      if (strcmp(nombres_variables[i], nombre) == 0) return i;
    }
    return -1;
  }

  void asignar_variable(const char* nombre, int valor) {
    int idx = buscar_indice_variable(nombre);
    if (idx >= 0) {
      valores_variables[idx] = valor;
    } else {
      if (cantidad_variables < MAX_VARS) {
        nombres_variables[cantidad_variables] = strdup(nombre);
        valores_variables[cantidad_variables] = valor;
        cantidad_variables++;
      } else {
        fprintf(stderr, "error: demasiadas variables.\n");
      }
    }
  }

  int obtener_valor_variable(const char* nombre) {
    int idx = buscar_indice_variable(nombre);
    if (idx >= 0) return valores_variables[idx];
    /* si no existe, por simplicidad devolvemos 0 */
    return 0;
  }

%}

/* ===== Valores semánticos ===== */
%union {
  int   ival;   /* para CONST_ENTERO y valores de expresion */
  char* sval;   /* para IDENTIFICADOR, CONST_FLOTANTE, CONST_CADENA */
}

/* ===== Tokens (segun el lexer) ===== */
%token COMIENZO FIN_PROGRAMA
%token LEER ESCRIBIR REPETIR VECES SI ENTONCES FINSI
%token ASIGNACION
%token FIN_SENTENCIA
%token COMP_MAYOR_IGUAL COMP_MENOR_IGUAL COMP_IGUAL COMP_DISTINTO COMP_MAYOR COMP_MENOR
%token <sval> IDENTIFICADOR
%token <ival> CONST_ENTERO
%token <sval> CONST_FLOTANTE
%token <sval> CONST_CADENA

/* ===== Declaraciones de tipo para no-terminales (arregla los errores de bison) ===== */
/* declaramos que expr, condicion y comp_op devuelven enteros (ival) */
%type <ival> expr condicion comp_op

/* precedencia */
%left COMP_MAYOR_IGUAL COMP_MENOR_IGUAL COMP_IGUAL COMP_DISTINTO COMP_MAYOR COMP_MENOR
%left '+' '-'
%left '*' '/'
%right UMINUS

%start programa

%%  /* =================== Gramatica =================== */

programa
  : COMIENZO cuerpo FIN_PROGRAMA
  ;

cuerpo
  : /* vacio */
  | cuerpo sentencia
  ;

sentencia
  : asignacion FIN_SENTENCIA
  | lectura FIN_SENTENCIA
  | escritura FIN_SENTENCIA
  | repetir_sentencia FIN_SENTENCIA
  | si_sentencia
  | error FIN_SENTENCIA { yyerrok; }
  ;

asignacion
  : IDENTIFICADOR ASIGNACION expr
      {
        /* si el lexer habia marcado una cadena sin cerrar, y la expr vino como cadena vacia,
           mostramos el mensaje pedido por el profe */
        if (cadena_sin_cerrar_flag && ultima_cadena_sin_cerrar != NULL && strlen(ultima_cadena_sin_cerrar) > 0) {
          fprintf(stderr, "Error: No hay valor asignado para '%s'\n", ultima_cadena_sin_cerrar);
          /* limpiamos el flag */
          free(ultima_cadena_sin_cerrar);
          ultima_cadena_sin_cerrar = NULL;
          cadena_sin_cerrar_flag = 0;
        } else {
          asignar_variable($1, $3);
        }
        free($1);
      }
  ;

lectura
  : LEER '(' IDENTIFICADOR ')'
      {
        int valor_leido = 0;
        printf("Ingresa el valor de %s: ", $3);
        if (scanf("%d", &valor_leido) != 1) {
          valor_leido = 0;
          int c;
          while ((c = getchar()) != '\n' && c != EOF);
        }
        asignar_variable($3, valor_leido);
        free($3);
        yyerrok;
      }
  ;

escritura
  : ESCRIBIR '(' expr ')'
      {
        printf("%d\n", $3);
      }
  | ESCRIBIR '(' CONST_CADENA ')'
      {
        char* texto = $3;
        size_t len = strlen(texto);
        if (len >= 2 && texto[0] == '"' && texto[len-1] == '"') {
          char* sin_comillas = malloc(len - 1);
          strncpy(sin_comillas, texto + 1, len - 2);
          sin_comillas[len - 2] = '\0';
          printf("%s\n", sin_comillas);
          free(sin_comillas);
        } else {
          printf("%s\n", texto);
        }
        free(texto);
      }
  ;
repetir_sentencia
  : REPETIR expr VECES bloque
      {
        /* implementacion simple: el bloque se ejecuta cuando se parsea.
           para repetir realmente n veces habria que almacenar las sentencias
           y luego ejecutarlas n veces (construir AST / lista). */
        (void)$2;
      }
  ;

si_sentencia
  : SI condicion ENTONCES bloque FINSI
      {
        /* nota: similar a repetir, el control real para evitar ejecutar el bloque
           si la condicion es falsa requiere construir/ejecutar AST. */
      }
  ;

bloque
  : sentencia
  | '{' lista_sentencias '}'
  ;

lista_sentencias
  : /* vacio */
  | lista_sentencias sentencia
  ;

condicion
  : expr comp_op expr
      {
        int v1 = $1;
        int v2 = $3;
        int resultado = 0;
        if ($2 == COMP_MAYOR_IGUAL) resultado = (v1 >= v2);
        else if ($2 == COMP_MENOR_IGUAL) resultado = (v1 <= v2);
        else if ($2 == COMP_IGUAL) resultado = (v1 == v2);
        else if ($2 == COMP_DISTINTO) resultado = (v1 != v2);
        else if ($2 == COMP_MAYOR) resultado = (v1 > v2);
        else if ($2 == COMP_MENOR) resultado = (v1 < v2);

        $$ = resultado;
      }
  | '(' condicion ')'
      {
        $$ = $2;
      }
  ;

comp_op
  : COMP_MAYOR_IGUAL  { $$ = COMP_MAYOR_IGUAL; }
  | COMP_MENOR_IGUAL  { $$ = COMP_MENOR_IGUAL; }
  | COMP_IGUAL        { $$ = COMP_IGUAL; }
  | COMP_DISTINTO     { $$ = COMP_DISTINTO; }
  | COMP_MAYOR        { $$ = COMP_MAYOR; }
  | COMP_MENOR        { $$ = COMP_MENOR; }
  ;

/* expresiones: devolvemos un int en $$ */
expr
  : expr '+' expr   { $$ = $1 + $3; }
  | expr '-' expr   { $$ = $1 - $3; }
  | expr '*' expr   { $$ = $1 * $3; }
  | expr '/' expr   {
                      if ($3 == 0) { $$ = 0; } 
                      else { $$ = $1 / $3; }
                    }
  | '-' expr %prec UMINUS { $$ = - $2; }
  | '(' expr ')'      { $$ = $2; }
  | CONST_ENTERO      { $$ = $1; }
  | CONST_FLOTANTE    {
                        /* por simplicidad convertimos float a 0 */
                        $$ = 0;
                        free($1);
                      }
  | IDENTIFICADOR     {
                        $$ = obtener_valor_variable($1);
                        free($1);
                      }
  | CONST_CADENA      {
                        /* cadena en contexto de expresion -> no numerica */
                        $$ = 0;
                        free($1);
                      }
  ;

%%  /* =================== Codigo C de apoyo =================== */

void yyerror(const char *s) {
  errores_sintacticos++;
  /* mostramos exactamente 'syntax error' para coincidir con el ejemplo del profesor */
  fprintf(stderr, "syntax error\n");
}

int main(void) {
  printf(">> Ingrese su programa (termine con 'finutn'):\n");

  yyparse();  /* analiza hasta que vea finutn o error /

  / mensajes finales */
  if (errores_sintacticos > 0)
    printf("\nErrores de compilacion\n");

  printf("Errores sintacticos: %d   Errores lexicos: %d\n",
         errores_sintacticos, errores_lexicos);

  return 0;
}