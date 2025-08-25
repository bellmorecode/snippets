--select name from sys.tables

-- Create Table FutureEmails
-- (
    -- Id uniqueidentifier Primary Key default newid(),
    -- FromAddress nvarchar(max) null,
    -- ToAddress nvarchar(max) null,
    -- CCAddress nvarchar(max) null,
    -- BccAddress nvarchar(max) null,

    -- [Subject] nvarchar(max) null,
    -- [MessageContent] nvarchar(max) null,
    -- [MessageType] nvarchar(max) null,
    -- [IsHighPriority] bit null,
    
    -- RequestedDeliveryDate datetime2 null,
    -- IsProcessed bit null, 
    -- IsCancelled bit null, 
    -- StatusMessage nvarchar(max) null
-- )

-- new column.
-- alter table [FutureEmails] add [SendClicked] bit null
-- alter table [FutureEmails] add [RequestCreateDate] datetime2 null


insert into [FutureEmails]
([FromAddress], [ToAddress], [BccAddress], [Subject], [MessageContent], [MessageType], [RequestedDeliveryDate], [StatusMessage], RequestCreateDate)
values 
('support@gfdata.io', 'future-emails@gfdata.io', 'future-emails@gfdata.io', 'Test Email Subject 3', '<p>Test Email Message 3</p>', 'Html', '2019-11-15', 'New', GETUTCDate())


select * from [FutureEmails]
