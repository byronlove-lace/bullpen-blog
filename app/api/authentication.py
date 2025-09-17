from flask import g, jsonify
from flask_httpauth import HTTPBasicAuth

from ..models import User
from . import api
from .errors import forbidden, unauthorized

auth = HTTPBasicAuth()

@auth.verify_password # Triggered on auth.login_required for APIs
def verify_password(email_or_token, password):
    if email_or_token == '':
        return False
    if password == '': # Blank if token
        g.current_user = User.verify_auth_token(email_or_token)
        g.token_used = True
        return g.current_user is not None
    user = User.query.filter_by(email=email_or_token).first()
    if not user:
        return False
    g.current_user = user
    g.token_used = False
    return user.verify_password(password)

@api.route('/tokens/', methods=['POST'])
def get_token():
    if g.current_user.is_anonymous or g.token_used:
        return unauthorized('Invalid credentials.')
    return jsonify({'token': g.current_user.generate_auth_token(),
                    'expiration': 3600})

@auth.error_handler
def auth_error():
    return unauthorized('Invalid credentials.')

@api.before_request
@auth.login_required # Grabs email:password from http reqs and runs verify_password
def before_request():
    if not g.current_user.is_anonymous and \
        not g.current_user.confirmed:
        return forbidden('Unconfirmed account.')
