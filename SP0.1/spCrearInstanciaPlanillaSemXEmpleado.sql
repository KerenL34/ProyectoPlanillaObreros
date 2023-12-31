USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[CrearInstanciaSemXEmpleado]    Script Date: 21/10/2023 1:26:13 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[CrearInstanciaPlanillaSemXEmpleado]    Script Date: 20/10/2023 10:30:46 p. m. ******/


ALTER PROCEDURE [dbo].[CrearInstanciaSemXEmpleado]
	@outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si la tabla PlanillaSemXEmp ya existe y, si es así, eliminarla
    IF OBJECT_ID('dbo.PlanillaSemXEmp', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.PlanillaSemXEmp;
    END

    -- Crear la tabla PlanillaSemXEmp con los acumuladores en cero
    CREATE TABLE dbo.PlanillaSemXEmp (
        id INT IDENTITY(1, 1) NOT NULL,
        salarioNeto MONEY NOT NULL DEFAULT 0,
        movPlanillaId INT NOT NULL DEFAULT 0,
        semanaPlanillaId INT NOT NULL,
        planillaMesXempId INT NOT NULL,
        salarioBruto MONEY NOT NULL DEFAULT 0,
        totalDeducciones MONEY NOT NULL DEFAULT 0,
        CONSTRAINT PK_PlanillaSemXEmp PRIMARY KEY CLUSTERED (id ASC)
    ) ON [PRIMARY];

    -- Insertar valores iniciales en la tabla PlanillaSemXEmp si es necesario
    INSERT INTO dbo.PlanillaSemXEmp (salarioNeto, movPlanillaId, semanaPlanillaId, planillaMesXempId, salarioBruto, totalDeducciones)
    VALUES (0, 0, 0, 0, 0, 0);

    -- Establecer el valor de @outResultCode
    SET @outResultCode = 0;

    BEGIN TRY
        BEGIN TRANSACTION tCrearInstanciaSemXEmpleado;

        -- Registrar el evento en el registro de eventos
        INSERT INTO [dbo].[EventLog] (
            [LogDescription],
            [PosIdUser],
            [PosIP],
            [PostTime]
        )
        VALUES (
            'Creación de instancia de PlanillaSemXEmpleado',
            NULL, -- Cambiar esto al ID de usuario adecuado si es necesario
            NULL, -- Cambiar esto a la dirección IP adecuada si es necesario
            GETDATE()
        );

        COMMIT TRANSACTION tCrearInstanciaSemXEmpleado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
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

        SET @outResultCode = 50005; -- Código de error general
    END CATCH

    SET NOCOUNT OFF;
END;
