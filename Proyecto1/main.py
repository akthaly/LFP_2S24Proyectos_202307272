from tkinter import *
from tkinter import messagebox, filedialog
import subprocess
from PIL import Image, ImageTk  # Importar Pillow

raiz = Tk()

# Variable global para almacenar la ruta del archivo actual
archivo_actual = None

def abrir():
    archivo_path = filedialog.askopenfilename(
        title="Abrir archivo",
        filetypes=(("Archivos .org", ".org"), ("Todos los archivos", ".*"))
    )

    if archivo_path:
        with open(archivo_path, "r") as archivo:
            contenido = archivo.read()
        texto.delete(1.0, END)
        texto.insert(END, contenido)

        global archivo_actual
        archivo_actual = archivo_path  # Actualizar la ruta del archivo actual

def guardar():
    global archivo_actual
    if archivo_actual:
        with open(archivo_actual, "w") as archivo:
            contenido = texto.get(1.0, END)
            archivo.write(contenido)
        messagebox.showinfo("Guardar", "Archivo guardado exitosamente.")
    else:
        guardarComo()

def guardarComo():
    archivo_path = filedialog.asksaveasfilename(
        title="Guardar archivo como",
        defaultextension=".org",
        filetypes=(("Archivos .org", ".org"), ("Todos los archivos", ".*"))
    )

    if archivo_path:
        with open(archivo_path, "w") as archivo:
            contenido = texto.get(1.0, END)
            archivo.write(contenido)

        global archivo_actual
        archivo_actual = archivo_path
        messagebox.showinfo("Guardar como", "Archivo guardado exitosamente")

def enviar_datos():
    dato = texto.get(1.0, END)

    resultado = subprocess.run(
        ["./analizador.exe"],
        input=dato,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,  # Capturar errores estándar
        text=True
    )

    # Procesar la salida
    salida = resultado.stdout.strip().split('\n')
    errores = resultado.stderr.strip()  # Leer errores si los hay

    # Limpiar resultados previos
    resultados_text.delete(1.0, END)
    label_pais.config(text="País: ")
    label_poblacion.config(text="Población: ")
    label_bandera.config(image='')  # Limpiar imagen de bandera

    if errores:
        messagebox.showerror("Errores léxicos", "Se encontraron errores léxicos:\n" + errores)
        return  # No mostrar nada más si hay errores

    # Si no hay errores, procesar la salida
    for linea in salida:
        resultados_text.insert(END, linea + '\n')

    # Extraer país, población y bandera
    pais = ""
    poblacion = ""
    bandera_ruta = ""

    for linea in salida:
        if "Pais:" in linea:
            pais = linea.split("Pais:")[1].strip().strip('"')
            label_pais.config(text=f"País: {pais}")
        elif "Poblacion:" in linea:
            poblacion = linea.split("Poblacion:")[1].strip()
            label_poblacion.config(text=f"Población: {poblacion} personas")
        elif "Bandera" in linea:
            bandera_ruta = linea.split("Bandera:")[1].strip().strip('"')
            mostrar_bandera(bandera_ruta)


def mostrar_bandera(ruta):
    try:
        # Usar Pillow para abrir y redimensionar la imagen de la bandera
        img = Image.open(ruta)
        img = img.resize((170, 110), Image.LANCZOS)  
        bandera_img = ImageTk.PhotoImage(img)

        # Actualizar el label_bandera con la imagen
        label_bandera.config(image=bandera_img)
        label_bandera.image = bandera_img  # Mantener una referencia a la imagen para evitar que se elimine
    except Exception as e:
        print(f"Error al cargar la imagen: {e}")


def acercaDe():
    messagebox.showinfo("Información", "> Nombre: Bryan Alejandro Anona Paredes\n> Carnet: 202307272\n> Curso: Laboratorio Lenguajes Formales y de Programación\n> Sección: B+\n> Año: 2024\n> Segundo Semestre 2024")


# Menú
barraMenu = Menu(raiz)
raiz.config(menu=barraMenu, width=1000, height=575, bg="light slate blue")
raiz.title("Proyecto 1 [LFP]")

menu = Menu(barraMenu, tearoff=0)
menu.add_command(label="Abrir", command=abrir)
menu.add_command(label="Guardar", command=guardar)
menu.add_command(label="Guardar como", command=guardarComo)

barraMenu.add_cascade(label="Archivo", menu=menu)
barraMenu.add_cascade(label="Acerca de", command=acercaDe)
barraMenu.add_cascade(label="Salir", command=raiz.quit)

# Títulos

tituloEntrada = Label(raiz, text="Archivo de entrada:", bg="light slate blue", font=("UD Digi Kyokasho NK-R", 15))
tituloEntrada.pack()
tituloEntrada.place(x=55, y=15)

tituloSalida = Label(raiz, text="Resultados:", bg="light slate blue", font=("UD Digi Kyokasho NK-R", 15))
tituloSalida.pack()
tituloSalida.place(x=580, y=15)

# Editor de texto
texto = Text(raiz, wrap="word", font=("UD Digi Kyokasho NK-R", 11), bg="light cyan")
texto.pack()
texto.place(x=50, y=50, height=500, width=475)

# Botón Analizar
analisisBoton = Button(raiz,
                       text="Analizar",
                       font=("UD Digi Kyokasho NK-R", 22),
                       bg="dark slate blue",
                       fg="light grey",
                       cursor="hand2",
                       command=enviar_datos,
                       borderwidth=0)
analisisBoton.pack()
analisisBoton.place(x=805, y=500, width=140, height=50)

# Labels
label_pais = Label(raiz, text="Pais: ", font=("UD Digi Kyokasho NK-R", 13, "normal"), bg="light slate blue")
label_pais.pack()
label_pais.place(x=575, y=375)

label_poblacion = Label(raiz, text="Población: ", font=("UD Digi Kyokasho NK-R", 13), bg="light slate blue")
label_poblacion.pack()
label_poblacion.place(x=575, y=400)

label_bandera = Label(raiz, text='', bg="light slate blue", font=("UD Digi Kyokasho NK-R", 13))
label_bandera.pack()
label_bandera.place(x=575, y=440)

# Área de resultados
resultados_text = Text(raiz, bg="light cyan", font=("UD Digi Kyokasho NK-R", 11))
resultados_text.pack()
resultados_text.place(x=575, y=50, height=300, width=350)

raiz.mainloop()
