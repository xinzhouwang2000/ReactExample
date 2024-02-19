// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 *  El contrato Asignatura que representa una asignatura de la carrera.
 * 
 * Version Lite - Practicas
 * 
 * Posibles modificaciones:
 *  - Gestionar el limite de los puntos que aporta cada evaluacion.
 *  - ¿Puede repetirse el nombre de una evaluacion?
 *  - Cambiar algunos uint a uint8 ??
 *  - Nota minima en las evaluaciones?
 *  - Evaluacion obligatoria u opcional?
 *  - Nota final en la asignatura.
 *  - Evaluacion continua, final, extraordinaria, ....
 *  - ¿Un alumno puede ser el owner, el coordinador o un profesor?
 *  - Un profesor si puede ser el coordinador.
 */
 
 contract Asignatura {

     event Tic(string msg, address account, uint8 out);

     /// Version 2022 Lite - Teoria
    string public version = "2022 Lite";

    /**
     * address del profesor que ha desplegado el contrato.
     * El contrato lo despliega el profesor.
     */
    address public profesor;
    
    /// Nombre de la asignatura
    string public nombre;
    
    /// Curso academico
    string public curso;
    
    /// Datos de un alumno.
    struct DatosAlumno {
        string nombre;
        string email;
    }
    
    /// Acceder a los datos de un alumno dada su direccion.
    mapping (address => DatosAlumno) public datosAlumno;
    
    // Array con las direcciones de los alumnos matriculados.
    address[] public matriculas;
    
    /**
     * Datos de una evaluacion.
     */
    struct Evaluacion {
        string nombre;
        uint fecha;
        uint porcentaje;
    }
    
    /// Evaluaciones de la asignatura.
    Evaluacion[] public evaluaciones;
        
    /// Tipos de notas: sin usar, no presentado, y nota normal entre 0 y 1000.
    enum TipoNota {Empty, NP, Normal}
    
    /**
     * Datos de una nota.
     * La calificacion esta multiplicada por 100 porque no hay decimales.
     */
    struct Nota {
        TipoNota tipo;
        uint calificacion;
    }
    
    // Dada la direccion de un alumno, y el indice de la evaluacion, devuelve
    // la nota del alumno.
    mapping (address => mapping (uint => Nota)) public calificaciones;

    
     /**
     * Constructor.
     * 
     * @param _nombre Nombre de la asignatura.
     * @param _curso  Curso academico.
     */
    constructor(string memory _nombre, string memory _curso) {
        require(bytes(_nombre).length != 0, "El nombre de la asignatura no puede ser vacio");
        require(bytes(_curso).length != 0, "El curso academico de la asignatura no puede ser vacio");
      
        profesor = msg.sender;
        nombre = _nombre;
        curso = _curso;
    }
    
    
    /**
     * Los alumnos pueden automatricularse con el metodo automatricula.
     * 
     * Impedir que se pueda meter un nombre vacio.
     * 
     * @param _nombre El nombre del alumno. 
     * @param _email  El email del alumno.
     */
    function automatricula(string memory _nombre, string memory _email) soloNoMatriculados public {
        require(bytes(_nombre).length != 0, "El nombre no puede ser vacio");

        DatosAlumno memory datos = DatosAlumno(_nombre, _email);

        datosAlumno[msg.sender] = datos;

        matriculas.push(msg.sender);
    }

    /**
     * El numero de alumnos matriculados.
     *
     * @return El numero de alumnos matriculados.
     */
    function matriculasLength() public view returns(uint) {
        return matriculas.length;
    }
    
    /**
     * Permite a un alumno obtener sus propios datos.
     * 
     * @return _nombre El nombre del alumno que invoca el metodo.
     * @return _email  El email del alumno que invoca el metodo.
     */
    function quienSoy() soloMatriculados public view returns (string memory _nombre, string memory _email) {
        DatosAlumno memory datos = datosAlumno[msg.sender];
        _nombre = datos.nombre;
        _email = datos.email;
    }
    
    /**
     * Crear una prueba de evaluacion de la asignatura. Por ejemplo, el primer parcial, o la practica 3. 
     *
     * Las evaluaciones se meteran en el array evaluaciones, y nos referiremos a ellas por su posicion en el array.
     * 
     * @param _nombre El nombre de la evaluacion.
     * @param _fecha  La fecha de evaluacion (segundos desde el 1/1/1970).
     * @param _porcentaje El porcentaje de puntos que proporciona a la nota final.
     *
     * @return La posicion en el array evaluaciones,
     */
    function creaEvaluacion(string memory _nombre, uint _fecha, uint _porcentaje) soloProfesor  public returns (uint) {
        require(bytes(_nombre).length != 0, "El nombre de la evaluacion no puede ser vacio");
        
        evaluaciones.push(Evaluacion(_nombre, _fecha, _porcentaje));
        return evaluaciones.length - 1;
    }
    
    /**
     * El numero de evaluaciones creadas.
     *
     * @return El numero de evaluaciones creadas.
     */
    function evaluacionesLength() public view returns(uint) {
        return evaluaciones.length;
    }
    
    /**
     * Poner la nota de un alumno en una evaluacion.
     * 
     * @param alumno        La direccion del alumno.
     * @param evaluacion    El indice de una evaluacion en el array evaluaciones.
     * @param tipo          Tipo de nota.
     * @param calificacion  La calificacion, multipilicada por 100 porque no hay decimales.
     */
    function califica(address alumno, uint evaluacion, TipoNota tipo, uint calificacion) soloProfesor public {
        require(estaMatriculado(alumno), "Solo se pueden calificar a un alumno matriculado.");
        require(evaluacion < evaluaciones.length, "No se puede calificar una evaluacion que no existe.");
        require(calificacion <= 1000, "No se puede calificar con una nota superior a la maxima permitida.");

        emit Tic("He calificado", alumno, 55);

        Nota memory nota = Nota(tipo, calificacion);
        
        calificaciones[alumno][evaluacion] = nota;
    }
    
    /**
     * Devuelve el tipo de nota y la calificacion que ha sacado el alumno que invoca el metodo en la evaluacion pasada como parametro.
     * 
     * @param evaluacion Indice de una evaluacion en el array de evaluaciones.
     * 
     * @return tipo         El tipo de nota que ha sacado el alumno.
     * @return calificacion La calificacion que ha sacado el alumno.
     */ 
    function miNota(uint evaluacion) soloMatriculados public view returns (TipoNota tipo, uint calificacion) {
        require(evaluacion < evaluaciones.length, "El indice de la evaluacion no existe.");
        
        Nota memory nota = calificaciones[msg.sender][evaluacion];
        
        tipo = nota.tipo;
        calificacion = nota.calificacion;
    }

   /**
     * Consulta si una direccion pertenece a un alumno matriculado.
     * 
     * @param alumno La direccion de un alumno.
     * 
     * @return true si es una alumno matriculado.
     */
    function estaMatriculado(address alumno) private view returns (bool) {
        string memory _nombre = datosAlumno[alumno].nombre;
        
        return bytes(_nombre).length != 0;
    } 
    
    /**
     * Modificador para que una funcion solo la pueda ejecutar el profesor.
     * 
     * Se usa en creaEvaluacion y en califica.
     */
    modifier soloProfesor() {
        require(msg.sender == profesor, "Solo permitido al profesor");
        _;
    }
    
    /**
     * Modificador para que una funcion solo la pueda ejecutar un alumno matriculado.
     */
    modifier soloMatriculados() {
        require(estaMatriculado(msg.sender), "Solo permitido a alumnos matriculados");
        _;
    }
    
    /**
     * Modificador para que una funcion solo la pueda ejecutar un alumno no matriculado aun.
     */
    modifier soloNoMatriculados() {
        require(!estaMatriculado(msg.sender), "Solo permitido a alumnos no matriculados");
        _;
    }
    
    /**
     * No se permite la recepcion de dinero.
     */
    receive() external payable {
        revert("No se permite la recepcion de dinero.");
    }
 }
 