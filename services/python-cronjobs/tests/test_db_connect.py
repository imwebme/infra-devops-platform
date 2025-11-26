from utils.mongodb_manager import mongodb_manager

print("============================================================")
print("[1. Testing MongoDB connection...]")

client = mongodb_manager.get_connection('cluster0')

print(client.server_info())
print("MongoDB connection successful")
  
print("============================================================\n")