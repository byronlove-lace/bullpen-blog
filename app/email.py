from threading import Thread
from flask import render_template, current_app
from flask_mail import Message
from . import mail, logger


def send_async_email(app, msg):
    with app.app_context():
        try:
            mail.send(msg)
            logger.info(f"Sent async email to {msg.recipients[0]} with subject '{msg.subject}'")
        except Exception as e:
            logger.error(f"Failed to send async email: {e}")

def send_email(to, subject, template, **kwargs):
    msg = Message(current_app.config['FLASKY_MAIL_SUBJECT_PREFIX'] + subject,
                  sender=current_app.config['FLASK_MAIL_SENDER'], recipients=[to])
    msg.body = render_template(template + '.txt', **kwargs)
    msg.html = render_template(template + '.html', **kwargs)
    thr = Thread(target=send_async_email, args=[current_app, msg])
    thr.start()
    return thr
