USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[CrearInstanciaPlanillaMesXEmpleado]    Script Date: 21/10/2023 1:26:15 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CrearInstanciaPlanillaMesXEmpleado]
	@inUltimaSemanaDelMes bit OUTPUT,
	@inFechaActual date OUTPUT,
	@insalarioBruto money,
	@intotalDeducciones money,
	@inmesPlanillaId int,
	@intipoDeduccionId int,
	@outResultCode INT OUTPUT
AS
BEGIN
    BEGIN TRY
        -- Evita la inclusión de filas afectadas en los resultados
        SET NOCOUNT ON;

        -- Obtiene la fecha actual
        SET @inFechaActual = GETDATE();
        
        -- Comprueba si es la última semana del mes
        IF DAY(@inFechaActual) + 7 > DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, @inFechaActual)))
            SET @inUltimaSemanaDelMes = 1;
        ELSE
            SET @inUltimaSemanaDelMes = 0;
        
        -- Inicia una transacción
        BEGIN TRANSACTION tCrearInstanciaSemXEmpleado;
        
        -- Si es la última semana del mes, crea las instancias de las tablas
        IF @inUltimaSemanaDelMes = 1
        BEGIN
            -- Inserta un registro en PlanillaMesXEmp
            INSERT INTO PlanillaMesXEmp (salarioBruto, totalDeducciones, mesPlanillaId, DeduccionXempXmesId)
            VALUES (@insalarioBruto, @intotalDeducciones, @inmesPlanillaId, @intipoDeduccionId);

            -- Inserta un registro en DeducXEmpXMes
            INSERT INTO DeducXEmpXMes (totalDeducciones, tipoDeduccionId)
            VALUES (@intotalDeducciones, @intipoDeduccionId);
            
            -- Registrar el evento en el registro de eventos
            INSERT INTO [dbo].[EventLog] (
                [LogDescription],
                [PosIdUser],
                [PosIP],
                [PostTime]
            )
            VALUES (
                'Creación de instancia de PlanillaMesXEmpleado',
                NULL, -- Cambiar esto al ID de usuario adecuado si es necesario
                NULL, -- Cambiar esto a la dirección IP adecuada si es necesario
                GETDATE()
            );
        END

        -- Confirma la transacción
        COMMIT TRANSACTION tCrearInstanciaSemXEmpleado;
        
        -- Restaura el recuento de registros afectados en los resultados
        SET NOCOUNT OFF;
        
        -- Establecer el valor de @outResultCode
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            -- Si hay una transacción activa, la deshace
            ROLLBACK TRANSACTION tCrearInstanciaSemXEmpleado;
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

        -- Establecer el código de resultado de error
        SET @outResultCode = 50005; -- Código de error general
    END CATCH
END
