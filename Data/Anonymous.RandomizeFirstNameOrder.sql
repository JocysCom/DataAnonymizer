SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('[Anonymous].[RandomizeFirstNameOrder]', 'P') IS NOT NULL 
  DROP PROCEDURE [Anonymous].[RandomizeFirstNameOrder]
GO

CREATE PROCEDURE [Anonymous].[RandomizeFirstNameOrder] 
AS

-- EXEC [Anonymous].[RandomizeFirstNameOrder]
-- SELECT TOP (10000) * FROM [Anonymous].[FirstName]

---------------------------------------------------------------
-- UPDATE rows in a batches. Most popular will stay on top.
---------------------------------------------------------------
DECLARE
    @last bigint = -1,
    @done bigint = 0,
    @total bigint = 0,
    @error sysname = '',
    @reported datetime = GETDATE()

DECLARE @StartId bigint = 0

-- Select total records to complete.
SELECT @total = COUNT(*)
FROM [Anonymous].[FirstName] p WITH(NOLOCK)

SET @error = 'Total: ' + CAST(@total AS sysname)
RAISERROR(@error, -1, -1) WITH NOWAIT

DECLARE 
    @start datetime,
    @size bigint = 1000 -- Batch size.

DECLARE @Table as TABLE (id bigint PRIMARY KEY, [order] int)

WHILE @last <> 0 AND @total > 0
BEGIN
    SET NOCOUNT ON

    SET @start = GETDATE()

    -- Do action here.
    -----------------------------------------------------------
    
 DECLARE @LastId bigint
 
 DELETE @Table

	-- Get Ids to process.
	INSERT INTO @Table(id, [order])
	SELECT TOP(@size) id, id
	FROM [Anonymous].[FirstName] T1
	WHERE T1.id >= @StartId AND T1.id < (@StartId + @size)
	ORDER BY T1.Id

	-- Randomize the order.
	;WITH Randomize AS ( 
		SELECT
			Id,
			ROW_NUMBER() OVER (ORDER BY Id) AS orig_rownum, 
			ROW_NUMBER() OVER (ORDER BY NewId()) AS new_rownum
		FROM @Table
	) 
	UPDATE T1 SET Id = T2.Id 
	FROM Randomize T1 
	JOIN Randomize T2 on T1.orig_rownum = T2.new_rownum;

	------------------------------

	---- Randomize...
	UPDATE T1 SET
		T1.[Order] = T2.[Order]
	FROM [Anonymous].[FirstName] T1
	INNER JOIN @Table T2 ON T2.id = T1.id

	
    -----------------------------------------------------------

    -- Count selected rows.
    SET @last = @@ROWCOUNT

	SET @StartId = @StartId + @size

	SET @done = @done + @last
    
    -----------------------------------------------------------

    -- Report when finished or every 5 seconds.
    IF @last = 0 OR @last > 0 AND DATEDIFF(SECOND, @reported, GETDATE()) > 5
    BEGIN
        SET @reported = GETDATE()
        SET @error =
            FORMAT(@reported,'yyyy-MM-dd HH:mm:ss') +
            ' | Done: '    + RIGHT(CAST('' AS CHAR(26)) + FORMAT(@done, '#,##0'), LEN(@total)) +
            ' | Size: '    + RIGHT(CAST('' AS CHAR(26)) + FORMAT(@size, '#,##0'), LEN(@total)) +
            ' | Last: '    + RIGHT(CAST('' AS CHAR(26)) + FORMAT(@last, '#,##0'), LEN(@total)) +
            ' | Percent: ' + RIGHT(CAST('' AS CHAR(26)) + FORMAT(@done * 100 / CAST(@total AS money), '#,##0.00'), 7)
        RAISERROR(@error, -1, -1) WITH NOWAIT
    END
    
    -- Delay next action for 250 ms.
    WAITFOR DELAY '00:00:00.250'
    
    SET NOCOUNT OFF

END
