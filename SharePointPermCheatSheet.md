# Some Details for manageing the Permissions for apps in SharePoint

https://tenantName-admin.sharepoint.com/_layouts/appinv.aspx

Full control at tenant level

<AppPermissionRequests AllowAppOnlyPolicy="true">
    <AppPermissionRequest Scope="http://sharepoint/content/tenant" 
     Right="FullControl" />
 </AppPermissionRequests>

Manage control at tenant level

<AppPermissionRequests AllowAppOnlyPolicy="true">  
    <AppPermissionRequest Scope="http://sharepoint/content/tenant" 
     Right="Manage" />
</AppPermissionRequests>

Similarly for Write, use Right=”Write” and for Read use Right=”Read”
Make note that Scope=”http://sharepoint/content/tenant" specifies that permission is being granted for SharePoint Product → Content meaning SharePoint content database → tenant is tenant level scope.

2) Provide access at site collection level
This needs site collection admin permissions to be able to grant access at site collection scope.
Url to be used is SiteCollectionUrl/_layouts/appinv.aspx

Eg : https://sumitagrawal.sharepoint.com/sites/dev/_layouts/appinv.aspx for granting access to sites/dev site collection.

Full control at site collection level

<AppPermissionRequests AllowAppOnlyPolicy="true">  
   <AppPermissionRequest Scope="http://sharepoint/content/sitecollection" 
    Right="FullControl" />
</AppPermissionRequests>
Manage control at site collection level

<AppPermissionRequests AllowAppOnlyPolicy="true">  
   <AppPermissionRequest Scope="http://sharepoint/content/sitecollection" 
    Right="Manage" />
</AppPermissionRequests>
Same is case for Read and Write access.
Scope definition http://sharepoint/content/sitecollection should be self explanatory now.

3) Provide access at web level/site level/sub-site level
This is bit tricky, the catch here is to invoke appinv.aspx from the Web’s context and not from the context of site collection.
For eg: https://sumitagrawal.sharepoint.com/sites/dev/subsite1/_layouts/15/appinv.aspx
Here ‘sites/dev’ is site collection and subsite1 is sub-site under this site collection.

What happens when web level access is granted from site collection url ?
In this case access is granted to root web which has same url as site collection.

Full control at web level

<AppPermissionRequests AllowAppOnlyPolicy="true">  
  <AppPermissionRequest Scope="http://sharepoint/content/sitecollection/web" 
   Right="FullControl" />
</AppPermissionRequests>
Same is case with Manage , Read and Write. Just update Right= to appropriate value.

4) Provide access to List/Library
Invoke appinv.aspx the same way as that was for web level access.
For eg : https://sumitagrawal.sharepoint.com/sites/dev/subsite1/_layouts/15/appinv.aspx


Full control to a list/library

<AppPermissionRequests AllowAppOnlyPolicy="true">  
   <AppPermissionRequest Scope="http://sharepoint/content/sitecollection/web/list" 
    Right="FullControl" />
</AppPermissionRequests>
Same is case with Manage , Read and Write. Just update Right= to appropriate value.
There is one additional step for list/library, it is to select to which list/library we want to grant access. This will be asked when we are trusting the app :

How do I grant access to multiple lists/libraries ?
You need to invoke url https://sumitagrawal.sharepoint.com/sites/dev/subsite1/_layouts/15/appinv.aspx multiple times and provide same permission XML and select different list/library each time.

B) Special scenarios
1) Provide access to search service
Search service permission is special case. Since search service crawls all the data and user should be able to see only to see the results in search result to which user has permissions, AllowAppOnlyPolicy is not valid for search permission. Also, there is only one permission scope , QueryAsUserIgnoreAppPrincipal
This permission has to be granted from the scope of tenant admin url.
eg : https://sumitagrawal-admin.sharepoint.com/_layouts/appinv.aspx

<AppPermissionRequests AllowAppOnlyPolicy="false">  
   <AppPermissionRequest Scope="http://sharepoint/search" 
    Right="QueryAsUserIgnoreAppPrincipal" />
</AppPermissionRequests>

Also notice that Product is SharePoint and now instead of content, we have search which signifies access to SharePoint search database.
There are no other permission level for search service.

2) Provide access to taxonomy
For taxonomy, only read and write permission can be granted. Taxonomy supports app only permissions.

<AppPermissionRequests AllowAppOnlyPolicy="true">  
   <AppPermissionRequest Scope="http://sharepoint/taxonomy" 
    Right="Read" />
</AppPermissionRequests>

Other possibility is Right=”Write”

3) Provide access to business connectivity service
Business Connectivity only supports read access and permission xml is :

<AppPermissionRequests AllowAppOnlyPolicy="true">  
   <AppPermissionRequest Scope="http://sharepoint/bcs/connection" 
    Right="Read" />
</AppPermissionRequests>
Apart from these, there are others like news feed, user profile, project server etc.

C) Understanding AppOnly policy
There are 3 supported policies while authenticating apps:

User-only policy: SharePoint checks only the permissions for the user

User+AddIn policy: SharePoint checks the permissions of both the user and the add-in principal

Add-in-only policy: (Also called app only policy) SharePoint checks only the permissions of the add-in principal
