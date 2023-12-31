USE [PlanillaObrera]
GO
/****** Object:  StoredProcedure [dbo].[ValidarUsuario]    Script Date: 21/10/2023 6:41:12 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Crear el procedimiento almacenado
ALTER PROCEDURE [dbo].[ValidarUsuario] 
	@inNombre VARCHAR(32),
	@inClave VARCHAR(32),
	@outResultLogin INT OUTPUT,
	@outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;  -- Sin error

		-- Variables para validar el nombre y la clave
		DECLARE @inNombreValidado VARCHAR(32);
		DECLARE @inClaveValidado VARCHAR(32);

		SELECT  @inNombreValidado = U.[nombre],
				@inClaveValidado = U.[clave] 
		FROM dbo.Usuario U
		WHERE U.nombre = @inNombre 
		AND U.clave = @inClave;

		IF @inNombreValidado IS NULL OR @inClaveValidado IS NULL
		BEGIN 
			SET @outResultLogin = 1;  -- Error en la validación
		END 
		ELSE 
		BEGIN 
			SET @outResultLogin = 0;  -- Validación exitosa
		END;
	END TRY
	BEGIN CATCH
		-- Registrar errores en una tabla de errores
		INSERT INTO dbo.DBErrors	VALUES (
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
		);

		SET @outResultCode = 50005;  -- Código de error personalizado
	END CATCH

	SET NOCOUNT OFF;
END;
