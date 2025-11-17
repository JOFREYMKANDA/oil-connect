import fs from "fs";
import { MongoClient } from "mongodb";
import dotenv from "dotenv";

dotenv.config();

const uri = process.env.CONNECTION_STRING; 
const databaseName = "Africom_Energy_Db";
const collectionName = "depots";
  
async function seedData() {
  const client = new MongoClient(uri);
  try {
    // Connect to MongoDB
    await client.connect();
    const db = client.db(databaseName);
    const collection = db.collection(collectionName);

    // Read JSON data
    const data = JSON.parse(fs.readFileSync("depots.json", "utf8"));

    // Clear existing data
    await collection.deleteMany({});
    console.log("Cleared existing data");

    // Insert new data
    const result = await collection.insertMany(data);
    console.log(`${result.insertedCount} depots inserted successfully`);
  } catch (error) {
    console.error("Error seeding data:", error);
  } finally {
    await client.close();
  }
}

seedData();
