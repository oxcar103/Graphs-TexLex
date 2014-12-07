%{
#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <queue>
#include <string>

using namespace std;
    int i;
    string colors[] = {"red", "blue", "green", "yellow", "orange", "magenta", "cyan", "violet", "pink", "olive"};
    queue<string> graphs;
    ofstream file;
    
    void function_found (string function);
    string transform_function(string latex_form);
    void insert_graphs ();
%}

%x MATH_MODE
%x MATH_ENV

num             [0-9]
var             x
f_var           [yf](\({var}\))?
add             \ ?\+\ ?
sub             \ ?\-\ ?
eq              \ ?\=\ ?
real            -?{num}+(\.{num}+)?

var_exp         \^{real}
monomial        {real}?({var}({var_exp})?)|{real}
polynomial      {monomial}(({add}|{sub}){monomial})*
p_function      {f_var}{eq}{polynomial}
exp             \\exp\({p_function}\){var_exp}?
log             \\log\({p_function}\){var_exp}?
l/e_function    ({exp}|{log})(({add}|{sub}){p_function})*
function        ({p_function}|{l/e_function})


%%

^"\\documentclass"(.)*                  { file << yytext << "\n\\usepackage{tikz}"; }
\$                                      { file << yytext; BEGIN(MATH_MODE); }
<MATH_MODE>\$                           { file << yytext; BEGIN(INITIAL); }
\$\$                                    { file << yytext; BEGIN(MATH_ENV); }
<MATH_ENV>\$\$                          { file << yytext; BEGIN(INITIAL); }
<MATH_MODE>{function}                   { file << yytext; function_found(string(yytext)); }
<MATH_ENV>{function}                    { file << yytext; function_found(string(yytext)); }
(\n\n|"\\")                             { file << yytext; if(!graphs.empty()){insert_graphs();} }
(.|\n)                                  { file << yytext; }

%%
int main (int argc, char *argv[]) {
    if (argc != 3) {
        cerr << "Se requiere el fichero de entrada y de salida\n";
        exit(-1);
    }

    file.open(argv[2], ios::trunc);

    if (file == NULL) {
        cerr << "El fichero " << argv[2] << " no se puede abrir\n";
        exit (-1);
    }

    yyin = fopen (argv[1], "rt");
    if (yyin == NULL) {
        cerr << "El fichero " << argv[1] << " no se puede abrir\n";
        exit (-1);
    }

    i = 0;

    yylex();

    return 0;
}

void function_found (string function){
    graphs.push(transform_function(function));
}

string transform_function(string latex_form){
    string result = latex_form.erase(0, latex_form.find("=") + 1);
    int replace_pos;

    // Producto
    while((replace_pos = result.find("\\cdot")) != -1){
        result = result.replace(replace_pos, 4, "*");
    }

    // Potencia
    while((replace_pos = result.find("^")) != -1){
        result = result.replace(replace_pos, 1, "**");
    }

    // Exponencial
    if((replace_pos = result.find("\\exp")) != -1){
        result = result.erase(replace_pos, 1);
    }

    // Logaritmo
    if((replace_pos = result.find("\\log")) != -1){
        result = result.erase(replace_pos, 1);
    }

    return result;
}

void insert_graphs (){
    file << "\\begin{tikzpicture}[domain=-3:3]\n"
         << "\\draw[->] (-3.1,0) -- (3.2,0) node[right] {$x$};\n"
         << "\\draw[->] (0,-6) -- (0,13) node[above] {$f(x)$};\n";
    
    while(!graphs.empty()){
        file << "\\draw[color=" << colors[i] << "] plot function{"<< graphs.front() <<"};\n";
        graphs.pop();
        i = (i + 1) % 10;
    }

    file << "% xticks and yticks\n"
         << "\\foreach \\x in {-3,-2,...,3}\n"
         << "\\node at (\\x, 0) [below] {\\x};\n"
         << "\\foreach \\y in {-6,-5,...,13}\n"
         << "\\node at (0,\\y) [left] {\\y};\n"
         << "\\end{tikzpicture}\n\n";
}

