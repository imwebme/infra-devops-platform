from utils.mongodb_manager import mongodb_manager

print("============================================================")
print("[2. Testing MongoDB query...]")

client = mongodb_manager.get_connection('cluster0')

collection = client["DEMO"]["NewUsers"]
print(collection)
document = collection.find_one()
print(document)
print("MongoDB query successful")
  
print("============================================================\n")