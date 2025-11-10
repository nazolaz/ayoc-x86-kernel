 PARTE 1: MODO PROTEGIDO

1)

El modo real del procesador es aquel en cual se inicia tras un encendido de la computadora. Se tiene que en este modo:

- No hay niveles de proteccion ni aislamiento, cualquier programa puede acceder a cualquier direccion. 
- Se cuenta con todo el set de instrucciones del 8086 y se trabaja en registros de 16 bits, asegurando retrocompatibilidad. 
- Se tiene 1MB de memoria para maniobrar.

Luego, el kernel se encarga de pasar de modo real a protegido. En este modo se tiene que:

- Contamos con registros de 32 bits y 4 GBs de memoria disponible. 
- Existen 4 niveles de proteccion (0-3), en donde el nivel 0 es el de mayor privilegio y esta reservado para el kernel y el 3 es reservado para tareas de usuario.
- Se introducen la paginacion y, junto con la GDT, la segmentacion las cuales otorgan proteccion a memoria.
- Permite ejecutar multiples tareas simultaneamente.

---

2)
Podriamos tener un sistema operativo en modo real pero seria limitado, inseguro y poco eficiente:

- Limitado ya que en el modelo actual de modo real, se cuenta unicamente con registros de 16 bits y 1MB de memoria.
- Inseguro porque no hay proteccion en la memoria, pudiendo acceder a cualquier parte de la misma.
- Poco eficiente porque no se cuenta con la capacidad de hacer multitareas.

Todas estas son desventajas se resuelven pasando a modo protegido.

---

3)
La Global Descriptor Table (GDT) es una tabla que define descriptores de segmento, es utilizada por el procesador en modo protegido para el acceso a la memoria. Cada descriptor de segmento contiene la siguiente informacion sobre el segmento al que referencia:

- **Limit:** Tamaño del segmento.
- **Base:** Direccion al inicio del segmento.
- **G:** Granularidad, define si el limite esta en bytes o en bloques de kb.
- **P:** Present bit, indica si el segmento esta activo en memoria.
- **DPL:** Nivel del privilegio del segmento.
- **S:** Descriptor de tipo, define si el segmento es de sistema o de datos/ejecucion.

---
4)

Tendriamos que usar la combinacion de bits `1010`:

- El bit 11 en 1 indica que el segmento es de codigo/ejecucion.
- El bit 10 en 0 indica que el segmento es ejecutable solo desde su propio DPL.
- El bit 09 en 1 indica que ademas el segmento es de lectura.
- El bit 08 en 0 indica que el segmento no ha sido accedido por la CPU.

---
6)

La variable `gdt` de tipo `gdt_entry_t[]` es un array que contiene los descriptores de segmento de la GDT.  
La variable `GDT_DESC` de tipo `gdt_descriptor_t` es un struct que contiene datos que se corresponden a los datos en los registros de la GDTR.  

Son variables externas declaradas en el header pero provistas por otro archivo.

---
10)

La instruccion `LGDT` carga la direccion y el limite de la GDT en el registro GDTR, osea los datos que en el codigo se corresponden al `GDT_DESC`. Esta variable se inicializa en el archivo `gdt.c`.

---
11)

Efectivamente, hay que modificarlo siendo que el bit menos significativo de este señala si el procesador se encuentra en modo protegido o real.

---
22)

El metodo `screen_draw_box`, dado un caracter y una seccion rectangulo de la pantalla, rellena esta seccion con dicho caracter junto con su atributo.  

Para acceder a la pantalla castea a la variable `VIDEO`, que es la direccion fisica del buffer de video y lo castea para utilizarlo como una matriz de `ca`'s del tamaño de la pantalla, pudiendo asi modificar el valor de cada pixel en memoria.  

Para representar cada caracter en pantalla utiliza la estructura `ca_s`, que contiene 2 `uint8_t` donde el primero es el propio caracter y el segundo sus atributos, por lo que ocupa 2 bytes en memoria.

-------------------------

### PARTE 2: INTERRUPCIONES

Primera parte
Cada entrada de la **IDT** tiene los siguientes campos:

- **DPL:** Describe el mínimo nivel de privilegio que debe tener un programa para llamar a la interrupción.  
- **Offset:** Dentro del segmento de código dado por el selector, indica dónde comienzan las instrucciones del *handler*.  
- **P:** *Present bit* que indica si la interrupción está activa en memoria.  
- **Selector:** Índice a un descriptor de segmento de código en la **GDT** que contiene el código del *handler*.  
- **D:** Indica si el tamaño del *gate* es de 16 o 32 bits.  

---

Segunda parte

a) **¿Qué oficiaría de prólogo y epílogo de estas rutinas?**  
Se usan las instrucciones `pushad` y `popad`, respectivamente, para el prólogo y epílogo.  
Estas salvan y restauran los registros volátiles que el usuario podría haber estado usando antes de la ejecución de la interrupción.  

b) **¿Qué marca el `iret` y por qué no usamos `ret`?**  
`iret` se usa para volver de una interrupción o excepción porque restaura el estado exacto de la CPU antes de la interrupción  
(`EIP`, `CS`, `EFLAGS` y, si hubo cambio de privilegio, `ESP` y `SS`).  
`ret` solo retorna de una llamada normal (`call`) sin restaurar este contexto.


------------------------------

### PARTE 3: PAGINACION

a) Podemos definir dos niveles de privilegio en dos partes del proceso de paginacion, utilizando el atributo U/S en las entradas de las siguientes estructuras:  
- En primera instancia, en el directorio de paginas, en donde se puede permitir o denegar accesos en modo usuario a los 4MiB dados por el direccionamiento de la entrada del directorio.  
- Luego, en la tabla de paginas pudiendo hacer lo mismo para los 4KiB dados por la entrada de la tabla.  

---

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

---

c) Se definen los siguientes atributos en las entradas de la tabla de pagina:  
- D: Indica si se escribio en la pagina dada por la entrada.  
- A: Indica si se accedio a la pagina dada por la entrada.  
- PCD: Deshabilita cachear los datos de la pagina.  
- PWT: Deshabilita hacer write-back al escribir en la pagina.  
- U/S: Determina si se puede acceder en modo usuario a la pagina.  
- R/W: Determina si se puede escribir en la memoria de la pagina.  
- P:  Es el present bit, debe estar prendido para mapear a una pagina.  

---

d) Se tiene que, para los atributos de las PDEs y PDTs:  
- Si una entrada tiene privilegios de supervisor, entonces el efecto combinado de las entradas tiene privilegio de supervisor  
- Si una de las entradas tiene privilegio de supervisor, entonces el efecto combinado de las entradas presenta un tipo de acceso Read/Write  
- Por ultimo, si ambas entradas tienen privilegio de usuario, entonces el efecto combinado de las entradas sera de tipo Read/Only a menos que ambas entradas fueran de tipo Read/Write  

---

e) Se tiene que cada tarea tiene un directorio de paginas propio el cual, al ser de 4KiB, ocupa una pagina.  
Por otro lado, se necesitan 2 paginas para el codigo y 1 para la pila. Y, como una tabla de pagina contiene 1024 paginas y solo necesitamos 3, la tarea ocupa una sola tabla de paginas.  
Por lo tanto se necesitaran 5 paginas, una para el directorio, otra para la tabla y otras 3 requeridas por la tarea.  

---

f) La TLB es una cache de traducciones utilizada para acelerar el proceso de traduccion. Es necesario invalidarlo al modificar las estructuras de paginacion ya que sino se podria estar accediendo a una traduccion vieja dada por una direccion lineal.  
Cada traduccion en la TLB posee los siguientes atributos:  
- La direccion de memoria fisica  
- Flags de permisos y privilegios(R/W, U/S, etc)  
- Flags de estado (Dirty flag (D), memory type, etc.)  
Al ser su unica funcion la de almacenar cache temporal, invalidar la TLB no afecta las tablas de paginas en memoria.  

---------------------------------------

### PARTE 4: TAREAS

1) 
Si queremos definir un sistema que utilice dos tareas se necesitaria:
    - Una TSS (task state segment) para cada tarea. Esta es una estructura que almacena el estado de procesador previo al inicio de la tarea.
    - Dos entradas en la GDT que tengan los descriptores de la TSS, los cuales tendran la direccion a su respectiva de TSS ademas de distintos atributos.
    - En el inicio de la ejecucion del sistema, deberiamos poner en el registro TR (Task register) a la tarea inicial llamando a LTR.
    - Ademas, si quisieramos definir a estas tareas en la IDT para que puedan ser activadas como interrupciones, tendriamos que definir un task gate para cada una en la IDT.

---

2) 
Se llama cambio de contexto al proceso que se lleva a cabo en el pasaje de una tarea a otra, en donde se guarda el estado completo del procesador (contexto de la tarea en proceso) en la TSS de dicha tarea y se carga a los registros el contexto de la tarea a ejecutar. 
El registro TR almacena el selector de segmento que apunta al descriptor de TSS de la tarea en proceso en la GDT. 
En un cambio de contexto, la CPU toma el TSS apuntado por la TR y guarda alli los registros de la tarea actual para luego cargar los registros de la nueva tarea a ejecutar (dados por su TSS).

---

3) 
Al momento de realizar el primer cambio de contexto se deberia cargar una tarea inicial utilizando la instruccion LTR (que toma como parametro un registro de 16 bits con el selector de la tarea en la GDT) para cargar aquella direccion en la TR y de alli entrar en la GDT buscando el TSS Descriptor de esa tarea.
Por otro lado, el CPU siempre tiene que estar ejecutando una tarea por lo que se tiene que definir una task idle por si no tiene tareas disponibles para ejecutar. Eso se hace con un jmp far junto al selector de aquella tarea idle. 

---

4) 
El scheduler es el modulo del SO que trabaja con una lista de tareas a ejecutar, dividiendo el tiempo a utilizar para la ejecucion de tareas en un intervalo definido llamado timeframe que funciona como unidad. 
Ademas, el scheduler sigue una politica sobre la cual asignar la prioridad de ejecucion a las tareas.

---

5) 
Aunque pueda parecer que las tareas se ejecutan en paralelo, en un solo núcleo se ejecutan de forma secuencial, con miles de cambios de contexto por segundo. 

---

11) 
a. En cada tick del reloj, ademas del prologo y el epilogo, se ejecutan estas instrucciones:
    - call sched_next_task: que obtiene la siguiente tarea disponible, arranca su ejecucion y devuelve retorna su selector de segmento en la GDT. En caso de que no haya tarea disponible, realiza este proceso con el Idle.
    - Si la tarea a ejecutar es la misma que la que se estaba ejecutando, se salta directamente al epilogo. Caso contrario, se guarda al valor del selector de la nueva tarea (que se encontraba en ax) en la direccion dada por sched_task_selector y hace el cambio de tareas con un 'jmp far' a la direccion dada por sched_task_offset

    b. El tamaño de sched_task_offset es de 4 bytes e indica el offset al cual se hace jmp far para cambiar de tarea, y no tiene ningun efecto. 

    c. Cuando una tarea vuelve a ser puesta en ejecucion, continua corriendo desde el eip guardado en su respectiva TSS

---

12) 
a. El scheduler va recorriendo de forma circular la lista a partir de la siguiente a la actual hasta que encuentra alguna que este disponible, chequeando si tiene el atributo 'runnable', para ser ejecutada o hasta que se encuentre a si misma. Una vez que se encuentre con la tarea que cumpla esta condicion, setea su indice como el de la  nueva tarea actual, y retorna su selector de segmento (que permite a acceder a su TSS descriptor en la GDT).

---

14) 
a. La funcion tss_gdt_entry_for_task crea una entrada en la gdt para la tarea que esta siendo creada a partir de su TSS.
b. Esto es porque el gdt_id es un indice de acceso a un descriptor de la GDT, y la funcion sched_add_task es llamada a partir del selector de segmento de la task, por lo que es necesario hacer el shifteo para adaptar el formato. 

---

15) 
a. Las tareas usan syscalls para comunicarse con ek kernel, cambiando el modo de ejecucion de modo a usuario a modo kernel para que ejecute la operacion con los privilegios adecuados y guardando los registros generales en la pila del kernel.

b. Se tiene en consideracion el espacio de memoria que usa una variable en .data. Por otro lado, si una tarea intentase escribir en su .data podria estar reescribiendo informacion que podria necesitarse en otra instancia.

---

16) 
a. La tarea ejecucta en un loop infinito para evitar la ejecucion de otra tarea indeseada.

---

18) 
Tenemos dos tipos de tareas distintas para simular la funcion de multitasking, siendo que en el QEMU se le asigna un espacio de pantalla a cada una de estas tasks. Para ejecutar una tarea distinta, es suficiente con cambiar la tarea a ejecutar en el makefile.