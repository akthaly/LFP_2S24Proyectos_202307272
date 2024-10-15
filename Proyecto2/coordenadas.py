import tkinter as tk

# Función para mostrar las coordenadas del mouse
def mostrar_coordenadas(event):
    x, y = event.x, event.y
    etiqueta.config(text=f"Coordenadas: {x}, {y}")

# Crear la ventana principal
ventana = tk.Tk()
ventana.title("Coordenadas del mouse")

# Crear una etiqueta para mostrar las coordenadas
etiqueta = tk.Label(ventana, text="Mover el mouse sobre la ventana", font=("Arial", 16))
etiqueta.pack(padx=20, pady=20)

# Asociar el movimiento del mouse a la función 'mostrar_coordenadas'
ventana.bind('<Motion>', mostrar_coordenadas)

# Ejecutar la ventana
ventana.mainloop()
