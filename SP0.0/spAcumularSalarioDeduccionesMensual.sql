USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[AcumularSalarioDeduccionesMensual]    Script Date: 17/10/2023 10:57:39 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[AcumularSalarioDeduccionesMensual]
    @outResultCode INT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Inicializa el código de resultado a 0 (sin error)
    SET @outResultCode = 0;

    BEGIN TRY
        -- Actualizar el salario bruto mensual y el total de deducciones mensuales en la tabla PlanillaMexXEmpleado
        UPDATE [dbo].[PlanillaMexXEmpleado]
        SET SalarioBrutoMensual = ISNULL((
            SELECT SUM(PSE.SalarioBrutoSemanal)
            FROM [dbo].[PlanillaSemXEmpleado] AS PSE
            WHERE PSE.EmpleadoId = [dbo].[PlanillaMexXEmpleado].EmpleadoId
                AND DATEPART(MONTH, PSE.Fecha) = DATEPART(MONTH, GETDATE())
        ), 0),
        TotalDeduccionesMensual = ISNULL((
            SELECT SUM(DE.MontoDeduccion)
            FROM [dbo].[DeduccionesEmpleado] AS DE
            WHERE DE.EmpleadoId = [dbo].[PlanillaMexXEmpleado].EmpleadoId
                AND DATEPART(MONTH, DE.Fecha) = DATEPART(MONTH, GETDATE())
        ), 0);

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
