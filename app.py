import os
from datetime import datetime, timezone
from threading import Thread

from dotenv import load_dotenv
from flask import (Flask, abort, flash, make_response, redirect,
                   render_template, request, session, url_for)
from flask_bootstrap import Bootstrap
from flask_mail import Mail, Message
from flask_migrate import Migrate
from flask_moment import Moment
from flask_sqlalchemy import SQLAlchemy
from flask_wtf import FlaskForm
from loguru import logger
from wtforms import PasswordField, StringField, SubmitField
from wtforms.validators import DataRequired, Length

basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__)

# Log to a file with rotation and retention
logger.add(
    "logs/app.log",
    rotation="10 MB",         # new file when it exceeds 10MB
    retention="7 days",       # keep logs for 7 days
    compression="zip"         # compress old logs
)

# Log to another file at ERROR level only
logger.add("logs/errors.log", level="ERROR")
logger.add("logs/debug.log", level="DEBUG")

load_dotenv()
SECRET_KEY = os.getenv('SECRET_KEY')
app.secret_key = SECRET_KEY

DATABASE_URI = os.getenv('DATABASE_URI')
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URI
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

try: 
    MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))
except ValueError:
        raise RuntimeError("MAIL_PORT must be an integer")

app.config.update(
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_PORT=MAIL_PORT,
    MAIL_USE_TLS=os.getenv("MAIL_USE_TLS") == 'true',
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD")
)

app.config['FLASKY_MAIL_SUBJECT_PREFIX'] = '[Flasky]'
app.config['FLASK_MAIL_SENDER'] = 'Flasky Admin <jewell68@ethereal.email>'
app.config['FLASKY_ADMIN_MAIL'] = os.getenv('FLASKY_ADMIN_MAIL')


migrate = Migrate(app, db)
mail = Mail(app)

Bootstrap(app)
Moment(app)

class NameForm(FlaskForm):
    name = StringField('What is your name?', validators=[DataRequired()])
    secret = PasswordField('Tell me your secret.', validators=[DataRequired(), Length(6)])
    submit = SubmitField('Submit')

class Role(db.Model):
    __tablename__ = 'roles'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(64), unique=True)
    users = db.relationship('User', backref='role', lazy='dynamic')

    def __init__(self, name):
        self.name = name 

    def __repr__(self):
        return '<Role {!r}>'.format(self.name)

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, index=True)
    role_id = db.Column(db.Integer, db.ForeignKey('roles.id'))

    def __init__(self, username):
        self.username = username 

    def __repr__(self):
        return '<User {!r}>'.format(self.username)

@app.shell_context_processor
def make_shell_context():
    return dict(db=db, User=User, Role=Role)

def send_async_email(app, msg):
    with app.app_context():
        try:
            mail.send(msg)
            logger.info(f"Sent async email to {msg.recipients[0]} with subject '{msg.subject}'")
        except Exception as e:
            logger.error(f"Failed to send async email: {e}")

def send_email(to, subject, template, **kwargs):
    msg = Message(app.config['FLASKY_MAIL_SUBJECT_PREFIX'] + subject,
                  sender=app.config['FLASK_MAIL_SENDER'], recipients=[to])
    msg.body = render_template(template + '.txt', **kwargs)
    msg.html = render_template(template + '.html', **kwargs)
    thr = Thread(target=send_async_email, args=[app, msg])
    thr.start()
    return thr

@app.route('/', methods=['GET', 'POST'])
def index():
    form = NameForm()
    if form.validate_on_submit():
        # NOTE: Will this account for 2 separate names?
        user = User.query.filter_by(username=form.name.data).first()
        if user is None:
            user = User(username=form.name.data)
            db.session.add(user)
            db.session.commit()
            session['known'] = False
            if app.config['FLASKY_ADMIN_MAIL']:
                logger.debug("FLASKY_ADMIN_MAIL detected.")
                send_email(app.config['FLASKY_ADMIN_MAIL'], 'New User',
                           'mail/new_user', user=user)
        else:
            session['known'] = True 
        session['name'] = form.name.data
        form.name.data = ''
        return redirect(url_for('index'))
    return render_template('index.html', current_time=datetime.now(timezone.utc), 
                           form=form, name= session.get('name'), known=session.get('known', False))
    
@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.route('/user/')
@app.route('/user/<name>')
def user(name=None):
    if name == "gram": 
        abort(404)
    return render_template('user.html', name=name)

@app.route('/browser')
def browser():
    user_agent = request.headers.get('User-Agent')
    return '<p>Your browser is {}</p>'.format(user_agent)

# Need this for session cookie - given after successful login or registration.
@app.route('/cookie')
def cookie():
    response = make_response('<h1>A GIFT FROM THE COOKIE MONSTER!!!<h1>')
    response.set_cookie('answer', '42', secure=True, httponly=True, samesite='Strict')
    return response 

@app.route('/response')
def response():
    response = make_response('<h1>This is your Response!</h1>')
    response.get_data()
    return response 


@app.route('/redirect')
def reroute():
    return redirect('http://www.google.com')

