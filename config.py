import os

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
    SQLALCHEMY_DATABASE_URI = os.environ.get("PRODUCTION_DATABASE_URI")

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,

    'default': DevelopmentConfig
}
