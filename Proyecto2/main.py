from tkinter import *
from tkinter import messagebox, filedialog, ttk
import subprocess
from PIL import Image, ImageTk

raiz = Tk()

archivo_actual = None  # Variable para guardar la ruta del archivo actual
color_fondo = "gray20"
color_caja_texto = "gray64"
color_letra = "gray90"

# Funciones

def nuevo():
    # Verifica si hay texto modificado antes de limpiar
    if texto.get("1.0", END).strip():  # Si hay algo en el área de texto
        respuesta = messagebox.askyesnocancel("Nuevo archivo", "¿Desea guardar los cambios antes de continuar?")
        if respuesta:  # Si la respuesta es 'Sí', guarda
            guardar_como()
        elif respuesta is None:  # Si la respuesta es 'Cancelar', no hacer nada
            return
    
    # Limpiar el área de texto y resetear la variable del archivo actual
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
        archivo_actual = archivo_path  # Guardamos la ruta del archivo actual


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

def tokens():
    # Crear una nueva ventana
    ventana_tokens = Toplevel(raiz)
    ventana_tokens.title("Tokens")
    ventana_tokens.geometry("1000x400")
    ventana_tokens.config(bg="gray20")

    # Etiqueta de título
    titulo = Label(ventana_tokens, text="Tokens Analizados", fg="gray90", bg="gray20", font=("UD Digi Kyokasho NK-R", 15))
    titulo.pack(pady=10)

    # Crear un frame para contener la tabla
    frame_tabla = Frame(ventana_tokens, bg="gray20")
    frame_tabla.pack(pady=20)

    # Crear la tabla (Treeview)
    tabla = ttk.Treeview(frame_tabla, columns=("No.", "Tipo", "Línea", "Columna", "Token", "Descripción"), show="headings")
    tabla.heading("No.", text="No.")
    tabla.heading("Tipo", text="Tipo")
    tabla.heading("Línea", text="Línea")
    tabla.heading("Columna", text="Columna")
    tabla.heading("Token", text="Token")
    tabla.heading("Descripción", text="Descripción")

    # Ajustar el ancho de las columnas
    tabla.column("No.", anchor=CENTER, width=75)
    tabla.column("Tipo", anchor=CENTER, width=150)
    tabla.column("Línea", anchor=CENTER, width=75)
    tabla.column("Columna", anchor=CENTER, width=75)
    tabla.column("Token", anchor=CENTER, width=150)
    tabla.column("Descripción", anchor=CENTER, width=200)

    # Scrollbar para la tabla
    scrollbar = Scrollbar(frame_tabla, orient=VERTICAL, command=tabla.yview)
    tabla.configure(yscroll=scrollbar.set)
    scrollbar.pack(side=RIGHT, fill=Y)
    tabla.pack(side=LEFT, fill=BOTH, expand=True)

    # Aquí puedes agregar los datos de los tokens (esto es solo un ejemplo)
    tokens_ejemplo = [("if", "Palabra Reservada", 2),
                      ("(", "Símbolo", 2),
                      ("x", "Identificador", 2),
                      ("==", "Operador", 2),
                      ("10", "Número", 2),
                      (")", "Símbolo", 2)]

    for token in tokens_ejemplo:
        tabla.insert("", "end", values=token)

    # Botón para cerrar la ventana
    boton_cerrar = Button(ventana_tokens, text="Cerrar", command=ventana_tokens.destroy, font=("UD Digi Kyokasho NK-R", 13), bg="gray64", fg="black")
    boton_cerrar.pack(pady=20)


def enviar_datos():
    # Obtener el contenido del área de texto en Tkinter
    dato = texto.get("1.0", END).strip()  # Eliminar espacios y saltos de línea adicionales al final
    
    # Asegurarnos de que el contenido tiene saltos de línea correctos
    if not dato.endswith("\n"):
        dato += "\n"  # Asegurar que la última línea tiene un salto de línea

    try:
        # Ejecutar lexer_test.exe y enviarle el contenido del área de texto como entrada estándar
        resultado = subprocess.run(
            ["./lexer_test.exe"],  # Ejecutable de Fortran
            input=dato,            # Enviar el contenido como entrada estándar (stdin)
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        
        # Mostrar el resultado en el área de texto `resultados_text`
        resultados_text.delete("1.0", END)  # Limpiar el área de resultados antes de mostrar los nuevos datos
        resultados_text.insert(END, resultado.stdout)  # Insertar la salida del programa Fortran

    except subprocess.CalledProcessError as e:
        # Manejar errores en la ejecución del programa Fortran
        messagebox.showerror("Error en el análisis", f"Ocurrió un error al ejecutar el análisis:\n{e.stderr}")



def acerca_de():
    messagebox.showinfo("Información", "> Nombre: Bryan Alejandro Anona Paredes\n> Carnet: 202307272\n> Curso: Laboratorio Lenguajes Formales y de Programación\n> Sección: B+\n> Año: 2024\n> Segundo Semestre 2024")

# Función para mostrar las coordenadas del mouse
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
barraMenu.add_cascade(label="Tokens", command=tokens)
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

# Labels

# Área de resultados
resultados_text = Text(raiz, bg=color_caja_texto, font=("UD Digi Kyokasho NK-R", 11))
resultados_text.pack()
resultados_text.place(x=575, y=50, height=500, width=750)



raiz.mainloop()
