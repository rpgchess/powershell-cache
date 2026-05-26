@{
    # Cache Module - Dependencies
    # This file specifies the required modules for development and testing
    
    PSDependencies = @{
        Pester = @{
            Version = '5.5.0'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
        }
        
        PSScriptAnalyzer = @{
            Version = '1.21.0'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
        }
    }
}
