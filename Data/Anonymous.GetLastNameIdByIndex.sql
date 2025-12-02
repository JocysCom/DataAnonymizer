SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('[Anonymous].[GetLastNameIdByIndex]', 'FN') IS NOT NULL 
  DROP FUNCTION [Anonymous].[GetLastNameIdByIndex]
GO

CREATE FUNCTION [Anonymous].[GetLastNameIdByIndex](
	@index bigint, @max int
) RETURNS INT AS
BEGIN
	/*
	-- Example:
	DECLARE @max int
	SELECT @max = MAX(Id) FROM  [Anonymous].[LastName]
	SELECT [Anonymous].[GetLastNameIdByIndex](202754, @max)
	SELECT [Anonymous].[GetLastNameIdByIndex](1, @max)
	*/
	-- Make index 1 based
	DECLARE @i bigint = @index + @max - 1
	-- Get last name index by id. Most popular names will be on the top.
	RETURN (@i + (@index / @max)) % @max + 1
END
