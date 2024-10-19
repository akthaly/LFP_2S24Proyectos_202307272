import tkinter as tk
from tkinter import ttk

# Clase Token para representar cada token o error léxico
class Token:
    def __init__(self, lexeme, type, line, column):
        self.lexeme = lexeme
        self.type = type
        self.line = line
        self.column = column

# Función que imprime los tokens o errores léxicos encontrados
def print_tokens_in_table(tokens, tree):
    # Limpiar el contenido de la tabla antes de agregar los nuevos datos
    for row in tree.get_children():
        tree.delete(row)

    # Mostrar solo errores léxicos si existen, o todos los tokens si no hay errores
    lexical_errors = [token for token in tokens if "Error Lexico" in token.type]
    
    if lexical_errors:
        for token in lexical_errors:
            tree.insert('', 'end', values=(token.lexeme, token.type, token.line, token.column))
    else:
        for token in tokens:
            tree.insert('', 'end', values=(token.lexeme, token.type, token.line, token.column))

# Función de ejemplo que retorna una lista de tokens, algunos con errores léxicos
def get_tokens():
    return [
        Token("int", "Palabra Reservada", 1, 1),
        Token("main", "Identificador", 1, 5),
        Token("(", "Parentesis Abre", 1, 9),
        Token(")", "Parentesis Cierra", 1, 10),
        Token("{", "Llave Abre", 2, 1),
        Token("Error_Lexico", "Error Lexico: Simbolo no permitido", 2, 3),
        Token("return", "Palabra Reservada", 3, 2),
        Token("0", "Numero", 3, 9),
        Token("}", "Llave Cierra", 4, 1)
    ]

# Función principal para crear la interfaz gráfica
def create_gui():
    root = tk.Tk()
    root.title("Tokens y Errores Léxicos")
    
    # Crear el Treeview para mostrar los tokens o errores léxicos
    tree = ttk.Treeview(root, columns=("Lexema", "Tipo", "Línea", "Columna"), show='headings')
    tree.heading("Lexema", text="Lexema")
    tree.heading("Tipo", text="Tipo")
    tree.heading("Línea", text="Línea")
    tree.heading("Columna", text="Columna")
    
    # Empaquetar el Treeview en la ventana
    tree.pack(expand=True, fill='both')

    # Obtener los tokens (incluyendo errores léxicos) y mostrarlos en la tabla
    tokens = get_tokens()
    print_tokens_in_table(tokens, tree)
    
    root.mainloop()

# Ejecutar la interfaz gráfica
create_gui()
