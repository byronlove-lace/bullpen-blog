import os
from dotenv import load_dotenv
load_dotenv()

basedir = os.path.abspath(os.path.dirname(__file__))
class Config:
    try: 
        MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))
    except ValueError:
        raise RuntimeError("MAIL_PORT must be an integer")
    SECRET_KEY = os.getenv("SECRET_KEY")
    MAIL_SERVER = os.getenv("MAIL_SERVER")
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS")
    MAIL_USERNAME = os.getenv("MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
    FLASKY_MAIL_SUBJECT_PREFIX = '[Flasky]'
    FLASKY_MAIL_SENDER = f"Flasky Admin <{MAIL_USERNAME}>"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    LOG_DIR = os.getenv("LOG_DIR", "logs")  # fallback to 'logs' if not set

# Build full paths to individual log files
    APP_LOG = os.path.join(LOG_DIR, "app.log")
    ERROR_LOG = os.path.join(LOG_DIR, "error.log")
    DEBUG_LOG = os.path.join(LOG_DIR, "debug.log")

    @staticmethod
    def init_app(app):
        pass
    
class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("DEV_DATABASE_URI")

class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("TEST_DATABASE_URI")

class ProductionConfig(Config):
    PRODUCTION = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("PRODUCTION_DATABASE_URI")

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,

    'default': DevelopmentConfig
}
