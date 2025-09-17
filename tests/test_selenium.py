import os
import logging
import re
import threading
import time
import unittest
from flask import current_app
from selenium.webdriver.common.by import By
from selenium import webdriver
from selenium.common.exceptions import WebDriverException
from app import create_app, db, fake
from app.models import Role, User
from wsgiref.simple_server import make_server


class SeleniumTestCase(unittest.TestCase):
    client = None
    server = None

    @classmethod # class level atts apply to all tests -> reused browser sesh in selenium
    def setUpClass(cls):
        # start Chrome
        options = webdriver.ChromeOptions()
        options.add_argument('headless')
        try:
            cls.client = webdriver.Chrome(options=options)
        except WebDriverException:
            pass

        # skip if browser could not be started.
        if cls.client:
            # create the application
            cls.app = create_app('testing')
            cls.app_context = cls.app.app_context()
            cls.app_context.push()

            # supress logging to keep unittest output clean
            logger = logging.getLogger('werkzeug')
            logger.setLevel('ERROR')

            # create the database and populate with some fake data
            db.create_all()
            Role.insert_roles()
            fake.users(10)
            fake.posts(10)

            # add an admin user
            admin_role = Role.query.filter_by(name='Administrator').first()
            admin = User(email=cls.app.config['TEST_CLIENT_EMAIL'],
                         username=cls.app.config['TEST_CLIENT_USERNAME'],
                         password=cls.app.config['TEST_CLIENT_PASSWORD'],
                         role=admin_role, confirmed=True)
            db.session.add(admin)
            db.session.commit()

            # start the Flask server on a separate WSGI server thread
            cls.server = make_server(current_app.config['LOOPBACK_ADDRESS'], 5000, cls.app)
            cls.server_thread = threading.Thread(target=cls.server.serve_forever)
            cls.server_thread.start()

            # give the server a second to ensure it is up
            time.sleep(1)

    @classmethod
    def tearDownClass(cls):
        if cls.client:
            # stop the flask server and the browser
            cls.client.quit()

        if cls.server:
            cls.server.shutdown()
            cls.server_thread.join()

        # remove applicatoin context
        if hasattr(cls, 'app_context'):
            cls.app_context.pop()

            # destroy database
            db.drop_all()
            db.session.remove()


    def setUp(self):
        if not self.client:
            self.skipTest('Web browser not available')

    def tearDown(self):
        pass

    def test_admin_home_page(self):
        # navigate to home page
        self.client.get('http://localhost:5000/')
        self.assertRegex(self.client.page_source,
                         r"Hello,\s+Stranger!")

        # naviagete to login page
        self.client.find_element(By.LINK_TEXT, 'Log In').click()
        self.assertIn('<h1>Login</h1>', self.client.page_source)

        # login
        self.client.find_element(By.NAME,'email').send_keys(current_app.config['TEST_CLIENT_EMAIL'])
        self.client.find_element(By.NAME,'password').send_keys(current_app.config['TEST_CLIENT_PASSWORD'])
        self.client.find_element(By.NAME,'submit').click()
        time.sleep(2)
        self.assertRegex(self.client.page_source,
                         r"Hello,\s+" + re.escape(current_app.config['TEST_CLIENT_USERNAME']))

        # naviage to the user's profile page
        self.client.find_element(By.LINK_TEXT, 'Profile').click()
        time.sleep(2)
        self.assertRegex(self.client.page_source,
                         "<h1>" + re.escape(current_app.config['TEST_CLIENT_USERNAME'] + "</h1>"))
