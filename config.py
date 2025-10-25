import os

basedir = os.path.abspath(os.path.dirname(__file__))

class Config:
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.getenv("DEV_SECRET_KEY")

    # Dev/Testing Mail Stuff
    MAIL_PORT = int(os.getenv("DEV_MAIL_PORT", 587))
    MAIL_SERVER = os.getenv("DEV_MAIL_SERVER")
    MAIL_USERNAME = os.getenv("DEV_MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("DEV_MAIL_PASSWORD")
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "true").lower() == "true"
    MAIL_USE_SSL = os.getenv("MAIL_USE_SSL", "false").lower() == "true"

    MAIL_SUBJECT_PREFIX = '[Bullpen]'
    MAIL_SENDER = f"Bullpen Blog <{MAIL_USERNAME}>"
    ADMIN_MAIL = os.getenv("ADMIN_MAIL")

    # Pages
    POSTS_PER_PAGE = int(os.getenv("POSTS_PER_PAGE", 20))
    COMMENTS_PER_PAGE = int(os.getenv("COMMENTS_PER_PAGE", 20))
    FOLLOWERS_PER_PAGE = int(os.getenv("FOLLOWERS_PER_PAGE", 20))

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
    SLOW_DB_QUERY_TIME=float(os.getenv('SLOW_DB_QUERY_TIME', 0.5))
    SQLALCHEMY_RECORD_QUERIES=os.getenv('SQLALCHEMY_RECORD_QUERIES', "true").lower() == "true"

    @classmethod
    def init_app(cls, app):
        pass

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.getenv("DEV_DATABASE_URI")

class TestingConfig(Config):
    TESTING = True
    WTF_CSRF_ENABLED = False
    SQLALCHEMY_DATABASE_URI = os.getenv("TEST_DATABASE_URI")

class ProductionConfig(Config):
    PRODUCTION = True

    SECRET_KEY = os.getenv('PROD_SECRET_KEY')

    SQLALCHEMY_DATABASE_URI = os.getenv('PROD_DB_URI')
    SERVER_NAME = os.getenv("PROD_WEBAPP_HOSTNAME")

    # PROD MAIL
    MAIL_SERVER = os.getenv("PROD_MAIL_SERVER")
    MAIL_USERNAME = os.getenv("PROD_MAIL_LOGIN")
    MAIL_PASSWORD= os.getenv('PROD_MAIL_PASSWORD')
    MAIL_SENDER = f"Bullpen Blog <{MAIL_USERNAME}>"

    @classmethod
    def init_app(cls, app):
        from werkzeug.middleware.proxy_fix import ProxyFix

        app.wsgi_app = ProxyFix(app.wsgi_app)

class DockerConfig(ProductionConfig):
    @classmethod
    def init_app(cls, app):
        ProductionConfig.init_app(app)

        # log to stderr
        import logging
        from logging import StreamHandler
        file_handler = StreamHandler()
        file_handler.setLevel(logging.INFO)
        app.logger.addHandler(file_handler)

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'docker': DockerConfig,

    'default': DevelopmentConfig
}
