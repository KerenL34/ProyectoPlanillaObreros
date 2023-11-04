USE Pruebas
DECLARE @xmlData XML	

-- Cargar archivos xml
SET @xmlData = (
	SELECT *
	FROM OPENROWSET(
		BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\OperacionesV2.xml',
		SINGLE_BLOB
	) AS xmlData
);

-- script de simulaci�n
DECLARE @FechaOperacionItera DATE, @FechaOperacionFinal DATE;

-- Declaraci�n de Constantes
DECLARE @IDTIPOUSUARIOEMPLEADO INT = 2;



-- Declaraci�n de tablas para Empleados y Asistencias
DECLARE @EmpleadosDelXML TABLE (
    Sec INT IDENTITY(1, 1) PRIMARY KEY,
    Nombre VARCHAR(64),
    idTipoDocumentoIdentidad INT,
    ValorDocumentoIdentidad VARCHAR(32),
    idDepartamento INT,
    idPuesto INT,
    Usuario VARCHAR(32),
    Clave VARCHAR(32)
);

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Juan P�rez', 1, '12345', 2, 3, 'juanperez', 'contrase�a1');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Mar�a Gonz�lez', 2, '67890', 1, 4, 'mariagonzalez', 'contrase�a2');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Carlos Rodr�guez', 1, '54321', 3, 2, 'carlosrodriguez', 'contrase�a3');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Ana L�pez', 2, '98765', 2, 3, 'analopez', 'contrase�a4');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Pedro Ram�rez', 1, '12345', 3, 1, 'pedroramirez', 'contrase�a5');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Laura Mart�nez', 2, '67890', 1, 4, 'lauramartinez', 'contrase�a6');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Roberto S�nchez', 1, '54321', 2, 2, 'robertosanchez', 'contrase�a7');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Luisa Garc�a', 2, '98765', 3, 1, 'luisagarcia', 'contrase�a8');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Jorge Hern�ndez', 1, '12345', 1, 4, 'jorgehernandez', 'contrase�a9');

INSERT INTO @EmpleadosDelXML (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto, Usuario, Clave)
VALUES ('Carmen Castro', 2, '67890', 3, 3, 'carmencastro', 'contrase�a10');

INSERT INTO dbo.COMEMEMIAMOR 
SELECT * FROM @EmpleadosDelXML;

DECLARE @Asistencias TABLE (
    SEC INT IDENTITY(1, 1) PRIMARY KEY,
    ValorDocIdentidadEmpleado VARCHAR(64),
    MarcaInicio DATETIME,
    MarcaFin DATETIME
);

DECLARE @OUTResult INT;

-- Obtener las fechas de operaci�n
SELECT @FechaOperacionItera = MIN(FechaOperacion), @FechaOperacionFinal = MAX(FechaOperacion)
FROM DOCUMENTOxml;

-- Bucle principal para procesar fechas de operaci�n
WHILE (@FechaOperacionItera <= @FechaOperacionFinal)
BEGIN
    -- Cargar nuevos empleados del XML
    DELETE FROM @EmpleadosDelXML;
    INSERT INTO @EmpleadosDelXML (
        Nombre,
        idTipoDocumentoIdentidad,
        ValorDocumentoIdentidad,
        idDepartamento,
        idPuesto,
        Usuario,
        Clave
    )
    SELECT
        Nombre,
        idTipoDocumentoIdentidad,
        ValorDocumentoIdentidad,
        idDepartamento,
        idPuesto,
        Usuario,
        Clave
    FROM DOCUMENTOxml
    WHERE FechaOperacion = @FechaOperacionItera;

    -- Procesar empleados
    INSERT INTO dbo.Empleado (Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto)
    SELECT Nombre, idTipoDocumentoIdentidad, ValorDocumentoIdentidad, idDepartamento, idPuesto
    FROM @EmpleadosDelXML
    ORDER BY Nombre;

    INSERT INTO dbo.Usuario (Usuario, Clave, TipoUsuario)
    SELECT Usuario, Clave, @IDTIPOUSUARIOEMPLEADO
    FROM @EmpleadosDelXML
    ORDER BY Usuario;

    -- Vinculaci�n de tablas entre Usuario y Empleado
    INSERT INTO dbo.UsuarioEmpleado (idUsuario, idEmpleado)
    SELECT U.Id, E.Id
    FROM dbo.Empleado E
    INNER JOIN @EmpleadosDelXML XML ON E.ValorDocumentoIdentidad = XML.ValorDocumentoIdentidad
    INNER JOIN dbo.Usuario U ON XML.Usuario = U.Usuario;

  -- Procesar deducciones en la tabla TipoJornada
    INSERT INTO [PlanillaObrera].[dbo].[TipoJornada] ([nombre], [fechaInicio], [fechaFin])
    SELECT XML.Nombre, XML.FechaInicio, XML.FechaFin
    FROM @EmpleadosDelXML AS XML
    WHERE FechaOperacion = @FechaOperacionItera;

    -- Procesar jornadas en la tabla Jornada
    -- Supongamos que hay una tabla llamada Jornadas con campos (nombre, horaInicio, horaFin, MarcaAsistenciaId, tipoJornadaId, SemanaPlanillaId)
    INSERT INTO [PlanillaObrera].[dbo].[Jornada] ([nombre], [horaInicio], [horaFin], [MarcaAsistenciaId], [tipoJornadaId], [SemanaPlanillaId])
    SELECT XML.Nombre, XML.HoraInicio, XML.HoraFin, XML.MarcaAsistenciaId, XML.TipoJornadaId, XML.SemanaPlanillaId
    FROM @EmpleadosDelXML AS XML
    WHERE FechaOperacion = @FechaOperacionItera;

    -- Cargar asistencias del XML
    DELETE FROM @Asistencias;
    INSERT INTO @Asistencias (ValorDocIdentidadEmpleado, MarcaInicio, MarcaFin)
    SELECT XML.TipoDocumentoIdentidad, XML.MarcaInicio, XML.MarcaFin
    FROM documentoXML
    WHERE FechaOperacion = @FechaOperacionItera;

    -- Procesar asistencias mediante el procedimiento almacenado
    EXEC SP_procesaAsistencias @Asistencias, @OUTResult OUTPUT;

    IF @OUTResult > 0
    BEGIN
        -- Manejo del error en caso de fallo en el procesamiento de asistencias
        -- Agregar c�digo de manejo de error aqu�
    END

    SET @FechaOperacionItera = DATEADD(DAY, 1, @FechaOperacionItera);
END;

-- Definici�n del procedimiento almacenado SP_procesaAsistencias
CREATE PROCEDURE SP_procesaAsistencias @Asistencias TABLE (SEC INT, ValorDocIdentidadEmpleado VARCHAR(64), MarcaInicio DATETIME, MarcaFin DATETIME), @outResult INT OUTPUT
AS
BEGIN
    -- Cuerpo del procedimiento almacenado SP_procesaAsistencias
    -- Agregar c�digo correspondiente aqu�
END;
