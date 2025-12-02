SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('[Anonymous].[GetRandomNames]', 'P') IS NOT NULL 
  DROP PROCEDURE [Anonymous].[GetRandomNames]
GO

CREATE PROCEDURE [Anonymous].[GetRandomNames]
	@skip bigint,
	@take bigint,
	@randomized bit = 0
AS

/*
	-- Parameters @skip, @take, @randomized
	-- Skip 50 random names, take next 100 and use randomized order (1).
	EXEC [Anonymous].[GetRandomNames] 50, 100, 1
	--
	EXEC [Anonymous].[GetRandomNames] 0, 100, 0
	EXEC [Anonymous].[GetRandomNames] 0, 100, 1
	EXEC [Anonymous].[GetRandomNames] 4, 32000, 1
*/

-- Set NOCOUNT ON because billions of records could be inserted into a small temp table.
SET NOCOUNT ON

DECLARE
	@first_name nvarchar(128),
	@first_name_max_id int,
	@first_name_max_total int,
	@last_name nvarchar(128),
	@last_name_max_id int,
	@last_name_max_total int

SELECT @first_name_max_id = MAX(Id) FROM  [Anonymous].[FirstName]
SELECT @last_name_max_id  = COUNT(Id) FROM  [Anonymous].[LastName]
SELECT @first_name_max_total = MAX(Total) FROM  [Anonymous].[FirstName]
SELECT @last_name_max_total  = COUNT(Total) FROM  [Anonymous].[LastName]

---------------------------------------------------------------
-- Create temp table for name indexes.
---------------------------------------------------------------

DECLARE
	@f int = 1,
	@l int = 1,
	@fmax int = @first_name_max_id,
	@lmax int = @last_name_max_id,
	@t bigint = @skip,
	@fi int,
	@li int

DECLARE @tmp_table AS TABLE (id bigint PRIMARY KEY, f int, l int, d int)

-- Fill table with all posible variations.
WHILE @l <= @lmax AND @t < (@skip + @take)
BEGIN
	SET @f = 1
	WHILE @f <= @fmax AND @t < (@skip + @take)
	BEGIN
		SET @t = @t + 1
		SET @fi = [Anonymous].[GetFirstNameIdByIndex](@t, @first_name_max_id)
		SET @li = [Anonymous].[GetLastNameIdByIndex](@t, @last_name_max_id)
		INSERT INTO @tmp_table
		-- Delta will be used to order most popular names and surnames on top.
		SELECT @t, @fi, @li, ABS(@fi - @li)
		--PRINT @t
		SET @f = @f + 1
	END
	SET @l = @l + 1
END

IF @randomized = 1
BEGIN
	SELECT
		t.id,
		t.F,
		t.L,
		fn.[Name] AS FirstName,
		ln.[Name] AS LastName,
		fn.[Type]
	FROM @tmp_table t
	-- Select radomized in batches of 1000
	INNER JOIN [Anonymous].[FirstName] fn (NOLOCK) ON fn.[Order] = t.F
	INNER JOIN [Anonymous].[LastName] ln (NOLOCK) ON ln.[Order] = t.L
	ORDER BY t.id
END
ELSE
BEGIN
	SELECT
		t.id,
		t.F,
		t.L,
		fn.[Name] AS FirstName,
		ln.[Name] AS LastName,
		fn.[Type]
	FROM @tmp_table t
	-- Select non radomized.
	INNER JOIN [Anonymous].[FirstName] fn (NOLOCK) ON fn.Id = t.F
	INNER JOIN [Anonymous].[LastName] ln (NOLOCK) ON ln.Id = t.L
	ORDER BY t.id
END
GO
