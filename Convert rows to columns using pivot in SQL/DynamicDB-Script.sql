USE [master]
GO
/****** Object:  Database [DynamicDB]    Script Date: 7/30/2017 9:31:38 PM ******/
CREATE DATABASE [DynamicDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DynamicDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.EPMDB\MSSQL\DATA\\DynamicDB1.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DynamicDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.EPMDB\MSSQL\DATA\\DynamicDB1_0.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [DynamicDB] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DynamicDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DynamicDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DynamicDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [DynamicDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [DynamicDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [DynamicDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [DynamicDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DynamicDB] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [DynamicDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DynamicDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DynamicDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DynamicDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DynamicDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [DynamicDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DynamicDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [DynamicDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DynamicDB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DynamicDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DynamicDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DynamicDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DynamicDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DynamicDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DynamicDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DynamicDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DynamicDB] SET RECOVERY FULL 
GO
ALTER DATABASE [DynamicDB] SET  MULTI_USER 
GO
ALTER DATABASE [DynamicDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DynamicDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DynamicDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DynamicDB] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [DynamicDB]
GO
/****** Object:  StoredProcedure [dbo].[Convert_Rows_To_Columns_ByPivot]    Script Date: 7/30/2017 9:31:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================  
-- Author:  Mohamed El-Qassas    
-- Create date:   
-- Description:  DYNAMIC PIVOT WITHOUT AGGREGATION FUNCTION  
-- =============================================  
CREATE PROCEDURE [dbo].[Convert_Rows_To_Columns_ByPivot] 
  -- Add the parameters for the stored procedure here  
  @TableID AS INT 
AS 
  BEGIN 
      -- Get a list of the "Field Value" (Rows) 
      BEGIN try 
          DROP TABLE ##dataquery 
      END try 

      BEGIN catch 
      END catch 

      CREATE TABLE ##dataquery 
        ( 
           id         INT NOT NULL, 
           tablename  VARCHAR(50) NOT NULL, 
           fieldname  VARCHAR(50) NOT NULL, 
           fieldvalue VARCHAR(50) NOT NULL 
        ); 

      INSERT INTO ##dataquery 
      SELECT Row_number() 
               OVER ( 
                 partition BY (fields.fieldname) 
                 ORDER BY fieldvalue.fieldvalue) ID, 
             tables.tablename, 
             fields.fieldname, 
             fieldvalue.fieldvalue 
      FROM   tables 
             INNER JOIN fields 
                     ON tables.tid = fields.tid 
             INNER JOIN fieldvalue 
                     ON fields.fid = fieldvalue.fid 
      WHERE  tables.tid = @TableID 

      --Get a list of the "Fields" (Columns) 
      DECLARE @DynamicColumns AS VARCHAR(max) 

      SELECT @DynamicColumns = COALESCE(@DynamicColumns + ', ', '') 
                               + Quotename(fieldname) 
      FROM   (SELECT DISTINCT fieldname 
              FROM   fields 
              WHERE  fields.tid = @TableID) AS FieldList 

      -- Alternative Method 
  /*DECLARE @DynamicColumns AS NVARCHAR(max)  
     SET @DynamicColumns= Stuff((SELECT DISTINCT'],['+fieldname FROM (SELECT  
                          fields.fieldname FieldName  
                          FROM fields WHERE (fields.tid = @TableID)) y FOR xml  
                          path(  
                          ''), type).value('.', 'VARCHAR(Max)'), 1, 2, '') +  
                          ']' */ 
      --Build the Dynamic Pivot Table Query  
      DECLARE @FinalTableStruct AS NVARCHAR(max) 

      SET @FinalTableStruct = 'SELECT ' + @DynamicColumns 
                              + 
      ' from ##DataQuery x pivot ( max( FieldValue ) for FieldName in (' 
                              + @DynamicColumns + ') ) p ' 

      EXECUTE(@FinalTableStruct) 
  END 
GO
/****** Object:  Table [dbo].[Fields]    Script Date: 7/30/2017 9:31:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Fields](
	[FID] [int] IDENTITY(1,1) NOT NULL,
	[TID] [int] NULL,
	[FieldName] [varchar](50) NULL,
 CONSTRAINT [PK_Fields] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FieldValue]    Script Date: 7/30/2017 9:31:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FieldValue](
	[FVID] [int] IDENTITY(1,1) NOT NULL,
	[FID] [int] NULL,
	[FieldValue] [nvarchar](50) NULL,
 CONSTRAINT [PK_Field Value] PRIMARY KEY CLUSTERED 
(
	[FVID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tables]    Script Date: 7/30/2017 9:31:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Tables](
	[TID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](50) NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[TID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Fields]  WITH CHECK ADD  CONSTRAINT [FK_Fields_Tables] FOREIGN KEY([TID])
REFERENCES [dbo].[Tables] ([TID])
GO
ALTER TABLE [dbo].[Fields] CHECK CONSTRAINT [FK_Fields_Tables]
GO
ALTER TABLE [dbo].[FieldValue]  WITH CHECK ADD  CONSTRAINT [FK_Field Value_Fields] FOREIGN KEY([FID])
REFERENCES [dbo].[Fields] ([FID])
GO
ALTER TABLE [dbo].[FieldValue] CHECK CONSTRAINT [FK_Field Value_Fields]
GO
USE [master]
GO
ALTER DATABASE [DynamicDB] SET  READ_WRITE 
GO
