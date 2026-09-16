import os
from dotenv import load_dotenv



load_dotenv()
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")



SQLALCHEMY_DATABASE_URI = os.environ.get("SUPERSET_DATABASE_URI")



ENABLE_PROXY_FIX = True


FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}
