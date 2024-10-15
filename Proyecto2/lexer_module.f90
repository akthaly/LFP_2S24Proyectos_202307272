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

        ! Verificar si al final del archivo seguimos en un comentario multilínea
        if (in_multi_comment) then
            call add_error("Error: Comentario multilinea sin cierre encontrado al final del archivo.", "EOF", line_number, 1)
            in_multi_comment = .false.  ! Reiniciar estado del comentario
        end if
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

        ! Si estamos dentro de un comentario de múltiples líneas, acumular el contenido
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
    
            ! Detectar un solo '/' como error si no está seguido de '*' ni '/'
            else if (.not. in_multi_comment .and. caracter == '/' .and. &
                     (i == len_trim(line) .or. (line(i+1:i+1) /= '*' .and. line(i+1:i+1) /= '/'))) then
                call add_error("Error: Comentario mal formado, falta '/' o '*'.", trim(line), line_number, i)
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
                            ! Agrega más símbolos si es necesario
                            case default
                                call add_token(trim(caracter), "Simbolo Desconocido", line_number, i)
                        end select
                    end if
        
                    ! Reiniciar el lexema para comenzar a capturar uno nuevo
                    current_lexema = ""
                    position = i + 1
                end if

                if (caracter == '!') then
                    call add_token(trim(caracter), "Exclamacion Cerrar", line_number, i)
                else if (caracter == ">") then
                    call add_token(trim(caracter), "Mayor que", line_number, i)
                else if (caracter == "<") then
                    call add_token(trim(caracter), "Menor que", line_number, i)
                else if (caracter == "-") then
                    call add_token(trim(caracter), "Guion", line_number, i)
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
                call add_error("Error: Cadena no cerrada, falta una comilla.", trim(line), line_number, start)
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
        new_token%lexeme = message // " Error lexico: " // trim(line_content)  ! Combinar el mensaje con la línea completa
        new_token%type = "Error Lexico"
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

    ! Subrutina para imprimir los tokens y errores (opcional, para depuración)
    subroutine print_tokens()
        type(Token), pointer :: current_token
        current_token => token_list

        print *, "Lista de Tokens y Errores:"
        do while (associated(current_token))
            if (current_token%type == "Error Lexico") then
                print *, "Error: ", current_token%lexeme, &
                     " Linea: ", current_token%line, " Columna: ", current_token%column
            else
                print *, "Token: ", current_token%lexeme, " Tipo: ", current_token%type, &
                        " Linea: ", current_token%line, " Columna: ", current_token%column
            end if
            current_token => current_token%next
        end do
    end subroutine print_tokens



end module lexer_module
