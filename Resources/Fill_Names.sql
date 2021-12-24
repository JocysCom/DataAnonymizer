---------------------------------------------------------------
-- Insert first names from other tables.
---------------------------------------------------------------

-- Insert male first names.
INSERT INTO [Anonymous].[FirstName]([Name], [Rate], [Type])
SELECT [Male], [CountM], 'M'
FROM [Test].[dbo].[first_names_2019_by_rank]
WHERE [Male] IS NOT NULL

-- Insert female first names.
INSERT INTO [Anonymous].[FirstName]([Name], [Rate], [Type])
SELECT [Female], [CountF], 'F'
FROM [Test].[dbo].[first_names_2019_by_rank]
WHERE [Female] IS NOT NULL

-- Insert first names.
INSERT INTO [Anonymous].[FirstName]([Name], [Rate], [Type])
SELECT [Name], [Count], [Type]
FROM [US_FirstName]

---------------------------------------------------------------
-- Insert last names (surnames) from other tables.
---------------------------------------------------------------

-- Insert last names.
INSERT INTO [Anonymous].[LastName]([Name], [Rate], [Type])
SELECT [Surname], [Number], 'S'
FROM [last_names_2019_by_rank]

-- Insert last names.
INSERT INTO [Anonymous].[LastName]([Name], [Rate], [Type])
SELECT [Name], [Count], 'S'
FROM [US_Last_Names_2010_Census]

---------------------------------------------------------------
-- Fix names.
---------------------------------------------------------------

-- Trim spaces.
UPDATE [Anonymous].[FirstName] SET [Name] = LTRIM(RTRIM([Name])) WHERE [Name] <> LTRIM(RTRIM([Name]))
UPDATE [Anonymous].[LastName] SET [Name] = LTRIM(RTRIM([Name])) WHERE [Name] <> LTRIM(RTRIM([Name]))

-- Delete names, which contains non-letters.
DELETE FROM [Anonymous].[FirstName] WHERE [Name] LIKE '%[^A-Z]%'
DELETE FROM [Anonymous].[LastName]  WHERE [Name] LIKE '%[^A-Z]%'

-- Delete records with one or less letters.
DELETE FROM [Anonymous].[FirstName] WHERE LEN([Name]) <= 1
DELETE FROM [Anonymous].[LastName]  WHERE LEN([Name]) <= 1

-- Capitalize names.
UPDATE [Anonymous].[FirstName] SET
	[Name] = UPPER(LEFT([Name],1))+LOWER(SUBSTRING([Name],2,LEN([Name])))
WHERE [Name] <> UPPER(LEFT([Name],1))+LOWER(SUBSTRING([Name],2,LEN([Name]))) COLLATE Latin1_General_CS_AS

UPDATE [Anonymous].[LastName] SET
	[Name] = UPPER(LEFT([Name],1))+LOWER(SUBSTRING([Name],2,LEN([Name])))
WHERE [Name] <> UPPER(LEFT([Name],1))+LOWER(SUBSTRING([Name],2,LEN([Name]))) COLLATE Latin1_General_CS_AS

---------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------

-- Delete duplicated last names.
DELETE t1
--SELECT *
FROM (
	SELECT [Name], ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Name] ASC, [Rate] DESC) AS RowID, [Rate]
	FROM [Anonymous].[LastName]
) t1 WHERE RowID > 1

-- Delete duplicated male first names.
DELETE t1
--SELECT *
FROM (
	SELECT [Name], ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Name] ASC, [Rate] DESC) AS RowID, [Rate]
	FROM [Anonymous].[FirstName]
	WHERE [Type] = 'M'
) t1 WHERE RowID > 1

-- Delete duplicated female first names.
DELETE t1
--SELECT *
FROM (
	SELECT [Name], ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Name] ASC, [Rate] DESC) AS RowID, [Rate]
	FROM [Anonymous].[FirstName]
	WHERE [Type] = 'F'
) t1 WHERE RowID > 1

-- Delete names, which are less popular than in other gender.
DELETE t1
--SELECT *
FROM (
	SELECT [Name], ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Name] ASC, [Rate] DESC) AS RowID, [Rate], [Type]
	FROM [Anonymous].[FirstName]
) t1 WHERE RowID > 1

---------------------------------------------------------------
-- Reset first name identity column.
---------------------------------------------------------------

IF OBJECT_ID('[Anonymous].[_temp_FirstName]', 'U') IS NOT NULL 
  DROP TABLE [Anonymous].[_temp_FirstName]

-- SELECT into new table.
SELECT IDENTITY (int, 1, 1) AS Id, [Name], [Type], [Rate]
INTO [Anonymous].[_temp_FirstName]
FROM [Anonymous].[FirstName]
ORDER BY [Rate] DESC, [Name] ASC

-- Truncate original table.
TRUNCATE TABLE [Anonymous].[FirstName]

-- Reset seed.
DBCC CHECKIDENT('[Anonymous].[FirstName]', RESEED, 1)

-- Insert back.
INSERT INTO [Anonymous].[FirstName] ([Name], [Type], [Rate])
SELECT [Name], [Type], [Rate] FROM [Anonymous].[_temp_FirstName] ORDER BY Id

-- Drop temp table.
DROP TABLE [Anonymous].[_temp_FirstName]


---------------------------------------------------------------
-- Reset last name identity column.
---------------------------------------------------------------

IF OBJECT_ID('[Anonymous].[_temp_LastName]', 'U') IS NOT NULL 
  DROP TABLE [Anonymous].[_temp_LastName]

-- SELECT into new table.
SELECT IDENTITY (int, 1, 1) AS Id, [Name], [Type], [Rate]
INTO [Anonymous].[_temp_LastName]
FROM [Anonymous].[LastName]
ORDER BY [Rate] DESC, [Name] ASC

-- Truncate original table.
TRUNCATE TABLE [Anonymous].[LastName]

-- Reset seed.
DBCC CHECKIDENT('[Anonymous].[LastName]', RESEED, 1)

-- Insert back.
INSERT INTO [Anonymous].[LastName] ([Name], [Type], [Rate])
SELECT [Name], [Type], [Rate] FROM [Anonymous].[_temp_LastName] ORDER BY Id

-- Drop temp table.
DROP TABLE [Anonymous].[_temp_LastName]


---------------------------------------------------------------
-- Show results.
---------------------------------------------------------------


DECLARE @firstCount int, @lastCount int

SELECT @firstCount = COUNT(*) FROM [Anonymous].[FirstName]
SELECT @lastCount  = COUNT(*) FROM [Anonymous].[LastName]

SELECT @firstCount [FirstCount], @lastCount [LastCount]

DECLARE @firstBits int, @lastBits int, @firstTop bigint, @lastTop bigint, @uniqueCombinations bigint

SET @firstBits = LOG(@firstCount)/LOG(2)
SET @lastBits  = LOG(@lastCount)/LOG(2)
SET @firstTop = CAST(POWER(2, @firstBits) AS bigint)
SET @lastTop  = CAST(POWER(2, @lastBits) AS bigint)

SET @uniqueCombinations = @firstTop  * @lastTop

SELECT @firstBits [FirstBits], @firstTop [FirstTop], @lastBits [LastBits], @lastTop [LastTop], @uniqueCombinations [UniqueCombinations]

