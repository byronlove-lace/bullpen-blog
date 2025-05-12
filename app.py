from flask import Flask, request, make_response, redirect, abort, render_template, session, redirect, url_for, flash
from flask_bootstrap import Bootstrap
from flask_moment import Moment
from flask_wtf import FlaskForm
from flask_sqlalchemy import SQLAlchemy
from wtforms import StringField, SubmitField, PasswordField
from wtforms.validators import DataRequired, Length
from datetime import datetime, timezone
from dotenv import load_dotenv
import os



basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__)
DATABASE_URI = os.getenv('DATABASE_URI')
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URI
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

load_dotenv()
SECRET_KEY = os.getenv('SECRET_KEY')
app.secret_key = SECRET_KEY

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

@app.route('/', methods=['GET', 'POST'])
def index():
    form = NameForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.name.data).first()
        if user is None:
            user = User(username=form.name.data)
            db.session.add(user)
            db.session.commit()
            session['known'] = False
        else:
            session['known'] = True 
        session['name'] = form.name.data
        form.name.data = ''
        return redirect(url_for('index'))
    return render_template('index.html', current_time=datetime.now(timezone.utc), 
                           form=form, name= session.get('name'), known=session.get('known', False))
    


        old_name = session.get('name')
        new_name = form.name.data
        if old_name is not None and old_name != new_name:
            flash(f'Nice ta meetcha\', {new_name}!')
        else:
            flash(f'Welcome back\', {new_name}!')

        session['name'] = new_name
        return redirect(url_for('index'))
    return render_template('index.html', current_time=datetime.now(timezone.utc), 
                           form=form, name= session.get('name'))

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

