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
