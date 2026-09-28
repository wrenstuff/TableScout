from dataclasses import dataclass
from datetime import datetime

@dataclass
class User:
    userId: int
    userName: str
    email: str
    pwhash: str
    roleId: int
    accDate: datetime
    accStatus: str

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

