import tkinter as tk
from tkinter import ttk
import csv

def load_csv_data():
    """Función para cargar los datos del archivo CSV."""
    with open('tokens.csv', newline='') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # Saltar el encabezado
        return list(reader)

def populate_table(tree, data):
    """Función para llenar la tabla con los datos del archivo."""
    for row in data:
        tree.insert('', 'end', values=row)

# Crear ventana principal
root = tk.Tk()
root.title("Tokens")

# Crear Treeview (tabla)
tree = ttk.Treeview(root, columns=('Lexeme', 'Type', 'Line', 'Column'), show='headings')
tree.heading('Lexeme', text='Lexeme')
tree.heading('Type', text='Type')
tree.heading('Line', text='Line')
tree.heading('Column', text='Column')
tree.pack(fill='both', expand=True)

# Cargar datos del CSV y llenarlos en la tabla
data = load_csv_data()
populate_table(tree, data)

# Iniciar el bucle principal
root.mainloop()


# Agregar nueva tabla en la ventana principal
def crear_tabla_principal():
    # Crear Treeview (tabla)
    tree = ttk.Treeview(raiz, columns=('Lexeme', 'Type', 'Line', 'Column'), show='headings')
    tree.heading('Lexeme', text='Lexeme')
    tree.heading('Type', text='Type')
    tree.heading('Line', text='Line')
    tree.heading('Column', text='Column')
    tree.pack(fill='both', expand=True)

    # Cargar datos del CSV y llenarlos en la tabla
    data = load_csv_data()
    populate_table(tree, data)