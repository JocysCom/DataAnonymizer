SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT [name] FROM sys.schemas WHERE name = N'Anonymous')
	EXEC('CREATE SCHEMA [Anonymous]');
GO

IF OBJECT_ID('[Anonymous].[FirstName]', 'U') IS NOT NULL 
  DROP TABLE [Anonymous].[FirstName]
GO

CREATE TABLE [Anonymous].[FirstName](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](20) NOT NULL,
	[Type] [varchar](1) NOT NULL,
	[Rate] [int] NOT NULL,
	[Total] [int] NOT NULL,
	[Order] [int] NOT NULL,
	CONSTRAINT [PK_FirstName] PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO

ALTER TABLE [Anonymous].[FirstName] ADD  CONSTRAINT [DF_FirstName_Total]  DEFAULT ((0)) FOR [Total]
ALTER TABLE [Anonymous].[FirstName] ADD  CONSTRAINT [DF_FirstName_Order]  DEFAULT ((0)) FOR [Order]

CREATE UNIQUE NONCLUSTERED INDEX [IX_FirstName_Order] ON [Anonymous].[FirstName] ([Order] ASC) INCLUDE ([Name], [Type], [Rate])

BULK INSERT [Anonymous].[FirstName]
FROM 'C:\Temp\Data\Anonymous.FirstName.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
