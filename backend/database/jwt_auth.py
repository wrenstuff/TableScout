import os 
import jwt

from pathlib import Path
from dotenv import load_dotenv

backend_path = Path(__name__).resolve().parent.parent
env_path = backend_path / "api.env"

load_dotenv(dotenv_path=env_path, override=True)

SECRET_KEY = os.getenv("TABLESCOUT_SECRET_KEY")

def token_verify(token):
    if not SECRET_KEY:
        raise RuntimeError ("key is missing")

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=["HS256"]
        )
        return payload
    
    except jwt.InvalidTokenError:
        return None