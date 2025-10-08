Here’s a **Markdown-style summary + key snippets** from “SharePoint Add-In — Permission XML cheat sheet” by Sumit Agrawal. (I’m preserving only short excerpts for fair use; for full text see the original link.)

---

## SharePoint Add-In — Permission XML Cheat Sheet (Summary)

This article is a compact reference for permission XML snippets you can use with SharePoint Add-Ins. It’s meant to be a developer cheat sheet, simplifying the more formal documentation. ([Medium][1])

### A) Common Scenarios

#### 1. Tenant-level access

Only tenant admins can grant this. Use the *tenant admin* SharePoint site’s `appinv.aspx` page. ([Medium][1])
Example XML for **Full Control** at tenant level:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="true">
  <AppPermissionRequest Scope="http://sharepoint/content/tenant" Right="FullControl" />
</AppPermissionRequests>
```

You can similarly use `Manage`, `Write`, or `Read` in place of `FullControl`. ([Medium][1])

---

#### 2. Site collection level

Requires being a site collection admin. Use the site collection’s `/_layouts/appinv.aspx` URL. ([Medium][1])
Example:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="true">
  <AppPermissionRequest Scope="http://sharepoint/content/sitecollection" Right="FullControl" />
</AppPermissionRequests>
```

Again, you can swap in `Manage`, `Write`, or `Read`. ([Medium][1])

---

#### 3. Web / Subsite level

You must call `appinv.aspx` from within the web (site) context, not from the site collection root. Otherwise permissions default to the root web. ([Medium][1])
Example:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="true">
  <AppPermissionRequest Scope="http://sharepoint/content/sitecollection/web" Right="FullControl" />
</AppPermissionRequests>
```

Again, replace `FullControl` with `Manage`, `Write`, or `Read` as needed. ([Medium][1])

---

#### 4. List / Library level

Invoke `appinv.aspx` in the web’s context. Use this scope:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="true">
  <AppPermissionRequest Scope="http://sharepoint/content/sitecollection/web/list" Right="FullControl" />
</AppPermissionRequests>
```

To grant to multiple lists/libraries, you must run the trust process multiple times (once per list). ([Medium][1])

---

### B) Special Scenarios

#### Search service

Search permission is special: it **cannot** use `AllowAppOnlyPolicy="true"`. You must set it to `false`, and only the `QueryAsUserIgnoreAppPrincipal` right is allowed. ([Medium][1])
Example:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="false">
  <AppPermissionRequest Scope="http://sharepoint/search" Right="QueryAsUserIgnoreAppPrincipal" />
</AppPermissionRequests>
```

---

#### Taxonomy

Only `Read` or `Write` rights are permitted. App-only policy is allowed. ([Medium][1])
Example:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="true">
  <AppPermissionRequest Scope="http://sharepoint/taxonomy" Right="Read" />
</AppPermissionRequests>
```

---

#### Business Connectivity Service (BCS)

Supports only **read** access. Example:

```xml
<AppPermissionRequests AllowAppOnlyPolicy="true">
  <AppPermissionRequest Scope="http://sharepoint/bcs/connection" Right="Read" />
</AppPermissionRequests>
```

---

### C) Understanding App-Only Policy

There are three supported policies when authenticating apps:

* **User-only policy** — SharePoint checks permissions only of the user
* **User + Add-In policy** — Both the user and the add-in principal’s permissions matter
* **Add-In-only policy** (aka *app only policy*) — Only the add-in principal’s permissions are used

Some APIs (e.g. search service) require a user context and thus cannot run under pure add-in (app only) policy. ([Medium][1])

---

If you like, I can generate a fully formatted Markdown file version (with headings, code blocks, etc.) and give you a downloadable link (e.g. via Gist or file upload). Do you want me to do that for you now?

[1]: https://medium.com/ng-sp/sharepoint-add-in-permission-xml-cheat-sheet-64b87d8d7600 "SharePoint Add-In — Permission XML cheat sheet | by Sumit Agrawal | ng-sp | Medium"
