from tkinter import *
from tkinter import messagebox, filedialog, ttk
import subprocess, os, webbrowser
import csv
from PIL import Image, ImageTk

raiz = Tk()

archivo_actual = None  # Variable para guardar la ruta del archivo actual
color_fondo = "gray20"
color_caja_texto = "gray64"
color_letra = "gray90"

# Funciones

def nuevo():
    if texto.get("1.0", END).strip():
        respuesta = messagebox.askyesnocancel("Nuevo archivo", "¿Desea guardar los cambios antes de continuar?")
        if respuesta:
            guardar_como()
        elif respuesta is None:
            return
    
    texto.delete("1.0", END)
    global archivo_actual
    archivo_actual = None

def abrir():
    archivo_path = filedialog.askopenfilename(
        title="Abrir archivo",
        filetypes=(("Archivos LFP", "*.LFP"), ("Todos los archivos", "*.*"))
    )
    if archivo_path:
        with open(archivo_path, "r") as archivo:
            contenido = archivo.read()
        texto.delete("1.0", END)
        texto.insert("1.0", contenido)
        global archivo_actual
        archivo_actual = archivo_path

def guardar():
    global archivo_actual
    if archivo_actual:
        with open(archivo_actual, "w") as archivo:
            contenido = texto.get("1.0", END)
            archivo.write(contenido)
        messagebox.showinfo("Guardar", "El archivo se ha guardado correctamente")
    else:
        guardar_como()

def guardar_como():
    archivo_path = filedialog.asksaveasfilename(
        title="Guardar archivo como",
        defaultextension=".txt",
        filetypes=(("Archivos de texto", "*.txt"), ("Todos los archivos", "*.*"))
    )
    if archivo_path:
        with open(archivo_path, "w") as archivo:
            contenido = texto.get("1.0", END)
            archivo.write(contenido)
        global archivo_actual
        archivo_actual = archivo_path
        messagebox.showinfo("Guardar como", "El archivo se ha guardado correctamente")

def abrir_html():
    """
    Abre un archivo HTML en el navegador web predeterminado.
    """
    # Define la ruta del archivo HTML que quieres abrir
    ruta_archivo = 'tokens.html'  # Cambia esto a la ruta de tu archivo
    # Asegúrate de que la ruta del archivo sea absoluta
    ruta_absoluta = os.path.abspath(ruta_archivo)
    
    # Abre el archivo en el navegador
    webbrowser.open(f'file://{ruta_absoluta}')

def cargar_csv():
    """Función para cargar los datos del archivo CSV."""
    with open('tokens.csv', newline='') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # Saltar el encabezado
        return list(reader)

def llenar_tabla(tree, data):
    """Función para llenar la tabla con los datos del archivo."""
    for row in data:
        tree.insert('', 'end', values=row)

def tabla_errores():
    # Crear la nueva ventana para mostrar los tokens
    ventana_tokens = Toplevel(raiz)
    ventana_tokens.title("Tokens")
    ventana_tokens.geometry("1000x400")
    ventana_tokens.config(bg="gray20")

    # Título de la ventana
    titulo = Label(ventana_tokens, text="Tokens Analizados", fg="gray90", bg="gray20", font=("UD Digi Kyokasho NK-R", 15))
    titulo.pack(pady=10)

    # Frame que contendrá la tabla y el scrollbar
    frame_tabla = Frame(ventana_tokens, bg="gray20")
    frame_tabla.pack(pady=20, fill=BOTH, expand=True)

    # Crear tabla de tokens con encabezados
    tabla = ttk.Treeview(frame_tabla, columns=('Lexema', 'Tipo', 'Linea', 'Columna'), show='headings')
    for col in ['Lexema', 'Tipo', 'Linea', 'Columna']:
        tabla.heading(col, text=col)
        tabla.column(col, anchor='center')  # Centramos las columnas

    # Scrollbar vertical para la tabla
    scrollbar = Scrollbar(frame_tabla, orient=VERTICAL, command=tabla.yview)
    tabla.configure(yscroll=scrollbar.set)
    scrollbar.pack(side=RIGHT, fill=Y)

    # Empaquetar la tabla dentro del frame
    tabla.pack(side=LEFT, fill=BOTH, expand=True)

    # Cargar datos del CSV (o cualquier fuente) y llenar la tabla
    data = cargar_csv()  # Aquí se llama a la función que carga los datos
    llenar_tabla(tabla, data)  # Aquí llenamos la tabla con los datos

    # Botón para cerrar la ventana
    boton_cerrar = Button(ventana_tokens, text="Cerrar", command=ventana_tokens.destroy, font=("UD Digi Kyokasho NK-R", 13), bg="gray64", fg="black")
    boton_cerrar.pack(pady=20)

def enviar_datos():
    dato = texto.get("1.0", END).strip()
    
    if not dato.endswith("\n"):
        dato += "\n"

    try:
        resultado = subprocess.run(
            ["./lexer_test.exe"],
            input=dato,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        
        resultados_text.delete("1.0", END)
        resultados_text.insert(END, resultado.stdout)

    except subprocess.CalledProcessError as e:
        messagebox.showerror("Error en el análisis", f"Ocurrió un error al ejecutar el análisis:\n{e.stderr}")

def acerca_de():
    messagebox.showinfo("Información", "> Nombre: Bryan Alejandro Anona Paredes\n> Carnet: 202307272\n> Curso: Laboratorio Lenguajes Formales y de Programación\n> Sección: B+\n> Año: 2024\n> Segundo Semestre 2024")

def mostrar_coordenadas(event):
    x, y = event.x, event.y
    etiqueta.config(text=f"Coordenadas: X:{x}, Y:{y}")

# Menú
barraMenu = Menu(raiz)
raiz.config(menu=barraMenu, bg=color_fondo)
raiz.title("Proyecto 2 [LFP]")
raiz.state("zoomed")

menu = Menu(barraMenu, tearoff=0)
menu.add_command(label="Nuevo", command=nuevo)
menu.add_command(label="Abrir", command=abrir)
menu.add_command(label="Guardar", command=guardar)
menu.add_command(label="Guardar como", command=guardar_como)
menu.add_command(label="Salir", command=raiz.quit)

barraMenu.add_cascade(label="Archivo", menu=menu)
barraMenu.add_cascade(label="Análisis", command=enviar_datos)
barraMenu.add_cascade(label="Tokens", command=abrir_html)
barraMenu.add_cascade(label="Tabla de Errores", command=tabla_errores)
barraMenu.add_cascade(label="Acerca de", command=acerca_de)

# Coordenadas
etiqueta = Label(raiz, text="Coordenadas:", font=("UD Digi Kyokasho NK-R", 13, "normal"), fg=color_letra, bg=color_fondo)
etiqueta.pack()
etiqueta.place(x=1100, y=15)
raiz.bind("<Motion>", mostrar_coordenadas)

# Títulos

tituloEntrada = Label(raiz, text="Archivo de entrada:", fg=color_letra, bg=color_fondo, font=("UD Digi Kyokasho NK-R", 15))
tituloEntrada.pack()
tituloEntrada.place(x=55, y=15)

tituloSalida = Label(raiz, text="Resultados:", fg=color_letra, bg=color_fondo, font=("UD Digi Kyokasho NK-R", 15))
tituloSalida.pack()
tituloSalida.place(x=580, y=15)

# Editor de texto
texto = Text(raiz, wrap="word", font=("UD Digi Kyokasho NK-R", 11), bg=color_caja_texto)
texto.pack()
texto.place(x=50, y=50, height=500, width=475)

# Botón Analizar
analisisBoton = Button(raiz,
                       text="Analizar",
                       font=("UD Digi Kyokasho NK-R", 22),
                       bg=color_caja_texto,
                       fg="black",
                       cursor="hand2",
                       command=enviar_datos,
                       borderwidth=0)
analisisBoton.pack()
analisisBoton.place(x=805, y=500, width=140, height=50)

# Área de resultados
resultados_text = Text(raiz, bg=color_caja_texto, font=("UD Digi Kyokasho NK-R", 11))
resultados_text.pack()
resultados_text.place(x=575, y=50, height=500, width=750)



raiz.mainloop()
