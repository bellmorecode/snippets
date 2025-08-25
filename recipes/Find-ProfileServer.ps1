Function Find-ProfileServer ($user) {
    # Get the user profile path from the Active Directory
    $pp = (get-aduser -Identity $user -Properties profilePath).profilepath

    # Split the UNC path on backslashes and grab the third element
    $Server = ($pp.split("\"))[2]

    # Return the name of the server into the pipeline
    $Server
}
