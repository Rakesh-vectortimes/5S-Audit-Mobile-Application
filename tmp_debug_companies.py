from pymongo import MongoClient

c = MongoClient("mongodb://localhost:27017", serverSelectionTimeoutMS=3000)
db = c["diagnostic_study_db"]

print("companies", db.companies.count_documents({}))
print("deals", db.crm_deals.count_documents({}))

print("--- converted_to ---")
for row in db.crm_deals.aggregate([{"$group": {"_id": "$converted_to", "n": {"$sum": 1}}}]):
    print(repr(row["_id"]), type(row["_id"]).__name__, row["n"])

print("--- deals ---")
for d in db.crm_deals.find({}, {"company_name": 1, "converted_to": 1, "company_id": 1, "org_company_id": 1}):
    print(
        "name=", d.get("company_name"),
        "converted_to=", d.get("converted_to"),
        "company_id=", d.get("company_id"),
        "org=", d.get("org_company_id"),
    )

print("--- companies ---")
for doc in db.companies.find({}, {"company_name": 1, "status": 1, "location": 1, "address": 1, "currency": 1, "org_company_id": 1}):
    loc = doc.get("location")
    addr = doc.get("address")
    cur = doc.get("currency")
    print(
        "name=", doc.get("company_name"),
        "status=", doc.get("status"),
        "loc_type=", type(loc).__name__,
        "addr_type=", type(addr).__name__,
        "cur_type=", type(cur).__name__,
    )
