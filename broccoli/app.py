from flask import Flask
from flask_orator import Orator, jsonify

from .config import config

app = Flask(__name__)
app.config["ORATOR_DATABASES"] = config

db = Orator(app)

# TODO: literally everything else
