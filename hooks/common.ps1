# Common utilities for hook scripts

function Invoke-Replacement {
    param(
        [string]$Text,
        [hashtable]$Answers
    )
    
    $result = $Text
    
    # Replace [[[ANS:question_id]]]
    foreach ($key in $Answers.Keys) {
        $placeholder = "[[[ANS:$key]]]"
        $result = $result -replace [regex]::Escape($placeholder), [regex]::Escape($Answers[$key])
    }
    
    # Replace [[[UUIDv4]]] with a new UUID
    while ($result.Contains("[[[UUIDv4]]]")) {
        $newUUID = [guid]::NewGuid().ToString()
        # Replace only the first occurrence
        $index = $result.IndexOf("[[[UUIDv4]]]")
        $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + "[[[UUIDv4]]]".Length)
    }
    
    # Expand environment variables like %AppData%, %USERPROFILE%, etc.
    $result = [Environment]::ExpandEnvironmentVariables($result)
    
    # Unescape \\[[[ to \[[[ and then \[[[ to [[[
    # In JSON, \\[[[ becomes \[[[ after parsing
    # We need to unescape \[[[ to [[[
    $result = $result -replace '\\(\[\[\[)', '$1'
    
    return $result
}
