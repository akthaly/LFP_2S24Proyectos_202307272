module lexer_module
    implicit none

    ! Definir la estructura de un Nodo para almacenar cada token
    type :: Token
        character(len=:), allocatable :: lexeme  ! Lexema de longitud dinámica
        character(len=:), allocatable :: type    ! Tipo de token (Comentario, Identificador, etc.)
        integer :: line, column                  ! Línea y columna del token
        type(Token), pointer :: next             ! Apuntador al siguiente token
    end type Token

    ! Puntero a la lista de tokens
    type(Token), pointer :: token_list => null()
    type(Token), pointer :: last_token => null()

    ! Variable para multiples lineas (Comentario)
    logical :: in_multi_comment = .false.
    character(len=:), allocatable :: multi_comment_content  ! Contenido del comentario de varias lineas
    integer :: multi_comment_start_line  ! Línea donde comenzó el comentario multilínea

contains

    ! Subrutina para leer el archivo de entrada
    subroutine read_file(filename)
        character(len=*), intent(in) :: filename
        character(len=1000) :: line
        integer :: unit, ios, line_number

        unit = 10
        line_number = 1

        open(unit, file=filename, status='old', action='read', iostat=ios)
        if (ios /= 0) then
            print *, "Error al abrir el archivo: ", filename
            stop
        end if

        ! Leer cada línea y procesarla
        do
            read(unit, '(A)', iostat=ios) line
            if (ios /= 0) exit
            call process_line(trim(line), line_number)
            line_number = line_number + 1
        end do
        close(unit)

    end subroutine read_file

    ! Subrutina para procesar cada línea del archivo
    subroutine process_line(line, line_number)
        character(len=*), intent(in) :: line
        integer, intent(in) :: line_number
    
        ! Variables auxiliares para identificar tokens y su posición
        character(len=:), allocatable :: current_lexema
        integer :: position, start, i
        character(len=1) :: caracter
        logical :: in_string, in_single_comment
    
        ! Inicializar variables
        allocate(character(len=0) :: current_lexema)  ! Lexema vacío al inicio
        in_string = .false.          ! Indica si estamos dentro de una cadena de texto
        in_single_comment = .false.  ! Indica si estamos dentro de un comentario de una sola línea
        position = 1                 ! Posición inicial en la línea

        ! Si estamos dentro de un comentario de múltiples líneas, seguir acumulando el contenido
        if (in_multi_comment) then
            ! Si encontramos el final del comentario en esta línea
            if (index(line, "*/") > 0) then
                ! Acumular la última parte del comentario antes de cerrar
                multi_comment_content = multi_comment_content // trim(line(1:index(line, "*/") + 1))
    
                ! Agregar el comentario como token completo
                call add_token(trim(multi_comment_content), "ComentarioMultilinea", line_number, position)
    
                ! Salir del comentario multilínea y reiniciar la variable de contenido
                in_multi_comment = .false.
                deallocate(multi_comment_content)
            else
                ! Continuar acumulando el contenido del comentario y seguir buscando el cierre
                multi_comment_content = multi_comment_content // trim(line) // new_line("A")
            end if
            return  ! Ignorar el resto de la línea ya que estamos dentro del comentario
        end if
    
        ! Recorrer la línea carácter por carácter
        i = 1
        do while (i <= len_trim(line))
            caracter = line(i:i)
    
            ! Detectar y manejar cadenas de texto (entre comillas dobles)
            if (caracter == '"' .and. .not. in_single_comment .and. .not. in_multi_comment) then
                if (.not. in_string) then
                    in_string = .true.
                    start = i  ! Marcar el inicio de la cadena
                else
                    in_string = .false.
                    ! Al encontrar el cierre de la cadena, agregarla como token
                    call add_token(trim(line(start:i)), "CadenaTexto", line_number, start)
                end if
                i = i + 1
                cycle
            end if

            ! Ignorar el contenido dentro de las cadenas de texto
            if (in_string) then
                i = i + 1
                cycle
            end if

            ! Detectar inicio de comentario de múltiples líneas ("/*")
            if (.not. in_single_comment .and. line(i:i+1) == "/*") then
                in_multi_comment = .true.
                multi_comment_start_line = line_number  ! Guardar la línea de inicio del comentario
                allocate(character(len=0) :: multi_comment_content)  ! Iniciar la variable para el contenido
                multi_comment_content = trim(line(i:)) // new_line("A")  ! Iniciar acumulando la primera línea
                i = i + 1  ! Avanzar una posición adicional para "/*"
                cycle
            end if
            
    
            ! Detectar comentarios de una sola línea ("//")
            if (.not. in_multi_comment .and. line(i:i+1) == "//") then
                in_single_comment = .true.
                start = i
                exit  ! Ignorar el resto de la línea, ya que es un comentario de una línea
            else if (.not. in_multi_comment .and. caracter == '/' .and. &
                (i == len_trim(line) .or. (line(i+1:i+1) /= '*' .and. line(i+1:i+1) /= '/'))) then
                call add_error("Error: Comentario mal formado", trim(line), line_number, i)
                exit
            end if
            

             ! Acumular el lexema actual si es una letra (A-Z, a-z) y no estamos en comentarios
            if (.not. in_single_comment .and. .not. in_multi_comment) then
                if ((caracter >= 'a' .and. caracter <= 'z') .or. (caracter >= 'A' .and. caracter <= 'Z') .or. (caracter >= '0' .and. caracter <= '9')) then
                    current_lexema = trim(current_lexema) // caracter
                
                ! Detectar delimitadores y operadores que indican el fin de un lexema
                else 
                    if (trim(current_lexema) /= "") then
                        if (current_lexema == "Etiqueta") then
                            call add_token(current_lexema, "Reservada_Etiqueta", line_number, position)
                        else if (trim(current_lexema) >= '0' .and. trim(current_lexema) <= '9') then
                            call add_token(current_lexema, "Numero", line_number, position)
                        else if (current_lexema == "Boton") then
                            call add_token(current_lexema, "Reservada_Boton", line_number, position)
                        else if (current_lexema == "Check") then
                            call add_token(current_lexema, "Reservada_Check", line_number, position)
                        else if (current_lexema == "RadioBoton") then
                            call add_token(current_lexema, "Reservada_RadioBoton", line_number, position)
                        else if (current_lexema == "Texto") then
                            call add_token(current_lexema, "Reservada_Texto", line_number, position)
                        else if (current_lexema == "AreaTexto") then
                            call add_token(current_lexema, "Reservada_AreaTexto", line_number, position)
                        else if (current_lexema == "Clave") then
                            call add_token(current_lexema, "Reservada_Clave", line_number, position)
                        else if (current_lexema == "Contenedor") then
                            call add_token(current_lexema, "Reservada_Contenedor", line_number, position)
                        else if (current_lexema == "Controles") then
                            call add_token(current_lexema, "Reservada_Controles", line_number, position)
                        else if (current_lexema == "Propiedades") then
                            call add_token(current_lexema, "Reservada_Propiedades", line_number, position)
                        else if (current_lexema == "Colocacion") then
                            call add_token(current_lexema, "Reservada_Colocacion", line_number, position)
                        else if (current_lexema == "setAncho") then
                            call add_token(current_lexema, "Reservada_setAncho", line_number, position)
                        else if (current_lexema == "setAlto") then
                            call add_token(current_lexema, "Reservada_setAlto", line_number, position)
                        else if (current_lexema == "setColorFondo") then
                            call add_token(current_lexema, "Reservada_setColorFondo", line_number, position)
                        else if (current_lexema == "setTexto") then
                            call add_token(current_lexema, "Reservada_setTexto", line_number, position)
                        else if (current_lexema == "setColorLetra") then
                            call add_token(current_lexema, "Reservada_setColorLetra", line_number, position)
                        else if (current_lexema == "setPosicion") then
                            call add_token(current_lexema, "Reservada_setPosicion", line_number, position)
                        else if (current_lexema == "this") then
                            call add_token(current_lexema, "Reservada_this", line_number, position)
                        else if (current_lexema == "add") then
                            call add_token(current_lexema, "Reservada_add", line_number, position)
                        else
                            call add_token(current_lexema, "Identificador", line_number, position)
                        end if
                    end if
        
                    ! Registrar el delimitador como un token si es necesario
                    if (caracter /= ' ') then
                        ! Clasificar el tipo del delimitador o símbolo
                        select case (caracter)
                            case (';')
                                call add_token(trim(caracter), "Punto y Coma", line_number, i)
                            case (',')
                                call add_token(trim(caracter), "Coma", line_number, i)
                            case ('(')
                                call add_token(trim(caracter), "Parentesis Abre", line_number, i)
                            case (')')
                                call add_token(trim(caracter), "Parentesis Cierra", line_number, i)
                            case ('.')
                                call add_token(trim(caracter), "Punto", line_number, i)
                            case('!')
                                call add_token(trim(caracter), "Exclamacion Cerrar", line_number, i)
                            case('<')
                                call add_token(trim(caracter), "Menor Que", line_number, i)
                            case('>')
                                call add_token(trim(caracter), "Mayor Que", line_number, i)
                            case('-')
                                call add_token(trim(caracter), "Guion", line_number, i)
                            case default
                                call add_error("Error: Caracter no reconocido", trim(caracter), line_number, i)
                        end select
                    end if
        
                    ! Reiniciar el lexema para comenzar a capturar uno nuevo
                    current_lexema = ""
                    position = i + 1
                end if
                
            end if
    
            ! Avanzar al siguiente carácter
            i = i + 1
        end do
    
        ! Agregar el último lexema si no se agregó al final del bucle y no estamos en comentarios
        if (trim(current_lexema) /= "" .and. .not. in_single_comment .and. .not. in_multi_comment) then
            if (current_lexema == "Etiqueta") then
                call add_token(current_lexema, "Reservada_Etiqueta", line_number, position)
            else if (current_lexema == "Controles") then
                call add_token(current_lexema, "Reservada_Controles", line_number, position)
            else if (current_lexema == "Propiedades") then
                call add_token(current_lexema, "Reservada_Propiedades", line_number, position)
            else if (current_lexema == "Colocacion") then
                call add_token(current_lexema, "Reservada_Colocacion", line_number, position)
            else
                call add_token(current_lexema, "Identificador", line_number, position)
            end if
        end if

            ! Verificar si estamos en una cadena que no fue cerrada
            if (in_string) then
                call add_error("Cadena no cerrada falta una comilla.", trim(line), line_number, start)
                in_string = .false.  ! Reiniciar el estado de cadena abierta
            end if

        ! Si estamos dentro de un comentario de una sola línea, agregarlo como token
        if (in_single_comment) then
            call add_token(trim(line(start:)), "Comentario_Linea", line_number, start)
            in_single_comment = .false.  ! Reiniciar el estado de comentario de una línea
        end if
    
        ! Liberar memoria del lexema temporal
        deallocate(current_lexema)
    end subroutine process_line
    
    ! Subrutina para agregar un error a la lista de tokens como tipo "Error Léxico"
    subroutine add_error(message, line_content, line, column)
        character(len=*), intent(in) :: message, line_content
        integer, intent(in) :: line, column
        type(Token), pointer :: new_token
    
        ! Crear un nuevo nodo para el error
        allocate(new_token)
        new_token%lexeme = trim(line_content)  ! Guardar solo el contenido que causó el error
        new_token%type = "Error Lexico: " // message  ! Descripción detallada en el campo 'type'
        new_token%line = line
        new_token%column = column
        new_token%next => null()
    
        ! Insertar el error en la lista enlazada (al final de la lista)
        if (.not. associated(token_list)) then
            token_list => new_token
            last_token => new_token
        else
            last_token%next => new_token
            last_token => new_token
        end if
    end subroutine add_error
    


    ! Subrutina para agregar un token a la lista enlazada
    subroutine add_token(lexeme, type, line, column)
        character(len=*), intent(in) :: lexeme, type
        integer, intent(in) :: line, column
        type(Token), pointer :: new_token

        ! Crear un nuevo nodo para el token
        allocate(new_token)
        new_token%lexeme = lexeme
        new_token%type = type
        new_token%line = line
        new_token%column = column
        new_token%next => null()

        ! Insertar el token en la lista enlazada
        if (.not. associated(token_list)) then
            ! La lista está vacía
            token_list => new_token
            last_token => new_token
        else
            ! Agregar al final de la lista
            last_token%next => new_token
            last_token => new_token
        end if
    end subroutine add_token
    
    subroutine create_html()
        type(Token), pointer :: current_token
        logical :: has_errors
        character(len=100) :: delete_html
        character(len=:), allocatable :: tabla_html
        character(len=:), allocatable :: header, row
        logical :: estado
        
        ! Inicializar el puntero a la lista de tokens
        current_token => token_list
        has_errors = .false.
        delete_html = "tokens.html"

        ! Comprobar si hay errores léxicos
        do while (associated(current_token))
            ! Verificar si el tipo del token es un error léxico
            if (index(current_token%type, "Error Lexico") > 0) then
                has_errors = .true.
            end if
            current_token => current_token%next
        end do

        if (has_errors) then
                            ! Verificamos si el archivo existe
            inquire(file=trim(delete_html), exist=estado)
            if (estado) then
                ! El archivo existe, procedemos a eliminarlo
                call system('del ' // trim(delete_html))

                print *, 'Archivo eliminado exitosamente.'
            else
                ! El archivo no existe
                print *, 'Error: El archivo no existe.'
            end if
        end if

        if (.not. has_errors) then
            ! Comenzar la construcción del HTML con CSS
            header = "<html><head><title>Resultado del Análisis Léxico</title>"
            header = header // "<link href=""https://fonts.googleapis.com/css2?family=Fredoka:wght@300..700&family=Playfair+Display:ital,wght@0,400..900;1,400..900&display=swap"" rel=""stylesheet"">"
            header = header // "<style>"
            header = header // "body {background-color: #f4f4f4; color: #333; }"
            header = header // "h1 { color: #3B3030; text-align: center; }"
            header = header // "table { border-collapse: collapse; width: 100%; margin-top: 20px; }"
            header = header // "th { background-color: #664343; color: #FFF0D1; padding: 10px; }"
            header = header // "td { border: 1px solid #dddddd; text-align: left; padding: 8px; }"
            header = header // "tr:nth-child(even) { background-color: #f2f2f2; }"
            header = header // "tr:hover { background-color: #ddd; }"
            header = header // ".fredokaBold {font-family: ""Fredoka"", sans-serif;font-optical-sizing: auto;font-weight: 600;font-style: normal;font-variation-settings:""wdth"" 100;}"
            header = header // " .fredoka {font-family: ""Fredoka"", sans-serif;font-optical-sizing: auto;font-weight: 400;font-style: normal;font-variation-settings:""wdth"" 100;}"
            header = header // " .fredokaLight {font-family: ""Fredoka"", sans-serif;font-optical-sizing: auto;font-weight: 200;font-style: normal;font-variation-settings:""wdth"" 100;}"
            header = header // "</style></head><body>"
            header = header // "<h1  class=""fredokaBold"">Tokens Encontrados</h1>"
            header = header // "<table class=""fredoka""><tr><th class=""fredokaLight"">Lexema</th><th class=""fredokaLight"">Tipo</th><th class=""fredokaLight"">Linea</th><th class=""fredokaLight"">Columna</th></tr>"
            
            tabla_html = header

            ! Reiniciar el puntero a la lista de tokens
            current_token => token_list
        
            do while (associated(current_token))
                ! Agregar una fila para cada token
                row = "<tr><td>" // current_token%lexeme // "</td><td>" // current_token%type // "</td><td>" // &
                    trim(adjustl(itoa(current_token%line))) // "</td><td>" // trim(adjustl(itoa(current_token%column))) // "</td></tr>"
            
                tabla_html = tabla_html // row
            
                current_token => current_token%next
            end do
        
            tabla_html = tabla_html // "</table></body></html>"  ! Cerrar la tabla y el HTML
            print *, "No se encontraron errores lexicos. Generando tabla HTML..."
        
            ! Guardar tabla_html en un archivo
            open(unit=11, file='tokens.html', status='replace')
            write(11, '(A)') tabla_html
            close(11)
        end if  
    
    end subroutine create_html
    

    function itoa(num) result(str)
        integer, intent(in) :: num
        character(len=32) :: str  ! Tamaño suficiente para números
    
        write(str, '(I0)') num  ! Convertir el número a cadena
    end function itoa

    subroutine csv_table_error_tokens()
        type(Token), pointer :: current_token
        logical :: has_errors

        ! Inicializar el puntero a la lista de tokens
        current_token => token_list
        has_errors = .false.

        do while (associated(current_token))
            ! Verificar si el tipo del token es un error léxico
            if (index(current_token%type, "Error Lexico") > 0) then
                has_errors = .true.
            end if
            current_token => current_token%next
        end do

        if (has_errors) then
            ! Abrir archivo para escribir
            open(unit=10, file='tokens.csv', status='replace')

            ! Escribir cabecera
            write(10, '(A)') 'Lexeme,Type,Line,Column'

            ! Escribir tokens en el archivo
            current_token => token_list
            do while (associated(current_token))
                if (index(current_token%type, "Error Lexico") > 0) then
                    write(10, '(A, A, I0, A, I0)') trim(current_token%lexeme) // ',', &
                                                trim(current_token%type) // ',', &
                                                current_token%line, ',', &
                                                current_token%column
                end if
                current_token => current_token%next
            end do

            ! Cerrar archivo
            close(10)

            print *, "Datos exportados a tokens.csv."
        end if
        if (.not. has_errors) then
            print *, "No se encontraron errores lexicos. No se exportaron datos."
        end if
    end subroutine csv_table_error_tokens
    

    ! Subrutina para imprimir los tokens y errores (opcional, para depuración)
    subroutine print_tokens()
        type(Token), pointer :: current_token
        logical :: has_errors
    
        ! Inicializar el puntero a la lista de tokens
        current_token => token_list
        has_errors = .false.
    
        print *, "Analizando los tokens..."
    
        ! Recorrer la lista de tokens, imprimiendo errores léxicos y tokens válidos
        do while (associated(current_token))
            ! Verificar si el tipo del token es un error léxico
            if (index(current_token%type, "Error Lexico") > 0) then
                print *, "Error Lexico: ", current_token%lexeme, " Descripcion: ", current_token%type, & 
                         " Linea: ", current_token%line, " Columna: ", current_token%column
                has_errors = .true.
            end if
            current_token => current_token%next
        end do
    
        ! Si no se encontraron errores léxicos, imprimir todos los tokens
        if (.not. has_errors) then
            print *, "No se encontraron errores léxicos. Imprimiendo tokens en consola..."
            ! Reiniciar el puntero a la lista de tokens
            current_token => token_list
            do while (associated(current_token))
                print *, "Token: ", current_token%lexeme, " Tipo: ", current_token%type, & 
                         " Linea: ", current_token%line, " Columna: ", current_token%column
                current_token => current_token%next
            end do
        end if
    end subroutine print_tokens

    subroutine parser()
        type(Token), pointer :: current_token
        logical :: has_errors
        
        current_token => token_list  ! Apuntar al inicio de la lista de tokens
        has_errors = .false.
    
        ! Bucle para recorrer toda la lista
        do while (associated(current_token) .and. trim(current_token%type) /= "Reservada_Propiedades")
            ! Verificar si el token actual es una declaración de Contenedor
            if (trim(current_token%type) == "Reservada_Contenedor" .or. &
                trim(current_token%type) ==  "Reservada_Etiqueta" .or. &
                trim(current_token%type) == "Reservada_Boton" .or. &
                trim(current_token%type) == "Reservada_Clave" .or. &
                trim(current_token%type) == "Reservada_Texto") then
                current_token => current_token%next
                if (associated(current_token) .and. trim(current_token%type) == "Identificador") then
                    current_token => current_token%next
                    if (associated(current_token) .and. trim(current_token%type) == 'Punto y Coma') then
                        print *, "Sintaxis correcta: del bloque de Controles"
                    else
                        print *, "Error de sintaxis: Se esperaba un punto y coma"
                        has_errors = .true.
                    end if
                else
                    print *, "Error de sintaxis: Se esperaba un identificador"
                    has_errors = .true.
                end if
            end if
    
            ! Modo pánico si hubo error
            if (has_errors) then
                ! Buscar el punto y coma para recuperarse
                do while (associated(current_token) .and. trim(current_token%type) /= 'Punto y Coma')
                    current_token => current_token%next
                end do
                if (associated(current_token)) then
                    print *, "Recuperación de error: Se encontró un punto y coma"
                    has_errors = .false.  ! Resetear el estado de error
                else
                    print *, "Recuperación de error: No se encontró un punto y coma"
                end if
            end if
    
            ! Continuar con el siguiente token
            if (associated(current_token)) current_token => current_token%next
        end do

        
        ! Bucle para recorrer toda la lista
        do while (associated(current_token) .and. trim(current_token%type) /= "Reservada_Colocacion")
            ! Verificar si el token actual es una declaración de Contenedor
            if (associated(current_token) .and. trim(current_token%type) == "Identificador") then
                current_token => current_token%next
                if (associated(current_token) .and. trim(current_token%type) == "Punto") then
                    current_token => current_token%next
                    if (associated(current_token) .and. trim(current_token%type) == 'Reservada_setAncho' .or. trim(current_token%type) == 'Reservada_setAlto') then
                        current_token => current_token%next
                        if(associated(current_token) .and. trim(current_token%type) == "Parentesis Abre") then
                            current_token => current_token%next
                            if(associated(current_token) .and. trim(current_token%type) == "Numero") then
                                current_token => current_token%next
                                if(associated(current_token) .and. trim(current_token%type) == "Parentesis Cierra") then
                                    current_token => current_token%next
                                    if (associated(current_token) .and. trim(current_token%type) == 'Punto y Coma') then
                                        print *, "Sintaxis correcta: setAncho o setAlto"
                                    else
                                        print *, "Error de sintaxis: Se esperaba un punto y coma"
                                        has_errors = .true.
                                    end if
                                else
                                    print *, "Error de sintaxis: Se esperaba un cierre de parentesis"
                                    has_errors = .true.
                                end if
                            else
                                print *, "Error de sintaxis: Se esperaba un numero"
                            end if
                        else
                            print *, "Error de sintaxis: Se esperaba una apertura de parentesis"
                        end if
                    else if (associated(current_token) .and. trim(current_token%type) == 'Reservada_setColorFondo' .or. trim(current_token%type) == 'Reservada_setColorLetra')then
                        current_token => current_token%next
                        if(associated(current_token) .and. trim(current_token%type) == "Parentesis Abre") then
                            current_token => current_token%next
                            if(associated(current_token) .and. trim(current_token%type) == "Numero") then
                                current_token => current_token%next
                                if(associated(current_token) .and. trim(current_token%type) == "Coma") then
                                    current_token => current_token%next
                                    if(associated(current_token) .and. trim(current_token%type) == "Numero") then
                                        current_token => current_token%next
                                        if(associated(current_token) .and. trim(current_token%type) == "Coma") then
                                            current_token => current_token%next
                                            if(associated(current_token) .and. trim(current_token%type) == "Numero") then
                                                current_token => current_token%next
                                                if(associated(current_token) .and. trim(current_token%type) == "Parentesis Cierra") then
                                                    current_token => current_token%next
                                                    if (associated(current_token) .and. trim(current_token%type) == 'Punto y Coma') then
                                                        print *, "Sintaxis correcta: setColorFondo o setColorLetra"
                                                    else
                                                        print *, "Error de sintaxis: Se esperaba un punto y coma"
                                                        has_errors = .true.
                                                    end if
                                                else
                                                    print *, "Error de sintaxis: Se esperaba un cierre de parentesis"
                                                    has_errors = .true.
                                                end if
                                            else
                                                print *, "Error de sintaxis: Se esperaba un numero"
                                            end if
                                        else
                                            print *, "Error de sintaxis: Se esperaba una coma"
                                        end if
                                    else
                                        print *, "Error de sintaxis: Se esperaba un numero"
                                    end if
                                else
                                    print *, "Error de sintaxis: Se esperaba un coma"
                                end if
                            else
                                print *, "Error de sintaxis: Se esperaba un numero"
                            end if
                        else
                            print *, "Error de sintaxis: Se esperaba una apertura de parentesis"
                        end if
                    else if (associated(current_token) .and. trim(current_token%type) == 'Reservada_setTexto') then
                        current_token => current_token%next
                        if(associated(current_token) .and. trim(current_token%type) == "Parentesis Abre") then
                            current_token => current_token%next
                            if(associated(current_token) .and. trim(current_token%type) == "CadenaTexto") then
                                current_token => current_token%next
                                if(associated(current_token) .and. trim(current_token%type) == "Parentesis Cierra") then
                                    current_token => current_token%next
                                    if (associated(current_token) .and. trim(current_token%type) == 'Punto y Coma') then
                                        print *, "Sintaxis correcta: setTexto"
                                    else
                                        print *, "Error de sintaxis: Se esperaba un punto y coma"
                                        has_errors = .true.
                                    end if
                                else
                                    print *, "Error de sintaxis: Se esperaba un cierre de parentesis"
                                    has_errors = .true.
                                end if
                            else
                                print *, "Error de sintaxis: Se esperaba una cadena"
                            end if
                        else
                            print *, "Error de sintaxis: Se esperaba una apertura de parentesis"
                        end if
                    else
                        print *, "Error de sintaxis: Se esperaba una palabra reservada"
                    end if
                else
                    print *, "Error de sintaxis: Se esperaba un punto"
                    has_errors = .true.
                end if
            end if
    
            ! Modo pánico si hubo error
            if (has_errors) then
                ! Buscar el punto y coma para recuperarse
                do while (associated(current_token) .and. trim(current_token%type) /= 'Punto y Coma')
                    current_token => current_token%next
                end do
                if (associated(current_token)) then
                    print *, "Recuperación de error: Se encontró un punto y coma"
                    has_errors = .false.  ! Resetear el estado de error
                else
                    print *, "Recuperación de error: No se encontró un punto y coma"
                end if
            end if
    
            ! Continuar con el siguiente token
            if (associated(current_token)) current_token => current_token%next
        end do

    
    end subroutine parser

end module lexer_module
