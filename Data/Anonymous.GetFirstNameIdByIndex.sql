SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('[Anonymous].[GetFirstNameIdByIndex]', 'FN') IS NOT NULL 
  DROP PROCEDURE [Anonymous].[GetFirstNameIdByIndex]
GO

CREATE FUNCTION [Anonymous].[GetFirstNameIdByIndex](
	@index int, @max int
) RETURNS INT AS
BEGIN
	/*
	-- Example:
	DECLARE @max int
	SELECT @max = MAX(Id) FROM  [Anonymous].[FirstName]
	SELECT [Anonymous].[GetFirstNameIdByIndex](202754, @max)
	SELECT [Anonymous].[GetFirstNameIdByIndex](1, @max)
	*/
	-- Make index 1 based
	DECLARE @i int = @index + @max - 1
	-- Get first name index by id. Most popular names will be on the top.
	RETURN @i % @max + 1
END
