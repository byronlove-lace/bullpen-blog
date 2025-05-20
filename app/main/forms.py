from flask_wtf import FlaskForm
from wtforms import PasswordField, StringField, SubmitField
from wtforms.validators import DataRequired, Length

class NameForm(FlaskForm):
    name = StringField('What is your name?', validators=[DataRequired()])
    secret = PasswordField('Tell me your secret.', validators=[DataRequired(), Length(6)])
    submit = SubmitField('Submit')
