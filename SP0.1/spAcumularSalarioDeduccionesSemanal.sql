USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[AcumularSalarioDeduccionesSemanal]    Script Date: 17/10/2023 10:57:40 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[AcumularSalarioDeduccionesSemanal]
    @outResultCode INT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Inicializa el código de resultado a 0 (sin error)
    SET @outResultCode = 0;

    BEGIN TRY
        -- Inicia código en el cual se capturan errores

        -- Actualizar el salario bruto semanal y el total de deducciones semanales en la tabla PlanillaSemXEmpleado
        UPDATE PSE
        SET PSE.SalarioBrutoSemanal = ISNULL((
            SELECT SUM(Monto)
            FROM [dbo].[MovimientoPlanilla]
            WHERE EmpleadoId = PSE.EmpleadoId
                AND DATEPART(WEEK, fecha) = DATEPART(WEEK, GETDATE())
        ), 0),
        PSE.TotalDeduccionesSemanal = ISNULL((
            SELECT SUM(MontoDeduccion)
            FROM [dbo].[DeduccionesEmpleado]
            WHERE EmpleadoId = PSE.EmpleadoId
                AND DATEPART(WEEK, fecha) = DATEPART(WEEK, GETDATE())
        ), 0)
        FROM [dbo].[PlanillaSemXEmpleado] AS PSE;
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
