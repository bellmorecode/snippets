USE [WTASFUNDS_MSCRM]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_FindUserGuid]    Script Date: 9/30/2016 12:54:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER function [dbo].[fn_FindUserGuid] ()
returns uniqueidentifier
as
begin
	declare @userGuid uniqueidentifier

	--- test whether the query is runing by priviledged user with user role of CRMReaderRole
	--- if it is dbo, we trust it as well. 
	--- There is an issue in SQL. If the user is a dbo, if it not member of any role
	-- if (is_member('CRMReaderRole') | is_member('db_owner')) = 1
	-- begin
	--	select @userGuid = cast(context_info() as uniqueidentifier)
	--end

	--if @userGuid is null
	--begin
	--	select @userGuid = s.SystemUserId
		--	from SystemUserBase s
			--where s.DomainName = SUSER_SNAME()	
	--end

	select @userGuid = SystemUserId from SystemUser where DomainName = 'WTAS\ven-sd-01'

	return @userGuid
end
GO


