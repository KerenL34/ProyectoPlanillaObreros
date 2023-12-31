USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[AcumularDeduccionesXEmpleadoxMes]    Script Date: 23/10/2023 9:43:57 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Crear el nuevo procedimiento almacenado
ALTER PROCEDURE [dbo].[AcumularDeduccionesXEmpleadoxMes]
    @outResultCode INT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Inicializa el código de resultado a 0 (sin error)
    SET @outResultCode = 0;

    BEGIN TRY


        -- Crear una tabla temporal para almacenar los resultados
        CREATE TABLE #TempResult (
            EmpleadoId INT,
            TipoDeduccionId INT,
            MontoTotalDeducciones DECIMAL(10, 2)
        );

        -- Insertar los totales de deducciones por tipo de deducción y empleado en la tabla temporal
        INSERT INTO #TempResult (EmpleadoId, TipoDeduccionId, MontoTotalDeducciones)
        SELECT
            DE.EmpleadoId,
            DE.TipoDeduccionId,
            SUM(DE.MontoDeduccion)
        FROM [dbo].[DeduccionesEmpleado] AS DE
        WHERE
            DATEPART(MONTH, DE.Fecha) = DATEPART(MONTH, GETDATE())
        GROUP BY DE.EmpleadoId, DE.TipoDeduccionId;

        -- Actualizar la tabla DeduccionesXEmpleadoxMes con los totales acumulados
        UPDATE DXE
        SET DXE.MontoTotalDeducciones = ISNULL(
            TR.MontoTotalDeducciones, 0
        )
        FROM [dbo].[DeduccionesXEmpleadoxMes] AS DXE
        LEFT JOIN #TempResult AS TR ON
        DXE.EmpleadoId = TR.EmpleadoId AND DXE.TipoDeduccionId = TR.TipoDeduccionId;

        -- Eliminar la tabla temporal
        DROP TABLE #TempResult;

		        -- Registrar el evento en el registro de eventos
        INSERT INTO [dbo].[EventLog] (
            [LogDescription],
            [PosIdUser],
            [PosIP],
            [PostTime]
        )
        VALUES (
            'DeduccionesXEmpleadoxMes',
            NULL, -- Cambiar esto al ID de usuario adecuado si es necesario
            NULL, -- Cambiar esto a la dirección IP adecuada si es necesario
            GETDATE()
        );

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0  -- error ocurrió dentro de la transacción
        BEGIN
            ROLLBACK TRANSACTION; -- deshacer los cambios realizados
        END;

        -- Manejo de errores: Puedes personalizar esto según tus necesidades
        SET @outResultCode = 50000; -- Código de resultado personalizado en caso de error

        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
    END CATCH

    SET NOCOUNT OFF;
END;
