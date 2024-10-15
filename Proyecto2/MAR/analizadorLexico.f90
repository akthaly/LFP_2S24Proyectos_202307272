module analizador
    implicit none
    integer, parameter :: max_length = 50000
    integer :: max_tokens
    type :: Token
        character(len=150) :: lexema
        character(len=25) :: tipo
        integer :: fila
        integer :: columna
    end type Token
contains

    ! Subrutina para analizar el contenido del archivo
    subroutine analyze(file_content, resultado)
        character(len=*), intent(inout) :: file_content
        character(len=*), intent(out) :: resultado
        character(len=1) :: buffer(max_length)
        integer :: i, j, length, state, token_index, fila, columna_inicial, columna_actual, indice_error
        type(Token), allocatable :: tokens(:)
        type(Token), allocatable :: errores(:)
        character(len=1000) :: current_lexema
        character(len=1) :: caracter
        character(len=50000) :: resultados_locales 
        character(len=50000) :: resultados_errores


        max_tokens = 99999
        allocate(tokens(max_tokens))
        allocate(errores(max_tokens))

    
        length = len_trim(file_content)
        buffer = ' '
        current_lexema = ''
        token_index = 1
        indice_error = 1
        state = 0
        i = 0
        resultados_locales = '' ! Inicializar variable local
        resultados_errores = ''

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
                    if (caracter >= 'a' .and. caracter <= 'z' .or. caracter >= 'A' .and. caracter <= 'Z') then  ! Letra [a-z]
                        state = 1
                        current_lexema = caracter
                        columna_inicial = columna_actual
                    else if (caracter == '"') then
                        state = 2
                        current_lexema = caracter
                        columna_inicial = columna_actual
                    else if (caracter >= '0' .and. caracter <= '9') then  ! Número [0-9]
                        state = 5
                        current_lexema = caracter
                        columna_inicial = columna_actual
                    else if (caracter == char(59)) then 
                        state = 6  
                        current_lexema = caracter
                        columna_inicial = columna_actual
                    else if (caracter == '/') then 
                        state = 7  
                        current_lexema = caracter
                        columna_inicial = columna_actual
                    else if (caracter == char(32) .or. caracter == char(9) .or. caracter == char(10)) then
                        ! Ignorar espacios, tabulaciones y saltos de linea
                        cycle
                    else if (caracter == '#' .and. i == length) then
                        print *, "Hemos concluido el analisis lexico satisfactoriamente"
                    else
                     ! Registrar el error léxico
                        errores(indice_error)%lexema = caracter
                        errores(indice_error)%tipo = "Error Léxico Desconocido"
                        errores(indice_error)%fila = fila
                        errores(indice_error)%columna = columna_actual - 1
                        indice_error = indice_error + 1
                        resultados_errores = trim(resultados_errores) // &
                         "Error lexico: Caracter inesperado: " // caracter // new_line('A')
                    end if

                case(1)
                    if (caracter >= 'a' .and. caracter <= 'z' .or. caracter >= 'A' .and. caracter <= 'Z') then
                        current_lexema = trim(current_lexema) // caracter
                    else if (caracter == ':' .or. caracter == ';' .or. caracter == ' ') then
                        state = 0
                        ! Verificar si el lexema es una palabra reservada y asignar un tipo específico
                        if (current_lexema == 'Etiqueta') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaEtiqueta"
                        else if (current_lexema == 'Boton') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaBoton"
                        else if (current_lexema == 'Check') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaCheck"
                        else if (current_lexema == 'RadioBoton') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaRadioBoton"
                        else if (current_lexema == 'Texto') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaTexto"
                        else if (current_lexema == 'AreaTexto') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaAreaTexto"
                        else if (current_lexema == 'Clave') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaClave"
                        else if (current_lexema == 'Contenedor') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "ReservadaContenedor"
                        else
                            ! Si el lexema no coincide con ninguna palabra reservada, clasificarlo como un identificador
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "Identificador"
                        end if
                
                        ! Incrementar el índice del token en cualquier caso
                        tokens(token_index)%fila = fila
                        tokens(token_index)%columna = columna_inicial ! Columna donde comenzó el token
                        token_index = token_index + 1
                
                        current_lexema = ''
                        i = i - 1
                    else
                        ! Manejar errores o caracteres inesperados
                        resultados_locales = trim(resultados_locales) // &
                        "Error lexico: Caracter inesperado: " // caracter // new_line('A')
                    end if

                case(2)  ! Estado para el inicio de una cadena
                    if (caracter /= '"') then
                        state = 3
                        current_lexema = trim(current_lexema) // caracter
                        tokens(token_index)%columna = columna_inicial - 2
                    else
                        ! Si encontramos otra comilla en el estado 2, esto significa un error
                        resultados_locales = trim(resultados_locales) // &
                            "Error léxico: Comillas de cierre inesperadas" // new_line('A')
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
                        tokens(token_index)%fila = fila
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1

                case(5)  ! Estado para números
                    if (caracter >= '0' .and. caracter <= '9') then
                        current_lexema = trim(current_lexema) // caracter
                    else if (caracter == '%') then
                        ! Crear token para el número antes del símbolo '%'
                        state = 7  ! Cambiar al estado de porcentaje
                        if (current_lexema /= '') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "NumeroPor"
                            tokens(token_index)%fila = fila
                            tokens(token_index)%columna = columna_inicial - 2
                            token_index = token_index + 1
                            current_lexema = ''
                        end if
                        current_lexema = caracter  ! Iniciar el lexema del porcentaje
                    else
                        state = 0
                        if (current_lexema /= '') then
                            tokens(token_index)%lexema = trim(current_lexema)
                            tokens(token_index)%tipo = "Numero"
                            tokens(token_index)%fila = fila
                            tokens(token_index)%columna = columna_inicial - 2
                            token_index = token_index + 1
                            current_lexema = ''
                        end if
                        i = i - 1
                    end if
               
                case(6)  ! Estado para manejar el ';'
                    state = 0
                    if (current_lexema /= '') then
                        tokens(token_index)%lexema = trim(current_lexema)
                        tokens(token_index)%tipo = "Delimitador"
                        tokens(token_index)%fila = fila
                        tokens(token_index)%columna = columna_inicial - 3
                        token_index = token_index + 1
                        current_lexema = ''
                    end if
                    i = i - 1
                case(7)
                    if ( caracter == '/' ) then
                        state = 8
                        current_lexema = trim(current_lexema) // caracter
                    else
                        resultados_locales = trim(resultados_locales) // &
                        "Error: comentario de línea mal formado. Se esperaba '//'" // new_line('A')
                    end if
                case(8)
                    if (caracter == char(10)) then
                        state = 9
                    else 
                        current_lexema = trim(current_lexema) // caracter
                        state = 8
                    end if
                case(9)
                    tokens(token_index)%lexema = trim(current_lexema)
                    tokens(token_index)%tipo = "ComenatarioLinea"
                    token_index = token_index + 1
                    current_lexema = ''
                    state = 0
                    i = i - 1
            end select

            if (caracter /= char(10)) then
                columna_actual = columna_actual + 1
            end if
            if (caracter /= char(9)) then
                columna_actual = columna_actual + 1
            end if
        end do

        if (token_index > 1) then
            resultados_locales = trim(resultados_locales) // "Analisis completo. Tokens encontrados:" // new_line('A')
            do j = 1, token_index - 1
                resultados_locales = trim(resultados_locales) // &
                    "Lexema: " // trim(tokens(j)%lexema) // " Tipo: " // trim(tokens(j)%tipo) // new_line('A')
            end do
        else
            resultados_locales = trim(resultados_locales) // "No se encontraron tokens válidos." // new_line('A')
        end if


        resultados_locales = trim(resultados_locales)
        ! Asignar el resultado acumulado
        resultado = trim(resultados_locales)
    end subroutine analyze


 end module analizador

 program procesar_datos
    use analizador
    implicit none
    character(len=95000) :: entrada
    character(len=1000) :: linea
    character(len=95000) :: salida_analyze
    integer :: ios

    ! Inicializar la variable de entrada
    entrada = ''

    ! Leer el valor de entrada obtenida desde tkinter y concatenar cada linea al valor de entrada
    do
        read(*, '(A)', iostat = ios) linea
        if (ios /= 0) exit   ! Se alcanzo el fin del archivo
        entrada = trim(entrada) // trim(linea) // char(10) ! Concatenar la línea leida al valor de entrada y agregar un salto de línea
    end do

    ! Llamar a la subrutina analyze para procesar el texto
    call analyze(entrada, salida_analyze)

    ! Imprimir el resultado para que Python pueda capturarlo
    print *, trim(salida_analyze)

end program procesar_datos