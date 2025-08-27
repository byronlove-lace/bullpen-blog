import hashlib
import requests
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField
from wtforms.validators import DataRequired, Length, Email, Regexp, EqualTo
from wtforms import ValidationError
from ..models import User

class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Length(1, 64)])

    password = PasswordField('Password', validators=[DataRequired()])
    remember_me = BooleanField('Keep me logged in')
    submit = SubmitField('Log In')

class RegistrationForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Length(1, 64), Email()])
    username = StringField('Username', validators=[DataRequired(), Length(1, 64),
                                                   Regexp('^[A-Za-z][A-Za-z0-9_.]*$', 0,
                                                          'Usernames must have only letters,'
                                                          'numbers, dots or underscores')])
    password = PasswordField('Password', validators=[DataRequired(), Length(8, 128, message='Password must be between 8 and 128 characters long.'),
                                                     EqualTo('password2', message='Passwords must match.')])
    password2 = PasswordField('Confirm password', validators=[DataRequired()])
    submit = SubmitField('Register')

    def __get_pwned(self, password):
        sha1 = hashlib.sha1(password.encode('utf-8')).hexdigest().upper()
        prefix, suffix = sha1[:5], sha1[5:]
        response = requests.get(f'https://api.pwnedpasswords.com/range/{prefix}')
        hashes = (line.split(':') for line in response.text.splitlines())
        for h, count in hashes:
            if h == suffix:
                return int(count)

    def validate_email(self, field):
        if User.query.filter_by(email=field.data).first():
            raise ValidationError('Email already registered.')

    def validate_username(self, field):
        if User.query.filter_by(username=field.data).first():
            raise ValidationError('Username already in use.')

    def validate_password(self, field):
        count = self.__get_pwned(field.data)
        threshold = 100
        if count and count > threshold:
            raise ValidationError(f'This password has appeared in {count} data breaches. Please choose a more secure ont.')

class ChangePasswordForm(FlaskForm):
    old_password = PasswordField('Old password', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired(), Length(8, 128, message='Password must be between 8 and 128 characters long.'),
                                                     EqualTo('password2', message='Passwords must match.')])
    password2 = PasswordField('Confirm password', validators=[DataRequired()])

    def __get_pwned(self, password):
        sha1 = hashlib.sha1(password.encode('utf-8')).hexdigest().upper()
        prefix, suffix = sha1[:5], sha1[5:]
        response = requests.get(f'https://api.pwnedpasswords.com/range/{prefix}')
        hashes = (line.split(':') for line in response.text.splitlines())
        for h, count in hashes:
            if h == suffix:
                return int(count)

    def validate_password(self, field):
        count = self.__get_pwned(field.data)
        threshold = 100
        if count and count > threshold:
            raise ValidationError(f'This password has appeared in {count} data breaches. Please choose a more secure ont.')

    submit = SubmitField('Update Password')

class PasswordResetForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Length(1, 64), Email()])
    submit = SubmitField('Reset Password')

    def validate_email(self, field):
        if not User.query.filter_by(email=field.data).first():
            raise ValidationError('No account found with this email.')

    password = PasswordField('Password', validators=[DataRequired(), Length(8, 128, message='Password must be between 8 and 128 characters long.'),
                                                     EqualTo('password2', message='Passwords must match.')])
    password2 = PasswordField('Confirm password', validators=[DataRequired()])

    def __get_pwned(self, password):
        sha1 = hashlib.sha1(password.encode('utf-8')).hexdigest().upper()
        prefix, suffix = sha1[:5], sha1[5:]
        response = requests.get(f'https://api.pwnedpasswords.com/range/{prefix}')
        hashes = (line.split(':') for line in response.text.splitlines())
        for h, count in hashes:
            if h == suffix:
                return int(count)

    def validate_password(self, field):
        count = self.__get_pwned(field.data)
        threshold = 100
        if count and count > threshold:
            raise ValidationError(f'This password has appeared in {count} data breaches. Please choose a more secure ont.')

    submit = SubmitField('Reset Password')

class PasswordResetRequestForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Length(1, 64), Email()])
    submit = SubmitField('Reset Password')

    def validate_email(self, field):
        if not User.query.filter_by(email=field.data).first():
            raise ValidationError('No account found with this email.')
