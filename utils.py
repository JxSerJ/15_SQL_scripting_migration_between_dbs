import sqlite3


class DBHandler:

    def __init__(self, db_path: str):
        self.db_path = db_path
