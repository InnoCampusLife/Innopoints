API_VERSION = 1
URL = "/api/v#{API_VERSION}/points"
FILES_FOLDER = '/public/files'
ITEMS_IMAGE_FOLDER = '/items'
MAX_FILE_SIZE = 10000000 # 10Mb

def env_or_default(key, default)
  if ENV[key] == nil
    default
    else
      ENV[key]
  end
end

def extract_accounts_version(verbose_version)
  verbose_version = verbose_version.to_s
  version_components = verbose_version.split('.')
  version_components[0] # take only the first number of the version
end

# accounts microservice params

ACCOUNTS_HOST = env_or_default('ACCOUNTS_HOST', 'localhost')
ACCOUNTS_PORT = env_or_default('ACCOUNTS_PORT', 5000).to_i
ACCOUNTS_VERSION = extract_accounts_version(env_or_default('ACCOUNTS_VERSION', 1))

ACCOUNTS_URL = "http://#{ACCOUNTS_HOST}:#{ACCOUNTS_PORT}/api/v#{ACCOUNTS_VERSION}/accounts/"

# webhook params

WEB_HOST = env_or_default('WEB_HOST', 'localhost')
WEB_PORT = env_or_default('WEB_PORT', 5000).to_i

# database params

DB_HOST = env_or_default('DB_HOST', 'localhost')
DB_PORT = env_or_default('DB_PORT', 27017).to_i
DB_NAME = 'innopoints'

DB_URL = "#{DB_HOST}:#{DB_PORT}"

# mysql database params

MYSQL_DB_HOST = env_or_default('MYSQL_DB_HOST', 'localhost')
MYSQL_DB_PORT = env_or_default('MYSQL_DB_PORT', 3306).to_i
MYSQL_DB_NAME = 'innopoints'
MYSQL_DB_USER = 'innopoints_user'
MYSQL_DB_PASSWORD = 'innopoints2.0'

DEFAULT_LIMIT = 50
DEFAULT_SORT_ORDER = 'ASC'
DEFAULT_ITEMS_SORT_FIELD = 'title'

SERVER_ERROR_CODE = 500
CLIENT_ERROR_CODE = 400
SUCCESSFUL_RESPONSE_CODE = 200
