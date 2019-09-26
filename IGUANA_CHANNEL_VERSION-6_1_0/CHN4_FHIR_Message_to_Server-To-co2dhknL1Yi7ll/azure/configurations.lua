local configs = {}

-- Azure APP Authentication
configs.CLIENT_ID = os.getenv('AZURE_SERVICE_ID') -- Application (client) ID
configs.CLIENT_SECRET = os.getenv('AZURE_SERVICE_SECRET') -- A secret string that the application uses to prove its identity when requesting a token

-- Azure Endpoints
configs.TOKEN_ENDPOINT_V2 = os.getenv('AZURE_TOKEN_ENDPOINT_V2') -- Replace {tenent_id} with Directory (tenant) ID
configs.TOKEN_ENDPOINT_V1 = os.getenv('AZURE_TOKEN_ENDPOINT_V1') -- Replace {tenent_id} with Directory (tenant) ID
configs.AZURE_RESOURCE = os.getenv('AZURE_RESOURCE')

-- API configurations
configs.ISLIVE    = true
configs.RETRY       = 2
configs.RETRYPAUSE  = 10 -- in seconds

return configs