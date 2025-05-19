from flask import Blueprint, Bluprint

main = Blueprint('main', __name__) 

from . import views, errors
