import UIKit
import XCTest

/*
 Test unitarios (XCTest y TDD)
 */

/*
 Red-Green-Refactor
 
 El ciclo de trabajo de TDD se entiende como la aplicación de los citados test unitarios que prueban nuestro código, en un ciclo de trabajo que es paralelo al desarrollo de la app. Los test, para hacerlo bien, han de ir implementados y han de ser adaptados mientras hacemos la app. Nunca hay que ponerlos cuando una app ya está hecha. Para ello se usa el ciclo red-green-refactor que se compone de los siguientes pasos:
 
 Red: el test ha de fallar. Si hacemos un test que prueba una clase, hemos de comprobar que dicho test primero no funciona. Por ejemplo, si vamos a crear (como en el ejemplo que veremos más abajo) una comprobación que valide que el número de datos que se cargan es correcto, hemos de probar primero que la clase devuelve el número incorrecto de valores para que el test falle. Bien forzando que devuelva un dato erróneo o bien haciendo la prueba antes de implementar el código que recupera los datos para que devuelve que no hay datos (la mejor opción).
 
 Green: el test ha de funcionar. Una vez probamos que el test falla, implementamos la funcionalidad que queremos probar. Si queremos verificar que el número de registros de una carga es correcto, pues ahora hacemos el código que carga los datos. Volvemos a probar el test y comprobamos que este es satisfactorio.
 
 Refactor: adaptando. Se basa en que nuestro código de test tiene que adaptarse en tiempo real a cualquier cambio funcional y que, además, si podemos, hemos de optimizarlo lo más posible. Tanto el código como las pruebas. Y cuando una funcionalidad cambie, deberemos adaptar los test y empezar de nuevo desde el nivel rojo a probar, primero que falla, luego que funciona, etc…
 
 El trabajo es contínuo y en paralelo. No son dos tareas separadas, si no que hemos de trabajar con el código de nuestra app y con los test que validan su funcionalidad a la vez. Adaptando unos mientras generamos lo otro.
 
 Test básicos por prototipos
 Lo he dicho muchas veces, Playgrounds es la herramienta perfecta para todo, sobre todo si hablamos de enseñanza o pruebas. Y como no podía ser menos, también podemos hacer test con los playgrounds.

 Vamos a crear una clase que realice una carga de datos desde un fichero local y desde un JSON en red, para probar test síncronos (test que responden en tiempo real) y los asíncronos (test que prueban procesos que tardan un tiempo en comprobar si han sido o no realizados, como una carga de datos de red).

 Primero creamos la base o esqueleto de nuestra clase y del test, de la siguiente forma:
 */

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
    
    func testCarga() {
        XCTAssertEqual(carga.datos.count, 24)
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
 
 */


