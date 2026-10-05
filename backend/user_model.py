from dataclasses import dataclass
from datetime import datetime

@dataclass
class User:
    userid: int
    username: str
    email: str
    pwhash: str
    roleid: int
    role: str
    createdat: datetime
    accstatus: str

@dataclass
class Role:
    store: str
    supervisor: str
    staff: str

@dataclass
class AccStatus:
    active: str
    inactive: str
    suspended: str

