# PARTE 1: MODO PROTEGIDO

### EJERCICIO 1

El modo real del procesador es aquel en cual se inicia tras un encendido de la computadora. Se tiene que en este modo:

- No hay niveles de proteccion ni aislamiento, cualquier programa puede acceder a cualquier direccion. 
- Se cuenta con todo el set de instrucciones del 8086 y se trabaja en registros de 16 bits, asegurando retrocompatibilidad. 
- Se tiene 1MB de memoria para maniobrar.

Luego, el kernel se encarga de pasar de modo real a protegido. En este modo se tiene que:

- Contamos con registros de 32 bits y 4 GBs de memoria disponible. 
- Existen 4 niveles de proteccion (0-3), en donde el nivel 0 es el de mayor privilegio y esta reservado para el kernel y el 3 es reservado para tareas de usuario.
- Se introducen la paginacion y, junto con la GDT, la segmentacion las cuales otorgan proteccion a memoria.
- Permite ejecutar multiples tareas simultaneamente.

### EJERCICIO 2

Podriamos tener un sistema operativo en modo real pero seria limitado, inseguro y poco eficiente:

- Limitado ya que en el modelo actual de modo real, se cuenta unicamente con registros de 16 bits y 1MB de memoria.
- Inseguro porque no hay proteccion en la memoria, pudiendo acceder a cualquier parte de la misma.
- Poco eficiente porque no se cuenta con la capacidad de hacer multitareas.

Todas estas son desventajas se resuelven pasando a modo protegido.

### EJERCICIO 3

La Global Descriptor Table (GDT) es una tabla que define descriptores de segmento, es utilizada por el procesador en modo protegido para el acceso a la memoria. Cada descriptor de segmento contiene la siguiente informacion sobre el segmento al que referencia:

- **Limit:** Tamaño del segmento.
- **Base:** Direccion al inicio del segmento.
- **G:** Granularidad, define si el limite esta en bytes o en bloques de kb.
- **P:** Present bit, indica si el segmento esta activo en memoria.
- **DPL:** Nivel del privilegio del segmento.
- **S:** Descriptor de tipo, define si el segmento es de sistema o de datos/ejecucion.

### EJERCICIO 4

Tendriamos que usar la combinacion de bits `1010`:

- El bit 11 en 1 indica que el segmento es de codigo/ejecucion.
- El bit 10 en 0 indica que el segmento es ejecutable solo desde su propio DPL.
- El bit 09 en 1 indica que ademas el segmento es de lectura.
- El bit 08 en 0 indica que el segmento no ha sido accedido por la CPU.

### EJERCICIO 6

La variable `gdt` de tipo `gdt_entry_t[]` es un array que contiene los descriptores de segmento de la GDT.  
La variable `GDT_DESC` de tipo `gdt_descriptor_t` es un struct que contiene datos que se corresponden a los datos en los registros de la GDTR.  

Son variables externas declaradas en el header pero provistas por otro archivo.

### EJERCICIO 10

La instruccion `LGDT` carga la direccion y el limite de la GDT en el registro GDTR, osea los datos que en el codigo se corresponden al `GDT_DESC`. Esta variable se inicializa en el archivo `gdt.c`.

### EJERCICIO 11

Efectivamente, hay que modificarlo siendo que el bit menos significativo de este señala si el procesador se encuentra en modo protegido o real.

### EJERCICIO 22

El metodo `screen_draw_box`, dado un caracter y una seccion rectangulo de la pantalla, rellena esta seccion con dicho caracter junto con su atributo.  

Para acceder a la pantalla castea a la variable `VIDEO`, que es la direccion fisica del buffer de video y lo castea para utilizarlo como una matriz de `ca`'s del tamaño de la pantalla, pudiendo asi modificar el valor de cada pixel en memoria.  

Para representar cada caracter en pantalla utiliza la estructura `ca_s`, que contiene 2 `uint8_t` donde el primero es el propio caracter y el segundo sus atributos, por lo que ocupa 2 bytes en memoria.


---

# PARTE 2: INTERRUPCIONES

### PRIMERA PARTE
#### 