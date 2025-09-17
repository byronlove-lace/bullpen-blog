from flask import Blueprint

main = Blueprint('main', __name__)

from ..models import Permission
from . import errors, views


@main.app_context_processor #auto-injects keywords into every render_template call -- Permission consts
def inject_permissions():
    return dict(Permission=Permission)
