POR HACER
---------
    - Preguntar por 11)b.
    - ver en donde ponemos los externs de kernel.asm
    - preguntar orden


Primera parte: Inicializacion de tareas
---------------------------------------
1) Si queremos definir un sistema que utilice dos tareas se necesitaria:
    - Una TSS (task state segment) para cada tarea. Esta es una estructura que almacena el estado de procesador previo al inicio de la tarea.
    - Dos entradas en la GDT que tengan los descriptores de la TSS, los cuales tendran la direccion a su respectiva de TSS ademas de distintos atributos.
    - En el inicio de la ejecucion del sistema, deberiamos poner en el registro TR (Task register) a la tarea inicial llamando a LTR.
    - Ademas, si quisieramos definir a estas tareas en la IDT para que puedan ser activadas como interrupciones, tendriamos que definir un task gate para cada una en la IDT.

2) Se llama cambio de contexto al proceso que se lleva a cabo en el pasaje de una tarea a otra, en donde se guarda el estado completo del procesador (contexto de la tarea en proceso) en la TSS de dicha tarea y se carga a los registros el contexto de la tarea a ejecutar. 
El registro TR almacena el selector de segmento que apunta al descriptor de TSS de la tarea en proceso en la GDT. 
En un cambio de contexto, la CPU toma el TSS apuntado por la TR y guarda alli los registros de la tarea actual para luego cargar los registros de la nueva tarea a ejecutar (dados por su TSS).

3) Al momento de realizar el primer cambio de contexto se deberia cargar una tarea inicial utilizando la instruccion LTR (que toma como parametro un registro de 16 bits con el selector de la tarea en la GDT) para cargar aquella direccion en la TR y de alli entrar en la GDT buscando el TSS Descriptor de esa tarea.
Por otro lado, el CPU siempre tiene que estar ejecutando una tarea por lo que se tiene que definir una task idle por si no tiene tareas disponibles para ejecutar. Eso se hace con un jmp far junto al selector de aquella tarea idle. 

4) El scheduler es el modulo del SO que trabaja con una lista de tareas a ejecutar, dividiendo el tiempo a utilizar para la ejecucion de tareas en un intervalo definido llamado timeframe que funciona como unidad. 
Ademas, el scheduler sigue una politica sobre la cual asignar la prioridad de ejecucion a las tareas.

5) Aunque pueda parecer que las tareas se ejecutan en paralelo, en un solo núcleo se ejecutan de forma secuencial, con miles de cambios de contexto por segundo. 

11) a. En cada tick del reloj, ademas del prologo y el epilogo, se ejecutan estas instrucciones:
    - call sched_next_task: que obtiene la siguiente tarea disponible, arranca su ejecucion y devuelve retorna su selector de segmento en la GDT. En caso de que no haya tarea disponible, realiza este proceso con el Idle.
    - Si la tarea a ejecutar es la misma que la que se estaba ejecutando, se salta directamente al epilogo. Caso contrario, se guarda al valor del selector de la nueva tarea (que se encontraba en ax) en la direccion dada por sched_task_selector y hace el cambio de tareas con un 'jmp far' a la direccion dada por sched_task_offset

    b. El tamaño de sched_task_offset es de 4 bytes e indica la direccion de la tarea dentro del segmento en la GDT.....¿?¿?

    c. Cuando una tarea vuelve a ser puesta en ejecucion, continua corriendo desde el eip guardado en su respectiva TSS

12) a. El scheduler va recorriendo de forma circular la lista a partir de la siguiente a la actual hasta que encuentra alguna que este disponible, chequeando si tiene el atributo 'runnable', para ser ejecutada o hasta que se encuentre a si misma. Una vez que se encuentre con la tarea que cumpla esta condicion, setea su indice como el de la  nueva tarea actual, y retorna su selector de segmento (que permite a acceder a su TSS descriptor en la GDT).

14) a. La funcion tss_gdt_entry_for_task crea una entrada en la gdt para la tarea que esta siendo creada a partir de su TSS.
b. Esto es porque el gdt_id es un indice de acceso a un descriptor de la GDT, y la funcion sched_add_task es llamada a partir del selector de segmento de la task, por lo que es necesario hacer el shifteo para adaptar el formato. 
