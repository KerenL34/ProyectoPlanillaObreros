USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[InsertarMovimientoPorHoras]    Script Date: 17/10/2023 10:57:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[InsertarMovimientoPorHoras]
	@inmarcasAsistenciaId INT,
	@inmonto MONEY,
	@innuevoSalarioBruto MONEY,
	@intipoMovPlanillaId INT,
	@outResultCode INT OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRY


		INSERT INTO [dbo].[MovimientoPlanilla] (fecha, monto, nuevoSalarioBruto, tipoMovPlanillaId, movHorasId)
		VALUES (GETDATE(), @inmonto, @innuevoSalarioBruto, @intipoMovPlanillaId, NULL);


		DECLARE @inmovimientoId INT;
		SET @inmovimientoId = SCOPE_IDENTITY();

		INSERT INTO [dbo].[MovHoras] (marcasAsistenciaId)
		VALUES (@inmarcasAsistenciaId);

		UPDATE [dbo].[MovimientoPlanilla]
		SET movHorasId = @inmovimientoId
		WHERE id = @inmovimientoId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0  
		BEGIN
			ROLLBACK TRANSACTION; 
		END;

		-- Manejo de errores: Puedes personalizar esto según tus necesidades
		SET @outResultCode = 50005;

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
