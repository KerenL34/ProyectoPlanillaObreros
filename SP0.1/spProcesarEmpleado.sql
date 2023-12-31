USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[ProcesarEmpleado]    Script Date: 21/10/2023 1:25:54 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ProcesarEmpleado]
	@inIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @inEsPrimerEmpleado BIT;
    DECLARE @inEsUltimaSemana BIT;
    DECLARE @inFechaActual DATETIME;
    DECLARE @inUserId INT;

    DECLARE @LogDescription NVARCHAR(2000);

    -- Verificar si es el primer empleado procesado
    SELECT @inEsPrimerEmpleado = CASE
        WHEN MIN(id) = 1 THEN 1
        ELSE 0
    END
    FROM dbo.Usuario;

    -- Obtener la fecha actual
    SET @inFechaActual = GETDATE();

    -- Verificar si es la última semana del mes
    SELECT @inEsUltimaSemana = CASE
        WHEN DATEPART(week, @inFechaActual) = DATEPART(week, DATEADD(day, 7, @inFechaActual))
        AND DATEPART(month, @inFechaActual) <> DATEPART(month, DATEADD(day, 7, @inFechaActual)) THEN 1
        ELSE 0
    END;

    -- Inicializar el código de resultado
    SET @outResultCode = 0;

    BEGIN TRY
        BEGIN TRANSACTION tProcesarEmpleado;

        -- Lógica de procesamiento aquí...

        -- Registrar el evento en el registro de eventos
        INSERT INTO [dbo].[EventLog] (
            [LogDescription],
            [PosIdUser],
            [PosIP],
            [PostTime]
        )
        VALUES (
            @LogDescription,
            @inUserId,
			@inIP,
            GETDATE()
        );

        COMMIT TRANSACTION tProcesarEmpleado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION tProcesarEmpleado;
        END;

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
        );

        SET @outResultCode = 50005; -- Código de error general
    END CATCH

    SET NOCOUNT OFF;
END;
