SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT [name] FROM sys.schemas WHERE name = N'Anonymous')
	EXEC('CREATE SCHEMA [Anonymous]');
GO

IF OBJECT_ID('[Anonymous].[LastName]', 'U') IS NOT NULL 
  DROP TABLE [Anonymous].[LastName]
GO

CREATE TABLE [Anonymous].[LastName](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](20) NOT NULL,
	[Type] [varchar](1) NOT NULL,
	[Rate] [int] NOT NULL,
	[Total] [int] NOT NULL,
	[Order] [int] NOT NULL,
	CONSTRAINT [PK_LastName] PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO

ALTER TABLE [Anonymous].[LastName] ADD  CONSTRAINT [DF_LastName_Total]  DEFAULT ((0)) FOR [Total]
ALTER TABLE [Anonymous].[LastName] ADD  CONSTRAINT [DF_LastName_Order]  DEFAULT ((0)) FOR [Order]

CREATE UNIQUE NONCLUSTERED INDEX [IX_LastName_Order] ON [Anonymous].[LastName] ([Order] ASC) INCLUDE ([Name], [Type], [Rate])

BULK INSERT [Anonymous].[LastName]
FROM 'C:\Temp\Data\Anonymous.LastName.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
