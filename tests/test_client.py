import unittest, re
from app import create_app, db
from app.models import User, Role
from flask import current_app

class FlaskClientTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app('testing')
        self.app_context = self.app.app_context()
        self.app_context.push()
        db.create_all()
        Role.insert_roles()
        self.client = self.app.test_client(use_cookies=True)

    def tearDown(self):
        db.session.remove()
        db.drop_all()
        self.app_context.pop()

    def test_home_page(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertTrue('Stranger' in response.get_data(as_text=True))

    def test_register_and_login(self):
        # register a new account
        response = self.client.post('/auth/register', data={
            'email': current_app.config['TEST_CLIENT_EMAIL'],
            'username': current_app.config['TEST_CLIENT_USERNAME'],
            'password': current_app.config['TEST_CLIENT_PASSWORD'],
            'password2': current_app.config['TEST_CLIENT_PASSWORD']
        })
        self.assertEqual(response.status_code, 302) # redirect only performed if succesful

        # log in with the new account
        response = self.client.post('/auth/login', data={
            'email': current_app.config['TEST_CLIENT_EMAIL'],
            'password': current_app.config['TEST_CLIENT_PASSWORD']
        }, follow_redirects=True)
        self.assertEqual(response.status_code, 200)
        self.assertRegex(response.get_data(as_text=True), re.escape(current_app.config['TEST_CLIENT_USERNAME']))
        self.assertTrue('You have not confirmed your account yet' in response.get_data(
            as_text=True))

        # send confirmation token
        user = User.query.filter_by(email=current_app.config['TEST_CLIENT_EMAIL']).first()
        token = user.generate_confirmation_token()
        response = self.client.get(f'auth/confirm/{token}',
                                   follow_redirects=True)
        user.confirm(token) # bypasses email function
        self.assertEqual(response.status_code, 200)
        self.assertTrue('You have confirmed your account' in response.get_data(as_text=True))

        # logout
        response = self.client.get('/auth/logout', follow_redirects=True)
        self.assertEqual(response.status_code, 200)
        self.assertTrue('You have been logged out' in response.get_data(as_text=True))

