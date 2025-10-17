import os
import json
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

basedir = os.path.abspath(os.path.dirname(__file__))

# Source KV name from params.json for single source of truth
params_path = os.path.join(basedir, "infra", "params.json")
with open(params_path, "r") as f:
    params = json.load(f)

AZURE_KEY_VAULT_NAME = params.get("keyVaultName", {}).get("value")
if not AZURE_KEY_VAULT_NAME:
    raise RuntimeError("Key Vault name not found in infra/params.json")

def get_secret(secret_name):
    key_vault_uri = f"https://{AZURE_KEY_VAULT_NAME}.vault.azure.net/"

    try:
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=key_vault_uri, credential=credential)
        return client.get_secret(secret_name).value
    except Exception as e:
        raise RuntimeError(f"Failed to retrieve {secret_name} from Key Vault: {e}")

class Config:
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.getenv("SECRET_KEY")

    # Dev/Testing Mail Stuff
    try:
       MAIL_PORT = int(os.getenv("DEV_MAIL_PORT", 587))
    except ValueError:
        raise RuntimeError("DEV_MAIL_PORT must be an integer")
    MAIL_SERVER = os.getenv("DEV_MAIL_SERVER")
    MAIL_USERNAME = os.getenv("DEV_MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("DEV_MAIL_PASSWORD")
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "true").lower() == "true"
    MAIL_USE_SSL = os.getenv("MAIL_USE_SSL", "false").lower() == "false"

    BULLPEN_MAIL_SUBJECT_PREFIX = '[Bullpen]'
    BULLPEN_MAIL_SENDER = f"Bullpen Admin <{MAIL_USERNAME}>"
    BULLPEN_ADMIN_MAIL = os.getenv("BULLPEN_ADMIN_MAIL")

    # Pages
    BULLPEN_POSTS_PER_PAGE = int(os.getenv("BULLPEN_POSTS_PER_PAGE", 20))
    BULLPEN_COMMENTS_PER_PAGE = int(os.getenv("BULLPEN_COMMENTS_PER_PAGE", 20))
    BULLPEN_FOLLOWERS_PER_PAGE = int(os.getenv("BULLPEN_FOLLOWERS_PER_PAGE", 20))

    # Cookies
    SHOW_FOLLOWED_COOKIE_AGE=int(os.getenv('SHOW_FOLLOWED_COOKIE_AGE', 2592000))

    # Build full paths to individual log files
    LOG_DIR = os.getenv("LOG_DIR", "logs")  # fallback to 'logs' if not set
    APP_LOG = os.path.join(LOG_DIR, "app.log")
    ERROR_LOG = os.path.join(LOG_DIR, "error.log")
    DEBUG_LOG = os.path.join(LOG_DIR, "debug.log")

    # Testing
    TEST_CLIENT_EMAIL=os.getenv('TEST_CLIENT_EMAIL')
    TEST_CLIENT_PASSWORD=os.getenv('TEST_CLIENT_PASSWORD')
    TEST_CLIENT_USERNAME=os.getenv('TEST_CLIENT_USERNAME')
    LOOPBACK_ADDRESS=os.getenv('LOOPBACK_ADDRESS')

    # Performance
    BULLPEN_SLOW_DB_QUERY_TIME=float(os.environ.get('BULLPEN_SLOW_DB_QUERY_TIME', 0.5))
    SQLALCHEMY_RECORD_QUERIES=os.environ.get('SQLALCHEMY_RECORD_QUERIES', "true").lower() == "true"

    @staticmethod
    def init_app(app):
        pass

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("DEV_DATABASE_URI")

class TestingConfig(Config):
    TESTING = True
    WTF_CSRF_ENABLED = False
    SQLALCHEMY_DATABASE_URI = os.environ.get("TEST_DATABASE_URI")

class ProductionConfig(Config):
    PRODUCTION = True

    SECRET_KEY = get_secret("SecretKey")

    SQLALCHEMY_DATABASE_URI = get_secret("ProdDatabaseURI")
    SERVER_NAME = os.environ.get("PROD_SERVER_NAME")

    # PROD MAIL
    MAIL_SERVER = os.getenv("PROD_MAIL_SERVER")
    MAIL_USERNAME = os.getenv("PROD_SANDBOX_MAIL_USERNAME")
    MAIL_PASSWORD= get_secret("ProdSandboxMailPassword")

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,

    'default': DevelopmentConfig
}
