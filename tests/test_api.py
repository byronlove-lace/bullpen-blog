import unittest, re
from flask_login import current_user
from base64 import b64encode

from werkzeug.wrappers import response
from app import create_app, db
from app.models import User, Role
from flask import current_app, url_for, json

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

    def get_api_headers(self, username, password):
        return {
            'Authorization':
                'Basic ' + b64encode( #b64 ascii needed for http compatability -- username and password may have non ascii chars
                (username + ':' + password).encode('utf-8')).decode('utf-8'), # decode to unicode but b64ascii compatible under the hood
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }

    def test_no_auth(self):
        response = self.client.get('/api/v1/posts/',
                                   content_type='application/json')
        self.assertEqual(response.status_code, 401)

    def test_posts(self):
        # add user
        r = Role.query.filter_by(name='User').first()
        self.assertIsNotNone(r)
        u = User(email=current_app.config['TEST_CLIENT_EMAIL'],
                 password=current_app.config['TEST_CLIENT_PASSWORD'],
                 confirmed=True,
                 role=r)
        db.session.add(u)
        db.session.commit()

        # write a post
        response = self.client.post(
            '/api/v1/posts/',
            headers=self.get_api_headers(
                current_app.config['TEST_CLIENT_EMAIL'],
                current_app.config['TEST_CLIENT_PASSWORD']),
                data=json.dumps({'body': 'body of the *blog* post'}))
        self.assertEqual(response.status_code, 201)
        url = response.headers.get('Location')
        self.assertIsNotNone(url)

        # get the new post
        response = self.client.get(
            url,
            headers=self.get_api_headers(
                current_app.config['TEST_CLIENT_EMAIL'],
                current_app.config['TEST_CLIENT_PASSWORD']))
        self.assertEqual(response.status_code, 200)
        json_response = json.loads(response.get_data(as_text=True))
        self.assertEqual(json_response['url'], url)
        self.assertEqual(json_response['body'], 'body of the *blog* post')
        self.assertEqual(json_response['body_html'],
                         '<p>body of the <em>blog</em> post</p>')
        self.assertEqual(response.status_code, 200)
