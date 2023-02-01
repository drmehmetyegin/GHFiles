CREATE DATABASE Manufacturer
USE Manufacturer

CREATE TABLE [dbo].[Product](
	[prod_id] INT PRIMARY KEY NOT NULL,
	[prod_name] [varchar](50) NOT NULL,
	[quantity] INT NOT NULL);
	

CREATE TABLE [dbo].[Prod_Comp](
	[prod_id] INT   NOT NULL,
	[comp_id] INT  NOT NULL,
	[quantity_comp] INT NOT NULL,
    PRIMARY KEY ([prod_id],[comp_id]));

CREATE TABLE [dbo].[Component] (
	  [comp_id] INT PRIMARY KEY,
	  [comp_name] VARCHAR(50) NOT NULL,
	  [description] VARCHAR(50),
	  [quantity_comp] INT  NOT NULL);
   

CREATE TABLE [dbo].[Comp_Supp](
	[supp_id] INT NOT NULL,
	[comp_id] DATE NOT NULL,
	[order_date] INT NOT NULL,
	[quantity] INT NOT NULL,
    PRIMARY KEY ([supp_id], [comp_id]));

CREATE TABLE [dbo].[Supplier](
	[supp_id] INT PRIMARY KEY NOT NULL,
    [supp_name] [varchar](50) NOT NULL,
    [supp_location] [varchar](50) NOT NULL,
    [supp_country] [varchar](50) NOT NULL,
	[is_active] BIT NOT NULL);
	

ALTER TABLE [dbo].[Supplier]
	  ADD CONSTRAINT supplier_status CHECK (is_active IN (0, 1, NULL));
ALTER TABLE [dbo].[Component]
	  ADD CONSTRAINT component_quantity CHECK (quantity_comp >= 0);
ALTER TABLE [dbo].[Comp_Supp]
	  ADD CONSTRAINT supplied_amount CHECK (quantity >= 0);

ALTER TABLE [dbo].[Prod_Comp]  
WITH CHECK ADD  CONSTRAINT [FK_Prod_Comp_Product] FOREIGN KEY([prod_id]) REFERENCES [dbo].[Product] ([prod_id])

ALTER TABLE [dbo].[Prod_Comp]  
WITH CHECK ADD  CONSTRAINT [FK_Prod_Comp_Component] FOREIGN KEY([comp_id]) REFERENCES [dbo].[Component] ([comp_id])

ALTER TABLE [dbo].[Comp_Supp]  
WITH CHECK ADD  CONSTRAINT [FK_Comp_Supp_Component] FOREIGN KEY([comp_id]) REFERENCES [dbo].[Component] ([comp_id])

ALTER TABLE [dbo].[Comp_Supp]  
WITH CHECK ADD  CONSTRAINT [FK_Comp_Supp_Supplier] FOREIGN KEY([supp_id]) REFERENCES [dbo].[Supplier] ([supp_id])



