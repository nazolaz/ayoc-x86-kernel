PREGUNTAS 
    - e) Cada directorio ocupa una pagina??? No es una idea medio recursiva eso?????? ayuda
__________________

a) Podemos definir dos niveles de privilegio en dos partes del proceso de paginacion, utilizando el atributo U/S en las entradas de las siguientes estructuras:
    - En primera instancia, en el directorio de paginas, en donde se puede permitir o denegar accesos en modo usuario a los 4MiB dados por el direccionamiento de la entrada del directorio. 
    - Luego, en la tabla de paginas pudiendo hacer lo mismo para los 4KiB dados por la entrada de la tabla.

b) Dada una direccion virtual definida por:
    | 10 bits | 10 bits | 12 bits |
Donde estos 32 bits estan definidos por:
    - Los primeros 10 bits son el indice en el directorio de paginas
    - Los siguientes 10 on el indice en la tabla de paginas
    - Por ultimo, 12 bits que marcan el offset dentro de la pagina
Por otro lado, el CR3 tiene en sus 20 bits mas altos la direccion fisica del page directory, lo que nos otorga una base para acceder con los indices dados por la direccion virtual.
Para conseguir la memoria fisica, podemos seguir el siguiente pseudocodigo:
    1. Obtenemos la direccion base del directorio de paginas a traves de los 20 bits mas altos del CR3.
    2. Con esta direccion y los 10 bits propios del indice de la entrada en el directorio de paginas accedemos a la tabla de paginas.
    3. Habiendo accedido a la tabla de paginas, con los siguientes 10 bits accedemos a la pagina que corresponde.
    4. Luego, ya con la base de la pagina, sumamos el offset dado por los 12 bits mas bajos de la direccion virtual.

c) Se definen los siguientes atributos en las entradas de la tabla de pagina:
    - D: Indica si se escribio en la pagina dada por la entrada.
    - A: Indica si se accedio a la pagina dada por la entrada.
    - PCD: Deshabilita cachear los datos de la pagina.
    - PWT: Deshabilita hacer write-back al escribir en la pagina. 
    - U/S: Determina si se puede acceder en modo usuario a la pagina.
    - R/W: Determina si se puede escribir en la memoria de la pagina.
    - P:  Es el present bit, debe estar prendido para mapear a una pagina.

d) Se tiene que, para los atributos de las PDEs y PDTs:
    - Si una entrada tiene privilegios de supervisor, entonces el efecto combinado de las entradas tiene privilegio de supervisor

    - Si una de las entradas tiene privilegio de supervisor, entonces el efecto combinado de las entradas presenta un tipo de acceso Read/Write

    - Por ultimo, si ambas entradas tienen privilegio de usuario, entonces el efecto combinado de las entradas sera de tipo Read/Only a menos que ambas entradas fueran de tipo Read/Write

e) Se tiene que cada tarea tiene un directorio de paginas propio el cual, al ser de 4KiB, ocupa una pagina. 
Por otro lado, se necesitan 2 paginas para el codigo y 1 para la pila. Y, como una tabla de pagina contiene 1024 paginas y solo necesitamos 3, la tarea ocupa una sola tabla de paginas.
Por lo tanto se necesitaran 5 paginas, una para el directorio, otra para la tabla y otras 3 requeridas por la tarea. 

f) La TLB es una cache de traducciones utilizada para acelerar el proceso de traduccion. Es necesario invalidarlo al modificar las estructuras de paginacion ya que sino se podria estar accediendo a una traduccion vieja dada por una direccion lineal.
Cada traduccion en la TLB posee los siguientes atributos:
    - La direccion de memoria fisica
    - Flags de permisos y privilegios(R/W, U/S, etc)
    - Flags de estado (Dirty flag (D), memory type, etc.)


