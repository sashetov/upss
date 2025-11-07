# Useful PowerShell Scripts (UPSS)

## Example usage:

- search.ps1

    ```
    .\search.ps1 -SearchBaseDN "DC=your,DC=com" -LdapFilter '(cn=test)'
    Success! Found 2 object(s) matching filter '(cn=test)':

      1. Name: CN=test,OU=External Objects,OU=Accounts_Contact,DC=your,DC=com
         Type:
         ----
      2. Name: CN=Test,OU=Alias,OU=Accounts_User,DC=your,DC=com
         Type:
         ----
    ```

- getusersunder.ps1

    ```
     > .\getusersunder.ps1 -SearchBaseDN "DC=your,DC=com" -ManagerUsername manger
    Searching for root manager 'manger'...
    0
    1
    =================================================================
     Finding All Reports Under: Man, Anger(manger) (manger)
    =================================================================
    Man, Anger(manger) (manger)
    0
    1
    2
      - First1, Last1(flast1) (flast1)
    0
    1
    2
        - First2, Last2(flast2) (flast2)
    ```

- getusersfromdls.ps1

    ```
    > .\getusersfromdls.ps1 "CN=DL-Your-Team,OU=DLS,OU=Accounts,DC=your,DC=com"
    ===============================
     Analyzing Group: DL-Your-Team
    ===============================
    Owner:
      - Dan, Man(dman) (user)

    All Unique Users (Recursive) (2):
      - Dan, Man(dman)
      - Daisy, Lady(dlady)
    ```
