from threading import Thread

from flask import current_app, render_template
from flask_mail import Message

from . import logger, mail


def send_async_email(app, msg):
    with app.app_context():
        try:
            mail.send(msg)
            logger.info(f"Sent async email to {msg.recipients[0]} with subject '{msg.subject}'")
        except Exception as e:
            logger.error(f"Failed to send async email: {e}")

def send_email(to, subject, template, **kwargs):
    app = current_app._get_current_object()
    msg = Message(current_app.config['BULLPEN_MAIL_SUBJECT_PREFIX'] + subject,
                  sender=current_app.config['BULLPEN_MAIL_SENDER'], recipients=[to])
    msg.body = render_template(template + '.txt', **kwargs)
    msg.html = render_template(template + '.html', **kwargs)
    thr = Thread(target=send_async_email, args=[app, msg])
    thr.start()
    return thr
