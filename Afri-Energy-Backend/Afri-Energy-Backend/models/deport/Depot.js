import mongoose from "mongoose";
// Date formatting
import moment from "moment"; 

const companySchema = new mongoose.Schema({
  name: { type: String, required: true },
  latitude: { type: Number },
  longitude: { type: Number },
  createdAt: {
    type: String,
    default: () => moment().format("YYYY-MM-DD"), 
    
  },
});

const sourceSchema = new mongoose.Schema({
  name: { type: String, required: true },
  companies: [companySchema],
  createdAt: {
    type: String,
    default: () => moment().format("YYYY-MM-DD"), 
    
  },
});

const depotSchema = new mongoose.Schema(
  {
    depot: { type: String, required: true, unique: true, trim: true },
    sources: [sourceSchema],
  },
  { timestamps: true }
);

depotSchema.set("toJSON", {
  transform: function (doc, ret) {
    ret.createdAt = moment(ret.createdAt).format("YYYY-MM-DD");
    ret.updatedAt = moment(ret.updatedAt).format("YYYY-MM-DD");
    return ret;
  },
});

export default mongoose.model("Depot", depotSchema);
