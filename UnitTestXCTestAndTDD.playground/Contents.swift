import UIKit
import XCTest
import PlaygroundSupport

/*
 Test unitarios (XCTest y TDD)
 */

/*
 Red-Green-Refactor:
 
 El ciclo de trabajo de TDD se entiende como la aplicación de los citados test unitarios que prueban nuestro código, en un ciclo de trabajo que es paralelo al desarrollo de la app. Los test, para hacerlo bien, han de ir implementados y han de ser adaptados mientras hacemos la app. Nunca hay que ponerlos cuando una app ya está hecha. Para ello se usa el ciclo red-green-refactor que se compone de los siguientes pasos:
 
 Red: el test ha de fallar. Si hacemos un test que prueba una clase, hemos de comprobar que dicho test primero no funciona. Por ejemplo, si vamos a crear (como en el ejemplo que veremos más abajo) una comprobación que valide que el número de datos que se cargan es correcto, hemos de probar primero que la clase devuelve el número incorrecto de valores para que el test falle. Bien forzando que devuelva un dato erróneo o bien haciendo la prueba antes de implementar el código que recupera los datos para que devuelve que no hay datos (la mejor opción).
 
 Green: el test ha de funcionar. Una vez probamos que el test falla, implementamos la funcionalidad que queremos probar. Si queremos verificar que el número de registros de una carga es correcto, pues ahora hacemos el código que carga los datos. Volvemos a probar el test y comprobamos que este es satisfactorio.
 
 Refactor: adaptando. Se basa en que nuestro código de test tiene que adaptarse en tiempo real a cualquier cambio funcional y que, además, si podemos, hemos de optimizarlo lo más posible. Tanto el código como las pruebas. Y cuando una funcionalidad cambie, deberemos adaptar los test y empezar de nuevo desde el nivel rojo a probar, primero que falla, luego que funciona, etc…
 
 El trabajo es contínuo y en paralelo. No son dos tareas separadas, si no que hemos de trabajar con el código de nuestra app y con los test que validan su funcionalidad a la vez. Adaptando unos mientras generamos lo otro.
 
 Test básicos por prototipos:
 
 Vamos a crear una clase que realice una carga de datos desde un fichero local y desde un JSON en red, para probar test síncronos (test que responden en tiempo real) y los asíncronos (test que prueban procesos que tardan un tiempo en comprobar si han sido o no realizados, como una carga de datos de red).

 Primero creamos la base o esqueleto de nuestra clase y del test, de la siguiente forma:
 */

PlaygroundPage.current.needsIndefiniteExecution = true
URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)

class Carga {
    var datos:[String] = []
    var datosAsync:[[String:Any]] = [[:]]
    
    // Carga del fichero datos1.plist que está en los "Resources del playground"
    init() {
        if let ruta = Bundle.main.path(forResource: "datos1", ofType: "plist"), let datos = FileManager.default.contents(atPath: ruta) {
            do {
                if let cargaInicial = try PropertyListSerialization.propertyList(from: datos, options: [], format: nil) as? [String:Any] {
                    self.datos = cargaInicial["pokemons"] as! [String]
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // Carga de datos asíncrona desde la red
    func cargaAsync() {
        if let rutaURL = URL(string: "https://jsonplaceholder.typicode.com/users") {
            let request = URLRequest(url: rutaURL)
            let session = URLSession.shared
            let task = session.dataTask(with: request) {
                [unowned self] (data, response, error) in
                do {
                    guard let data = data, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    self.datosAsync = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String:Any]]
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue:"cargaCompletada"), object: self)
                } catch {
                    print("Fallo en la carga del JSON")
                }
            }
            task.resume()
        }
    }
}

let carga = Carga()

class TestCarga:XCTestCase {
    var carga:Carga!
    
    override func setUp() {
        carga = Carga()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        carga = nil
    }
    
    // Comprueba que el fichero datos1.plist tenga 24 registros
    func testCarga() {
        XCTAssertEqual(carga.datos.count, 24)
    }
    
    func testWaitCargaAsync() {
        let expectacion = XCTNSNotificationExpectation(name: NSNotification.Name(rawValue: "cargaCompletada"), object: carga, notificationCenter: NotificationCenter.default)
        carga.cargaAsync()
        let waiter = XCTWaiter()
        waiter.delegate = self
        waiter.wait(for: [expectacion], timeout: 5)
    }
}

let test = TestCarga.defaultTestSuite
test.run()

/*
 Tenemos por un lado la clase Carga donde tenemos una propiedad datos de tipo array de cadenas, que usaremos para guardar la carga de un archivo que tiene 24 registros. La idea es comprobar que efectivamente, el archivo que cargamos siempre tiene esos mismos 24 registros y no cambia por cualquier motivo. Además tenemos la propiedad datosAsync que guardará los datos que vamos a recuperar asíncronamente de internet, en un JSON.

 La parte de test, la que nos interesa, es la clase TestCarga, subclase de XCTestCase. Cualquier método en esta función que comience por la palabra test será considerada por el framework como una prueba unitaria, y se ejecutará al hacer la instrucción de ejecución que luego veremos. Dentro de esta subclase hacemos sobrecarga (override) de dos funciones: setUp() y tearDown(). La primera configura la instancia y la última la desconfigura (la desinicializa). Es importante que en ambos métodos (si se sobrecargan) se llame siempre al padre con super para ejecutar la funcionalidad que de por sí realiza el framework. Si no, podemos obtener errores extraños.

 Lo que hacemos en el test es definir una instancia de nuestra clase Carga con la que trabajaremos, pero que no afectará en modo alguno a la normal vida fuera de dicho ámbito de la clase o cualquier instancia que existiera. En muchas ocasiones, en otros lenguajes, se usa lo que se llaman clases mock (o falsas) que sustituyen las instancias reales por otras falsas en tiempo de ejecución.

 Pero debido a la arquitectura de Swift, en este es imposible usar librerías mock ya que el código compilado no soporta ejecución dinámica por su orientación a datos por valor. Por lo tanto, no podemos cambiar un puntero en tiempo de ejecución porque gran parte del lenguaje no está orientado a objetos, como las estructuras de arrays o las cadenas… por lo tanto no podríamos crear copias falsas que sustituyeran los punteros en tiempo de ejecución porque estos no existen. Las clases falsas tenemos que generarlas nosotros por programación, como estamos haciendo creando una instancia de Clase dentro de la propia clase TestClase.

 Vamos a crear la primera función de test, que vamos a llamar testCarga(). En ella pondremos la comprobación de la condición que nos importa: que haya 24 datos en el fichero plist que cargamos. Para ello usamos una serie de métodos del framework XCTest que son afirmaciones (asserts) que se comprueban. Métodos que son la esencia de las preguntas que hacemos con los tests. De forma que el hecho que NO devuelva verdadero en una afirmación que hagamos, provocará que el test que contiene la afirmación falle. Estas afirmaciones se hacen con métodos que empieza todos por XCTAssert donde tenemos diferentes a verificar: igualdad, no igualdad, si es nil o no, si un elemento es mayor que otro o menor… Todos métodos genéricos.
 
 Ponemos este método dentro de la clase TestCarga y con ello ya tenemos nuestro primer test. Ahora vamos a probar que falla, porque no hemos hecho carga alguna. Para ejecutar los tests en un playground solo tenemos que poner debajo de let test = TestCarga.defaultTestSuite() la ejecución del método run() de la instancia que se ha creado.
 
 Veremos que en la consola nos aparece la siguiente información:
 
 Test Suite 'TestCarga' started at 2017-05-04 19:53:01.058
 Test Case '-[__lldb_expr_55.TestCarga testCarga]' started.
 MyPlayground.playground:56: error: -[__lldb_expr_55.TestCarga testCarga] : XCTAssertEqual failed: ("0") is not equal to ("24") -
 Test Case '-[__lldb_expr_55.TestCarga testCarga]' failed (0.003 seconds).
 Test Suite 'TestCarga' failed at 2017-05-04 19:53:06.124.
      Executed 1 test, with 0 failures (0 unexpected) in 0.003 (0.005) seconds
 
Como podemos ver nos avisa: XCTAssertEqual failed: ("0") is not equal to ("24"). O sea, que la afirmación que hemos hecho que carga.datos.count es igual a 24 ha resultado falsa y eso ha provocado que el test falle. Ahora ponemos la carga dentro de la función init() de nuestra clase Carga.
 
 Estamos cargando un fichero plist que tenemos en los recursos del playground, carpeta Resources (pinchad aquí para bajarlo y ponerlo en vuestros proyectos). Ahora, al hacer la carga, de pronto el mensaje cambia:
 
 Test Suite 'TestCarga' started at 2017-05-04 21:25:17.185
 Test Case '-[__lldb_expr_60.TestCarga testCarga]' started.
 Test Case '-[__lldb_expr_60.TestCarga testCarga]' passed (0.003 seconds).
 Test Suite 'TestCarga' passed at 2017-05-04 21:25:17.190.
      Executed 1 test, with 0 failures (0 unexpected) in 0.003 (0.005) seconds
 
 Ya hemos pasado el test porque ahora carga.datos.count es igual a 24. La afirmación que hemos hecho para verificar el test es correcta y se da por pasado (passed). Esa es la esencia del estado red (que falle) y pasar a green (que funcione). Si siguiéramos a partir de aquí implementando código, tendríamos que ir refactorizando (retocando) el código del test para que se fuera adaptando o mejorando. *Buscar maneras más eficientes de comprobar que los datos se cargan, en vez de comprobar un número concreto pasado como valor**.
 
 Test asíncronos:
 
 Cuando hacemos una llamada a la red o hacemos algún proceso que requerirá un tiempo superior al normal dentro del flujo de ejecución de un programa (lo que llamaríamos el «tiempo real») tenemos un proceso asíncrono. Un proceso en que la sincronía del programa y su normal flujo de ejecución se rompen pues el proceso que se lanza tardará en responder y por lo tanto quedará relegado a esperar la respuesta.

 Pero antes de ponernos a implementar los test asíncronos y explicar cómo son, hemos de incluir un par de líneas en nuestro playground, en la parte superior, justo encima de la definición de la clase Carga.
 
 La primera de las líneas nos permite decirle al playground que no se detenga cuando termine la ejecución síncrona (que es su comportamiento normal) sino que se quede ejecutando para que así el proceso asíncrono pueda contestar pasados los segundos que vayamos a esperarle. Para acceder al singleton PlaygroundPage.current tenemos que importar la clase PlaygroundSupport así que tenemos que poner en la parte de más arriba, donde el resto de instrucciones import, la siguiente instrucción: import PlaygroundSupport
 
 La siguiente línea (URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)) es un pequeño parche para un fallo. Si no lo ponemos, el sistema intentará escribir en la zona de disco una información temporal referente a nuestro código y nos dará error por los propios permisos de seguridad del playground. De esta forma, anulamos este proceso para que no falle y todo vaya sin problema.

 Tras esto, comenzamos. Lo primero, siguiendo el ciclo red-green-refactor es crear el test para que falle. Y para eso hemos de entender qué vamos a hacer. ¿Cómo funciona un test asíncrono? Funciona con lo que llamamos expectaciones. Creamos una expectación a que algo va a suceder, y si esta se cumple antes de un tiempo determinado el test será correcto.

 Tenemos tres opciones: crear una expectación a partir de una cadena que luego en un proceso asíncrono haremos que se cumpla invocando el método fulfill() de la misma, crear una que depende de un predicado que será analizado sobre un objeto que se pasará y si el predicado devuelve verdadero la expectación se dará por satisfecha o suscribirnos a una notificación que cuando sea lanzada cumplirá la expectación. En nuestro caso vamos a hacer la última.

 Para ello creamos un nuevo test en nuestra clase con el siguiente código:
 
 func testWaitCargaAsync() {
     let expectacion = XCTNSNotificationExpectation(name: "cargaCompletada", object: carga, notificationCenter: NotificationCenter.default)
     //carga.cargaAsync()
     let waiter = XCTWaiter()
     waiter.delegate = self
     waiter.wait(for: [expectacion], timeout: 5)
 }
 
 Con estas simples líneas ya hemos creado el test asíncrono. La primera línea genera un objeto de tipo XCTNSNotificationExpectation que es subclase del tipo XCTestExpectation que espera el framework de tests y que es el tipo que usamos para crear expectaciones. Creamos una expectación registrada a recibir el post de una notificación con el nombre "cargaCompletada" que nos llegará del propio objeto carga que estamos usando a través del NotificationCenter por defecto.

 Luego usamos la clase XCTWaiter que es la que hemos de usar desde Xcode 8.3 para obtener un funcionamiento más eficiente de los test unitarios asíncronos, y que además nos permite usar estos fuera del ámbito de una clase XCTest y que puedan lanzarse incluso desde funciones de ayuda. Instanciamos la clase, fijamos el delegate en el self de la clase y luego invocamos el método wait al que le pasamos un array de expectaciones dándole un tiempo que tendrá que esperar para que se cumplan. Nada más.

 Al ejecutarse, veremos que nos da el resultado del primer test que hicimos, al momento, pero luego el playground se queda como parado unos segundos, para luego responder el resultado (como fallo en este caso) del segundo test testWaitCargaAsync().

 Primero veremos en pantalla la siguiente información (en la consola de depuración):
 
 Test Suite 'TestCarga' started at 2020-02-04 10:43:03.970
 Test Case '-[__lldb_expr_7.TestCarga testCarga]' started.
 Test Case '-[__lldb_expr_7.TestCarga testCarga]' passed (0.012 seconds).
 
 Y tras unos segundos nos dará el resto de la información sobre el mismo, indicando que el test ha fallado.
  
 Test Case '-[__lldb_expr_7.TestCarga testWaitCargaAsync]' started.
 <unknown>:0: error: -[__lldb_expr_7.TestCarga testWaitCargaAsync] : Asynchronous wait failed: Exceeded timeout of 5 seconds, with unfulfilled expectations: "Expect notification 'cargaCompletada' from __lldb_expr_7.Carga".
 Test Case '-[__lldb_expr_7.TestCarga testWaitCargaAsync]' failed (5.028 seconds).
 Test Suite 'TestCarga' failed at 2020-02-04 10:43:09.022.
      Executed 2 tests, with 1 failure (0 unexpected) in 5.040 (5.052) seconds
 
 Como vemos claramente, el test ha fallado. Ya hemos completado el caso red. Ahora vamos a hacer que funcione. Para ello creamos una función en nuestra clase Carga que se encargue de hacer la carga asíncrona.
 
 func cargaAsync() {
     if let rutaURL = URL(string: "https://jsonplaceholder.typicode.com/users") {
         let request = URLRequest(url: rutaURL)
         let session = URLSession.shared
         let task = session.dataTask(with: request) {
             [unowned self] (data, response, error) in
             do {
                 guard let data = data, error == nil else { print(error!.localizedDescription); return }
                 self.datosAsync = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String:Any]]
                 NotificationCenter.default.post(name: NSNotification.Name(rawValue:"cargaCompletada"), object: self)
             } catch {
                 print("Fallo en la carga del JSON")
             }
         }
         task.resume()
     }
 }
 
 Esta función usa la conexión a través del gestor de red propia de Cocoa Touch, URLSession y su singleton shared, para establecer una conexión de red de tipo REST, solicitando la información de una URL que tras recuperar la información, la carga en su lugar correspondiente dentro de las propiedades de la clase. Tendríamos que poner esta llamada en el init() que hemos creado igualmente, para que la clase funcione bien.

 Pero el aislarlo tiene un motivo central, poder ejecutar el proceso de forma independiente para comprobar que todo funciona. Y si nos fijamos, tras la asignación de self.datosAsync hemos hecho una llamada al NotificationCenter.default, a través del método post para lanzar la notificación que nuestra expectación espera que se cumpla en ese lapso de 5 segundos que le hemos dado como máximo.
 
 Ahora incluimos la ejecución de este método en nuestro test, quedando este de la siguiente forma:
 
 func testWaitCargaAsync() {
     let expectacion = XCTNSNotificationExpectation(name: "cargaCompletada", object: carga, notificationCenter: NotificationCenter.default)
     carga.cargaAsync()
     let waiter = XCTWaiter()
     waiter.delegate = self
     waiter.wait(for: [expectacion], timeout: 5)
 }
 
 Ya hemos conseguido nuestro propósito. La expectación devuelve un resultado en menos de un segundo (aunque sigue siendo fuera del hilo principal de ejecución o flujo en tiempo real) y cuando esta recibe la notificación lanzada, da por correcto el test y vemos la siguiente información.
 
 Test Suite 'TestCarga' started at 2017-05-05 13:12:57.777
 Test Case '-[__lldb_expr_62.TestCarga testCarga]' started.
 Test Case '-[__lldb_expr_62.TestCarga testCarga]' passed (0.003 seconds).
 Test Case '-[__lldb_expr_62.TestCarga testWaitCargaAsync]' started.
 Test Case '-[__lldb_expr_62.TestCarga testWaitCargaAsync]' passed (0.182 seconds).
 Test Suite 'TestCarga' passed at 2017-05-05 13:12:57.965.
      Executed 2 tests, with 0 failures (0 unexpected) in 0.186 (0.188) seconds
 */



/*
 
 Test desde Playgrounds:
 
 Hemos visto cómo funcionan los test unitarios, tanto síncronos como asíncronos, con un ejemplo concreto. Pero no podemos olvidar que una cosa son los test y otra aplicar TDD, que es un paradigma de desarrollo donde en un proyecto completo estamos continuamente, primero poniendo test, probando que fallen, luego incluyendo la funcionalidad, probando que ahora los test funcionan y luego refactorizando el código para optimizar o adaptar al propio ciclo de vida de código y test.

 Al final, tenemos una forma de desarrollar que obviamente es más lenta y a veces tediosa, pero que nos garantiza algo claro: que el código que hace una cosa siempre va a seguir funcionando mientras los test sigan pasando. Es muy habitual, en proyectos grandes, que nos encontremos con casos donde alguien toca algo que arrastra o cambia una funcionalidad esencial y nadie se percata de ello porque es una parte de la app que se da por hecha y no hay nadie que vuelva a probarla.

 Si a esto le unimos métodos de integración continua que nos permiten ejecutar los test de forma periódica y automática y generar compilados cada x tiempo, tenemos un método de desarrollo mucho más eficiente que nos garantiza que nuestro proyecto va a estar estable, funcional, que no va a fallar en algo que ya funcionaba en su momento cuando se hizo (y se probó) y tenemos total garantía de estabilidad de nuestros desarrollos. Algo esencial. Y si alguien toca algo que no debe, lo sabremos al momento, en cuanto se vuelvan a lanzar los tests.
 */
