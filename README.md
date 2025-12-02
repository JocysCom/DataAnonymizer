# Jocys.com Data Anonymizer

Anonymizing scripts for SQL Database, which allows to anonymize names or generate 5 085 974 971 unique and anonymous first/last name combinations.

## Why this tool is usefull?

You can create TEST and DEV database environment from LIVE database. For example, you can derive anonymous names from unique user/profile ID, which allows to create TEST and DEV databases with same non-random anonymous users.

## Data Source

Data tables were created by merging public "National Records of Scotland" and "US Social Security Agency" data. It contains 31 339 first names and 162 289 last names.

## Installation

To install scripts and data, just open Data\*.sql files with "Microsoft SQL Management Studio" in specified order and execute them on target database:

1. <b>Anonymous.FirstName.csv</b> - First Name records.
2. <b>Anonymous.LastName.csv</b> - Last Name records.
3. <b>Anonymous.FirstName.sql</b> - Creates [Anonymous]  schema, [Anonymous].[FirstName] table and imports CSV file. 
4. <b>Anonymous.LastName.sql</b> - Creates [Anonymous]  schema, [Anonymous].[LastName] table and imports CSV file.
5. <b>Anonymous.RandomizeFirstNameOrder.sql</b> - Randomizes order of first names.
6. <b>Anonymous.RandomizeLastNameOrder.sql</b> - Randomizes order of last names.
7. <b>Anonymous.GetRandomNames.sql</b> - Stored Procedure. Generates table of unique anonymous first and last names. See example below.
8. <b>Anonymous.GetFirstNameIdByIndex.sql</b> - Scalar Function. Returns Id value of [FirstName] table by index. See example below.
9. <b>Anonymous.GetLastNameIdByIndex.sql</b> - Scalar Function. Returns Id value of [LastName] table by index. See example below.

### Database Objects

<pre>
DB
├───Functions
│   ├───Anonymous.GetFirstNameIdByIndex
│   └───Anonymous.GetLastNameIdByIndex
├───Stored Procedures
│   ├───Anonymous.GetRandomNames
│   ├───Anonymous.RandomizeFirstNameOrder
│   └───Anonymous.RandomizeLastNameOrder
├───Tables
│   ├───Anonymous.FirstName
│   └───Anonymous.LastName
└───Security
    └───Anonymous
</pre>
	
## Data

Structure of [Anonymous].[FirstName] and [Anonymous].[LastName] table:

<table>
	<tr><th>Column</th><th>Type</th><th>Description</th></tr>
	<tr><td>Id</td><td>BIGINT</td><td>Identity</td></tr>
	<tr><td>Name</td><td>VARCHAR(20)</td><td>First/Last Name</td></tr>
	<tr><td>Type</td><td>VARCHAR(1)</td><td>M - Male Name, F - Female Name, S - Surname</td></tr>
	<tr><td>Rate</td><td>INT</td><td>Popularity rating (heigher value - more popular)</td></tr>
	<tr><td>Total</td><td>INT</td><td>Number of people with the name</tr>
	<tr><td>Order</td><td>INT</td><td>Randomized popularity order in batches of 1000</td></tr>
</table>

## Examples

Example 1 - getting random names.

```SQL
-- Parameters @skip, @take, @randomized
-- Skip 50 random names, take next 100 and use randomized order (1).
EXEC [Anonymous].[GetRandomNames] 50, 100, 1
```

Example 2 - anonymizing table:

```SQL
-- Declare properties to store number of available names.
DECLARE @first_name_max int, @last_name_max int

-- Count available names.
SELECT @first_name_max = COUNT(*) FROM [Anonymous].[FirstName]
SELECT @last_name_max  = COUNT(*) FROM [Anonymous].[LastName]

-- Anonymise...
UPDATE p SET
	p.first_name = afn.[Name],
	p.last_name  = aln.[Name],
	p.email = CONCAT(afn.[Name], '.', aln.[Name], '@company.com')
FROM [profile] p
-- Pick anonymous first name and last name by id. Skip 100 000 anonymous names.
INNER JOIN [Anonymous].[FirstName] afn ON afn.[Order] = [Anonymous].[GetFirstNameIdByIndex](p.id + 100000, @first_name_max)
INNER JOIN [Anonymous].[LastName]  aln ON aln.[Order] = [Anonymous].[GetLastNameIdByIndex](p.id + 100000, @last_name_max)
```

Example 3 - anonymizing very large table:
```SQL
/*
Advantages of self-adjusting batch data processing script:

	1. Script will process data in batches, which prevents long table locks.
	   It allows to process very large amounts of data with minimized impact on the system.

	2. Bach size will be auto-adjusted for best performance and execution time between 2 and 5 seconds.
	   It starts from 1000 records at the time (look for @size parameter inside the script).
	   Next batch size will be doubled if current batch action takes less than 2 seconds. 
	   Next batch size will be halved  if current batch action takes more than 5 seconds.
	   
	3. Script will report progress every 5 seconds and when finished.

	4. Batch execution time and wait time between batches can be adjusted.
*/

DECLARE
	@first_name_max int,
	@first_name_dif int = 0, -- Change number to start from different first name.
	@last_name_max int,
	@last_name_dif int = 256 -- Change number to start from different last name.

SELECT @first_name_max = COUNT(*) FROM  [Anonymous].[FirstName]
SELECT @last_name_max  = COUNT(*) FROM  [Anonymous].[LastName]

---------------------------------------------------------------
-- UPDATE the rows in a batches. This will minimize impact.
---------------------------------------------------------------
DECLARE
    @last bigint = -1,
    @done bigint = 0,
    @total bigint = 0,
    @error sysname = '',
    @reported datetime = GETDATE()

DECLARE @StartId bigint = 0

---------------------------------------------------------------
-- CUSTOMIZE: Select total records (required for percentage display).
---------------------------------------------------------------
SELECT @total = COUNT(*)
FROM [Customer].[AccountContact] WITH(NOLOCK)
WHERE 
	-- Required: Start records from specific primary Id.
	[Id] > @StartId
	-- Optional: Exclude some records below if necessary.
	AND [FirstName] <> 'Test' AND [AccountId] NOT IN (40000) 

---------------------------------------------------------------

SET @error = 'Total: ' + CAST(@total AS sysname)
RAISERROR(@error, -1, -1) WITH NOWAIT

DECLARE 
    @start datetime,
    @size bigint = 1000, -- Starting batch size.
    @minTime int = 2, -- Increase batch size if less than this time (seconds).
    @maxTime int = 5  -- Decrease batch size if more than this time (seconds).

DECLARE @BatchIds as TABLE (Id bigint PRIMARY KEY)

WHILE @last <> 0 AND @total > 0
BEGIN
    SET NOCOUNT ON

    SET @start = GETDATE()

	DELETE @BatchIds

	--------------------------------------------------------------
	-- CUSTOMIZE: Insert record IDs which must be updated.
	--------------------------------------------------------------

	INSERT INTO @BatchIds
	SELECT TOP(@size) [Id]
	FROM [Customer].[AccountContact]
	WHERE
		-- Required: Start records from specific primary Id.
		[Id] > @StartId
		-- Optional: Exclude some records below if necessary.
		AND [FirstName] <> 'Test' AND [AccountId] NOT IN (40000) 
	-- Make sure that results are ordered by Id.
	ORDER BY [Id]

	------------------------------
	-- CUSTOMIZE: Do batch action here.
    ------------------------------

	---- Anonymise table...
	UPDATE ac SET
		-- Anonymise names and email.
		ac.[FirstName]  = afn.[Name],
		ac.[MiddleName] = '',
		ac.[LastName]   = aln.[Name],
		ac.[Email] = afn.[Name] + '.' + aln.[Name] + '@anonymous.com',
		-- Anonymise other fields.
		ac.[Phone] = '02012345678',
		ac.[PhoneExtension] = '',
		ac.[Mobile] = '07012345678',
		ac.[Notes] = '',
		ac.[Title] = ''
	FROM [Customer].[AccountContact] ac
	-- Process records listed in @BatchIds.
	INNER JOIN @BatchIds bids ON bids.Id = ac.Id
	-- Pick anonymous first name and last name by id.
	INNER JOIN [Anonymous].[FirstName] afn ON afn.[Order] = [Anonymous].[GetFirstNameIdByIndex](ac.Id + @first_name_dif, @first_name_max)
	INNER JOIN [Anonymous].[LastName]  aln ON aln.[Order] = [Anonymous].[GetLastNameIdByIndex](ac.Id + @last_name_dif, @last_name_max)
	
    -----------------------------------------------------------

    -- Count selected rows.
    SET @last = @@ROWCOUNT
	-- Select record id for next time.
	SELECT @StartId = MAX(Id) FROM @BatchIds
	-- Count done records.
	SET @done = @done + @last
    
    -----------------------------------------------------------
    
    -- Double batch size if execution was too quick.
    IF DATEDIFF(SECOND, @start, GETDATE()) < @minTime
        SET @size = @size * 2
    -- Half batch size if execution was too slow.
    IF DATEDIFF(SECOND, @start, GETDATE()) > @maxTime
        SET @size = @size / 2

    IF @size < 1 SET @size = 1
         
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
```


## Anonymizing Passwords and PINs

You can use "HMAC Implementation for Microsoft SQL Server" in order to derive anonymized passwords and PINs:

https://github.com/JocysCom/ShellScripts/tree/master/Tester/Scripts/HMAC_for_SQL

- <b>Security.HMAC</b> - Implements HMAC algorithm. Supported and tested algorithms: MD2, MD4, MD5, SHA, SHA1, SHA2_256, SHA2_512.
- <b>Security.HashPassword</b> - Returns base64 string which contains random salt and password hash inside. Use SHA-256 algorithm.
- <b>Security.IsValidPassword</b> - Returns 1 if base64 string and password match. Use SHA-256 algorithm.
