from flask import Blueprint

main = Blueprint('main', __name__)

from . import views, errors
from ..models import Permission

@main.app_context_processor #auto-injects keywords into every render_template call -- Permission consts
def inject_permissions():
    return dict(Permission=Permission)
