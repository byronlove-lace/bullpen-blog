import os
from dotenv import load_dotenv
load_dotenv()

basedir = os.path.abspath(os.path.dirname(__file__))
class Config:
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.getenv("SECRET_KEY")

    # Mail Stuff
    try:
        MAIL_PORT = int(os.getenv("MAIL_PORT", 587))
    except ValueError:
        raise RuntimeError("MAIL_PORT must be an integer")
    MAIL_SERVER = os.getenv("MAIL_SERVER")
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS")
    MAIL_USERNAME = os.getenv("MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
    FLASKY_MAIL_SUBJECT_PREFIX = '[Flasky]'
    FLASKY_MAIL_SENDER = f"Flasky Admin <{MAIL_USERNAME}>"
    FLASKY_ADMIN_MAIL = os.getenv("FLASKY_ADMIN_MAIL")

    # Pages
    FLASKY_POSTS_PER_PAGE = int(os.getenv("FLASKY_POSTS_PER_PAGE", 20))

    # Build full paths to individual log files
    LOG_DIR = os.getenv("LOG_DIR", "logs")  # fallback to 'logs' if not set
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
