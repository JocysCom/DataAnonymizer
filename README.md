# Jocys.com Data Anonymizer

Anonymizing scripts for SQL Database, which allows to anonymize names or generate 5 085 974 971 unique and anonymous first/last name combinations.

## Why this tool is usefull?

You can create TEST and DEV environment from LIVE environment. You can assign anonymouse names by ID, which allows to create TEST and DEV databases with the same anonymouse users.

## Data Source

Data tables were created by merging public "National Records of Scotland" and "US Social Security Agency". It contains 31 339 first names and 162 289 last names.

## Installation

To install scripts and data, just open *.sql files with "Microsoft SQL Management Studio" in specified order and execute them on target database:

1. <b>Anonymous.FirstName.csv</b> - First Name records.
2. <b>Anonymous.LastName.csv</b> - Last Name records.
3. <b>Anonymous.FirstName.sql</b> - Creates [Anonymous]  schema, [Anonymous].[FirstName] table and imports CSV file. 
4. <b>Anonymous.LastName.sql</b> - Creates [Anonymous]  schema, [Anonymous].[LastName] table and imports CSV file.
5. <b>Anonymous.RandomizeFirstNameOrder.sql</b> - Randomizes order of first names.
6. <b>Anonymous.RandomizeLastNameOrder.sql</b> - Randomizes order of last names.
7. <b>Anonymous.GetRandomNames.sql</b> - Stored Procedure. Generates table of unique anonymous first and last names. See example below.
8. <b>Anonymous.GetFirstNameIdByIndex.sql</b> - Scalar Function. Returns Id value of [FirstName] table by index. See example below.
9. <b>Anonymous.GetLastNameIdByIndex.sql</b> - Scalar Function. Returns Id value of [LastName] table by index. See example below.

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
 (
Example 1 - getting random names.

``` SQL
-- Parameters @skip, @take, @randomized
-- Skip 50 random names, take next 100 and use randomized order (1).
EXEC [Anonymous].[GetRandomNames] 50, 100, 1
```

Example 2 - Anonymizing table:

``` SQL
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

## Anonymizing Passwords and PINs

You can use "HMAC Implementation for Microsoft SQL Server" in order to derive anonymized passwords and PINs:

https://github.com/JocysCom/ShellScripts/tree/master/Tester/Scripts/HMAC_for_SQL

- <b>Security.HMAC</b> - Implements HMAC algorithm. Supported and tested algorithms: MD2, MD4, MD5, SHA, SHA1, SHA2_256, SHA2_512.
- <b>Security.HashPassword</b> - Returns base64 string which contains random salt and password hash inside. Use SHA-256 alg
