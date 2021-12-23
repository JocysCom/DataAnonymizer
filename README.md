# DataAnonymizer
Anonymizing scripts, which allows to anonymize names or generate 5 085 974 971 unique and anonymous first/last name combinations.

Anonymizing scripts, which allows to anonymize names or generate 5 085 974 971 unique and anonymous first/last name combinations.

Anonymizing scrips use public databases from "National Records of Scotland" and "US Social Security Agency". It contains 31 339 first names and 162 289 last names. It allows to generate 5 085 974 971 unique and anonymous  first/last name combinations.
To install scripts and data, just open *.sql files with SQL Management Studio in specified order and execute them on target database:

1. <b>Anonymous.FirstName.csv</b> - First Name records.
2. <b>Anonymous.LastName.csv</b> - Last Name records.
3. <b>Anonymous.FirstName.sql</b> - Creates [Anonymous]  schema, [Anonymous].[FirstName] table and imports CSV file. 
4. <b>Anonymous.LastName.sql</b> - Creates [Anonymous]  schema, [Anonymous].[LastName] table and imports CSV file.
5. <b>Anonymous.RandomizeFirstNameOrder.sql</b> - Randomizes order of first names.
6. <b>Anonymous.RandomizeLastNameOrder.sql</b> - Randomizes order of last names.
7. <b>Anonymous.GetRandomNames.sql</b> - Stored Procedure. Generates table of unique anonymous first and last names. See example below.
8. <b>Anonymous.GetFirstNameIdByIndex.sql</b> - Scalar Function. Returns Id value of [FirstName] table by index. See example below.
9. <b>Anonymous.GetLastNameIdByIndex.sql</b> - Scalar Function. Returns Id value of [LastName] table by index. See example below.

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
	p.last_name  = aln.[Name]
FROM [profile] p
-- Pick anonymous first name and last name by id. Skip 100 000 anonymous names.
INNER JOIN [Anonymous].[FirstName] afn ON afn.[Order] = [Anonymous].[GetFirstNameIdByIndex](p.id + 100000, @first_name_max)
INNER JOIN [Anonymous].[LastName]  aln ON aln.[Order] = [Anonymous].[GetLastNameIdByIndex](p.id + 100000, @last_name_max)
```
