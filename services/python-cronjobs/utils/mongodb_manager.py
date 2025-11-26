from dotenv import load_dotenv
from pymongo import MongoClient
import atexit
import logging
from .config import configs

# 로거 설정
logger = logging.getLogger(__name__)

class MongoDBManager:
    def __init__(self):
        load_dotenv(verbose=True)
        self.connections = {}

    def get_connection(self, db_name):
        try:
            if db_name not in self.connections:
                use_internal_db = configs['useInternalDb']
                db_uri_map = configs['newDbUriMap'] if use_internal_db else configs['dbUriMap']
                db_uri = db_uri_map[db_name]
                connection_string = f"{db_uri}"
                self.connections[db_name] = MongoClient(connection_string, maxPoolSize=30)
                print(f"MongoDB connected to {db_name}({db_uri})")
            return self.connections[db_name]
        except Exception as e:
            logger.error(f"Error getting connection for {db_name}: {e}")

    def close_all(self):
        for connection in self.connections.values():
            try:
                print("Closing MongoDB connection...")
                connection.close()
            except Exception as e:
                logger.error(f"Error closing connection: {e}")

# Create MongoDBManager instance
mongodb_manager = MongoDBManager()

# Register cleanup function to be called on program exit
atexit.register(mongodb_manager.close_all)