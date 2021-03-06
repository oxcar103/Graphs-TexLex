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
times           \ ?"\\cdot"\ ?
eq              \ ?\=\ ?
real            -?{num}+("."{num}+)?

var_exp         \^{real}
monomial        ({var}({var_exp})?)|{real}
polynomial      {monomial}(({add}|{sub}){monomial})*
elsc            \\(exp|log|sin|cos)\({polynomial}\){var_exp}?
type_of_func    ({real}{times})?({polynomial}|{elsc})
right_part      ({type_of_func})(({add}|{sub})({type_of_func}))*
function        {f_var}{eq}{right_part}

%%

^"\\documentclass"(.)*                  { file << yytext << "\n\\usepackage{tikz}"; }
\$                                      { file << yytext; BEGIN(MATH_MODE); }
<MATH_MODE>\$                           { file << yytext; BEGIN(INITIAL); }
\$\$                                    { file << yytext; BEGIN(MATH_ENV); }
<MATH_ENV>\$\$                          { file << yytext; BEGIN(INITIAL); }
<MATH_MODE>{function}                   { file << yytext; graphs.push(string(yytext)); }
<MATH_ENV>{function}                    { file << yytext; graphs.push(string(yytext)); }
(\n\n|"\\\\")                           { file << yytext; if(!graphs.empty()){insert_graphs();} }

<MATH_MODE>(.|\n)                       { file << yytext; }
<MATH_ENV>(.|\n)                        { file << yytext; }
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

string transform_function(string latex_form){
    string result = latex_form.erase(0, latex_form.find("=") + 1);
    int replace_pos;

    // Espacios
    while((replace_pos = result.find(" ")) != -1){
        result = result.erase(replace_pos, 1);
    }

    // Producto
    while((replace_pos = result.find("\\cdot")) != -1){
        result = result.replace(replace_pos, 5, "*");
    }

    // Potencia
    while((replace_pos = result.find("^")) != -1){
        result = result.replace(replace_pos, 1, "**");
    }

    // Exponencial
    while((replace_pos = result.find("\\exp")) != -1){
        result = result.erase(replace_pos, 1);
    }

    // Logaritmo
    while((replace_pos = result.find("\\log")) != -1){
        result = result.erase(replace_pos, 1);
    }

    // Seno
    while((replace_pos = result.find("\\sin")) != -1){
        result = result.erase(replace_pos, 1);
    }

    // Coseno
    while((replace_pos = result.find("\\cos")) != -1){
        result = result.erase(replace_pos, 1);
    }

    return result;
}

void insert_graphs (){
    file << "\\begin{tikzpicture}[domain=-2:2]\n"
         << "\\draw[->] (-2.1,0) -- (2.2,0) node[right] {$x$};\n"
         << "\\draw[->] (0,-2) -- (0,4) node[above] {$f(x)$};\n";
    
    while(!graphs.empty()){
        file << "\\draw[color=" << colors[i] << "] plot function{"<< transform_function(graphs.front()) <<"} node[right] {$" << graphs.front() << "$};\n";
        graphs.pop();
        i = (i + 1) % 10;
    }

    file << "% xticks and yticks\n"
         << "\\foreach \\x in {-2,-1,...,2}\n"
         << "\\node at (\\x, 0) [below] {\\x};\n"
         << "\\foreach \\y in {-2,-1,...,4}\n"
         << "\\node at (0,\\y) [left] {\\y};\n"
         << "\\end{tikzpicture}\n";
}

