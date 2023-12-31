USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[InsertarMovimientosPorDeducciones]    Script Date: 21/10/2023 1:26:11 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[InsertarMovimientosPorDeducciones]
	@inFechaCierre DATE OUTPUT,
	@inHoy DATE OUTPUT,
	@inEsDiaCierre BIT OUTPUT,
	@outResultCode INT OUTPUT
AS
BEGIN
    BEGIN TRY
        -- Evita la inclusión de filas afectadas en los resultados
        SET NOCOUNT ON

        -- Obtener la fecha de cierre desde la tabla SemanaPlanilla
        SELECT @inFechaCierre = fechaFin FROM SemanaPlanilla WHERE GETDATE() BETWEEN fechaInicio AND fechaFin

        -- Obtener la fecha actual
        SET @inHoy = GETDATE()

        -- Determinar si es el día de cierre
        IF @inHoy = @inFechaCierre
            SET @inEsDiaCierre = 1
        ELSE
            SET @inEsDiaCierre = 0

        -- Insertar movimientos por deducciones solo si es el día de cierre
        IF @inEsDiaCierre = 1
        BEGIN
            INSERT INTO MovimientoPlanilla (fecha, monto, nuevoSalarioBruto, tipoMovPlanillaId, movHorasId, movDeduccionId)
            SELECT @inHoy, 0, 0, 1, NULL, NULL -- Valores simplificados
        END

        -- Establecer el valor de @outResultCode en caso de éxito
        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            -- Si hay una transacción activa, la deshace
            ROLLBACK TRANSACTION
        END

        -- Registrar cualquier error en la tabla de errores
        INSERT INTO dbo.DBErrors (
            UserName,
            ErrorNumber,
            ErrorState,
            ErrorSeverity,
            ErrorLine,
            ErrorProcedure,
            ErrorMessage,
            ErrorDateTime
        )
        VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        )

        -- Establecer el código de resultado de error
        SET @outResultCode = 50005; -- Código de error general
    END CATCH

    -- Restaura el recuento de registros afectados en los resultados
    SET NOCOUNT OFF
END
