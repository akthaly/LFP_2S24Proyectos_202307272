module analizador
    implicit none
    integer, parameter :: max_length = 90000
    integer, parameter :: max_tokens = 90000
    type :: Token
        character(len=100) :: lexema
        character(len=100) :: tipo
    end type Token

contains

    ! Subrutina para analizar el contenido del archivo
subroutine analyze(file_content, resultado)
        character(len=*), intent(inout) :: file_content
        character(len=*), intent(out) :: resultado
        integer :: i, j, length, state, token_index, error_index
        type(Token), allocatable :: tokens(:)
        character(len=100) :: current_lexema
        character(len=1) :: caracter
        character(len=50000) :: resultados_locales  ! Variable para acumular resultados locales
        logical :: error_detected  ! Variable para indicar si se encontró algún error
        character(len=100), allocatable :: errores(:)  ! Almacena los errores léxicos encontrados
        integer :: menor_numero, numero_actual, poblacion_actual  ! Variables para almacenar el menor número y la población actual
        character(len=100) :: pais_actual  ! Variable para almacenar el último país encontrado
        character(len=100) :: nombre_pais_menor_saturacion  ! Almacenar el nombre del país con la menor saturación
        logical :: buscando_saturacion, buscando_poblacion  ! Flags para saber si estamos buscando la saturación y la población
        integer :: poblacion_menor_saturacion  ! Almacenar la población del país con menor saturación
        logical :: saturacion_encontrada  ! Indica si se encontró la saturación
        character(len=100) :: bandera_encontrada  ! Almacena el lexema de la bandera encontrada
    
        allocate(tokens(max_tokens))
        allocate(errores(max_tokens))
        
        ! Inicialización
        length = len_trim(file_content)
        current_lexema = ''
        token_index = 1
        error_index = 1
        state = 0
        i = 0
        resultados_locales = ''
        error_detected = .false.
        menor_numero = 101  ! Inicializa con un valor mayor a 100
        pais_actual = ''
        nombre_pais_menor_saturacion = ''
        buscando_saturacion = .false.
        buscando_poblacion = .false.  ! Flag para buscar la población
        poblacion_actual = -1
        poblacion_menor_saturacion = -1
        saturacion_encontrada = .false.  ! Inicializar como falso
        bandera_encontrada = ''  ! Inicializar como vacío
    

    ! Agregar carácter de fin de cadena
    if (length < max_length) then
        file_content(length + 1: length + 1) = '#'
        length = length + 1
    end if

    ! Procesar cada carácter con un ciclo for
    do while (i <= length)
        i = i + 1
        caracter = file_content(i:i)
            
            select case(state)
                case(0)  ! Estado inicial
                    if (caracter >= 'a' .and. caracter <= 'z') then  ! Letra [a-z]
                        state = 1
                        current_lexema = caracter
                    else if (caracter == '"') then
                        state = 2
                        current_lexema = caracter
                    else if (caracter >= '0' .and. caracter <= '9') then  ! Número [0-9]
                        state = 5
                        current_lexema = caracter
                    else if (caracter == '{' .or. caracter == '}') then
                        state = 6
                        current_lexema = caracter
                    else if (caracter == '%') then
                        state = 7
                        current_lexema = caracter
                    else if (caracter == char(59)) then
                        state = 8
                        current_lexema = caracter
                    else if (caracter == ':') then
                        state = 9
                        current_lexema = caracter
                    else if (caracter == ' ' .or. caracter == char(9) .or. caracter == char(10)) then
                        cycle ! Ignorar espacios, tabulaciones y saltos de línea
                    
                    else if ( caracter == char(35) .and. i == length ) then
                        
                    else ! Caracteres no válidos
                        resultados_locales = trim(resultados_locales) // &
                        "Error léxico: Carácter inesperado: " // caracter // new_line('A')
                        error_detected = .true.  ! Marcar que se encontró un error
                        errores(error_index) = caracter
                        error_index = error_index + 1
                    end if

                case(1)  ! Estado para identificadores
                    if (caracter >= 'a' .and. caracter <= 'z') then
                        current_lexema = trim(current_lexema) // caracter
                    else
                        state = 0
                        
                        if (current_lexema == 'grafica' .or. & 
                        current_lexema == 'nombre' .or. current_lexema == 'continente' .or. & 
                        current_lexema == 'pais' .or. current_lexema == 'poblacion' .or. & 
                        current_lexema == 'saturacion' .or. current_lexema == 'bandera') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        tokens(token_index)%tipo = "Reservada"
                        token_index = token_index + 2  ! Asegurarse de incrementar el token_index

                            if (current_lexema == 'pais') then
                                pais_actual = ''  ! Reiniciar el país actual al encontrar "pais"
                                buscando_saturacion = .true.  ! Activar búsqueda de saturación
                            end if
                            if (current_lexema == 'poblacion') then
                                poblacion_actual = -1  ! Reiniciar la población actual
                                buscando_poblacion = .true.  ! Activar búsqueda de población
                            end if
                        else
                            ! No es una palabra reservada, por lo tanto generar error correctamente
                            resultados_locales = trim(resultados_locales) // &
                            "Error léxico: '" // trim(current_lexema) // "' no es una palabra reservada." // new_line('A')

                            error_detected = .true.
                            errores(error_index) = trim(current_lexema)
                            error_index = error_index + 1

                            ! Incluir token de error en la lista para un análisis completo (opcional)
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "Error"

                            token_index = token_index + 1  ! Asegurarse de incrementar el token_index
                        end if

                        ! Regresar al carácter anterior para seguir evaluando
                        i = i - 1
                    end if

                case(2)  ! Estado para el inicio de una cadena
                    if (caracter /= '"') then
                        state = 3
                        current_lexema = trim(current_lexema) // caracter
                    else
                        resultados_locales = trim(resultados_locales) // &
                        "Error lexico: Se esperaba un caracter de cadena" // new_line('A')
                        error_detected = .true.  ! Marcar que se encontró un error
                        errores(error_index) = caracter
                        error_index = error_index + 1
                    end if

                case(3)  ! Estado para el contenido de la cadena
                    if (caracter /= '"') then
                        current_lexema = trim(current_lexema) // caracter
                    else
                        state = 4
                        current_lexema = trim(current_lexema) // caracter
                    end if

                case(4)  ! Estado final de una cadena
                    state = 0
                    if (current_lexema /= '') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        tokens(token_index)%tipo = "Cadena"
                        if (buscando_saturacion) then
                            pais_actual = trim(current_lexema)  ! Asignar el nombre del país actual
                        end if
                        
                        ! Buscar bandera solo si se ha encontrado saturación
                        if (saturacion_encontrada) then
                            bandera_encontrada = trim(current_lexema)
                            saturacion_encontrada = .false.  ! Para evitar encontrar más de uno
                        end if
                
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1
                
                case(5)  ! Estado para números
                    if (caracter >= '0' .and. caracter <= '9') then
                        current_lexema = trim(current_lexema) // caracter
                    else
                        state = 0
                        if (current_lexema /= '') then
                            read(current_lexema, *) numero_actual
                            if (buscando_poblacion) then
                                poblacion_actual = numero_actual
                                buscando_poblacion = .false.
                            else if (buscando_saturacion .and. numero_actual >= 0 .and. numero_actual <= 100) then
                                if (numero_actual < menor_numero) then
                                    menor_numero = numero_actual
                                    nombre_pais_menor_saturacion = pais_actual
                                    poblacion_menor_saturacion = poblacion_actual  ! Asociar la población con el país
                                    saturacion_encontrada = .true.  ! Marcar que se encontró la saturación
                                end if
                            end if
                
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "Numero"
                            token_index = token_index + 1
                            current_lexema = ''
                        end if
                        i = i - 1
                    end if


                case(6) ! Llaves
                    state = 0
                    if (current_lexema /= '') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        if (current_lexema == '{' .or. current_lexema == '}') then
                            tokens(token_index)%tipo = "Llaves"
                        else
                            tokens(token_index)%tipo = "Desconocido"
                        end if
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1
                
                case(7) ! Porcentaje
                    state = 0
                    if (current_lexema /= '') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        if (current_lexema == '%') then
                            tokens(token_index)%tipo = "Porcentaje"
                        else
                            tokens(token_index)%tipo = "Desconocido"
                        end if
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1
                
                case(8)
                    state = 0
                    if (current_lexema /= '') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        tokens(token_index)%tipo = "Punto y Coma"
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1

                case(9)
                    state = 0
                    if (current_lexema /= '') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        tokens(token_index)%tipo = "Dos puntos"
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1
            end select

            ! Verificar si se ha llegado al final del archivo
            if (caracter == '#' .and. length == i) then
                print *, "Análisis completo. Tokens encontrados:"
                do j = 1, token_index - 1
                    resultados_locales = trim(resultados_locales) // &
                    "Lexema: " // trim(tokens(j)%lexema) // " Tipo: " // trim(tokens(j)%tipo) // new_line('A')
                end do
                exit
            end if
        end do
    
        ! Agregar el resultado del país con la menor saturación
        if (menor_numero < 101) then
            resultados_locales = trim(resultados_locales) // &
                "Menor numero entre 0 y 100: " // trim(itoa(menor_numero)) // new_line('A') // &
                "Pais: " // trim(nombre_pais_menor_saturacion) // new_line('A') // &
                "Poblacion: " // trim(itoa(poblacion_menor_saturacion)) // new_line('A') // &
                "Bandera: " // trim(bandera_encontrada) // new_line('A')
        end if

        resultado = trim(resultados_locales)


        if (.not. error_detected) then
            call reporteTokensHTML(tokens(1:token_index - 1), token_index - 1)
        else
            print *, "Se encontraron errores léxicos. Generando reporte de errores."
            call reporteErroresHTML(errores(1:error_index - 1), error_index - 1)
        end if

end subroutine analyze

    ! Función para convertir entero a cadena
    character(len=10) function itoa(num)
    integer, intent(in) :: num
    write(itoa, '(I0)') num
    end function itoa

    subroutine reporteErroresHTML(errores, numeroErrores)
        character(len=100), intent(in) :: errores(:)
        integer, intent(in) :: numeroErrores
        integer :: i
        character(len=9999) :: tabla_html
        character(len=10) :: num_str  ! Para almacenar el número como cadena
    
        ! Cabecera del HTML con estilo CSS
        tabla_html = "<html>" // new_line('A') // &
                     "<head><title>Reporte de Errores Léxicos</title>" // new_line('A') // &
                     "<style>" // &
                     "body {font-family: Arial, sans-serif; background-color: #f4f4f9;}" // &
                     "h2 {color: #333; text-align: center;}" // &
                     "table {width: 80%; margin: auto; border-collapse: collapse;}" // &
                     "th, td {border: 1px solid #ddd; padding: 8px; text-align: left;}" // &
                     "th {background-color: #4CAF50; color: white;}" // &
                     "tr:nth-child(even) {background-color: #f2f2f2;}" // &
                     "tr:hover {background-color: #ddd;}" // &
                     "</style>" // &
                     "</head>" // new_line('A') // &
                     "<body>" // new_line('A') // &
                     "<h2>Errores Léxicos Encontrados</h2>" // new_line('A') // &
                     "<table>" // new_line('A') // &
                     "<tr><th>No.</th><th>Error</th><th>Descripción</th></tr>" // new_line('A')
    
        ! Agregar las filas de la tabla
        do i = 1, numeroErrores
            write(num_str, '(I10)') i  ! Formato I10 para el entero
    
            tabla_html = trim(tabla_html) // &
                         "<tr><td>" // trim(adjustl(num_str)) // "</td>" // &
                         "<td>" // trim(errores(i)) // "</td>" // &
                         "<td>Error léxico desconocido</td></tr>" // new_line('A')
        end do
    
        ! Cierre de la tabla y el HTML
        tabla_html = trim(tabla_html) // &
                     "</table>" // new_line('A') // &
                     "</body>" // new_line('A') // &
                     "</html>"
    
        ! Guardar la tabla en un archivo HTML
        open(unit=13, file="ErroresLexicos.html", status='replace')
        write(13, '(A)') tabla_html
        close(13)
    
    end subroutine reporteErroresHTML
    
    
    subroutine reporteTokensHTML(tokens, contadorTokens)
        type(Token), intent(in) :: tokens(:)
        integer, intent(in) :: contadorTokens
        integer :: i
        character(len=9999) :: tabla_html
        character(len=10) :: num_str  ! Para almacenar el número como cadena
    
        ! Cabecera del HTML con estilo CSS
        tabla_html = "<html>" // new_line('A') // &
                     "<head><title>Tokens Encontrados</title>" // new_line('A') // &
                     "<style>" // &
                     "body {font-family: Arial, sans-serif; background-color: #f4f4f9;}" // &
                     "h2 {color: #333; text-align: center;}" // &
                     "table {width: 80%; margin: auto; border-collapse: collapse;}" // &
                     "th, td {border: 1px solid #ddd; padding: 8px; text-align: left;}" // &
                     "th {background-color: #4CAF50; color: white;}" // &
                     "tr:nth-child(even) {background-color: #f2f2f2;}" // &
                     "tr:hover {background-color: #ddd;}" // &
                     "</style>" // &
                     "</head>" // new_line('A') // &
                     "<body>" // new_line('A') // &
                     "<h2>Tabla de Tokens y Lexemas</h2>" // new_line('A') // &
                     "<table>" // new_line('A') // &
                     "<tr><th>No.</th><th>Lexema</th><th>Token</th></tr>" // new_line('A')
    
        ! Agregar las filas de la tabla
        do i = 1, contadorTokens
            write(num_str, '(I10)') i  ! Formato I10 para el entero
    
            tabla_html = trim(tabla_html) // &
                         "<tr><td>" // trim(adjustl(num_str)) // "</td>" // &
                         "<td>" // trim(tokens(i)%lexema) // "</td>" // &
                         "<td>" // trim(tokens(i)%tipo) // "</td></tr>" // new_line('A')
        end do
    
        ! Cierre de la tabla y el HTML
        tabla_html = trim(tabla_html) // &
                     "</table>" // new_line('A') // &
                     "</body>" // new_line('A') // &
                     "</html>"
    
        ! Guardar la tabla en un archivo HTML
        open(unit=12, file="Tokens.html", status='replace')
        write(12, '(A)') tabla_html
        close(12)
    
    end subroutine reporteTokensHTML
    
end module analizador

program procesar_datos
    use analizador
    implicit none
    character(len=9999) :: entrada
    character(len=1000) :: linea
    character(len=90000) :: salida_analyze
    integer :: ios

    ! Inicializar la variable de entrada
    entrada = ''

    do
        read(*, '(A)', iostat = ios) linea
        if (ios /= 0) exit 
        entrada = trim(entrada) // trim(linea) // char(10) ! Agregar salto de línea
    end do

    call analyze(entrada, salida_analyze)

    ! imprimir resultado para python
    print*, trim(salida_analyze)

end program procesar_datos