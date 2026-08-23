import joblib
loaded_model = joblib.load('model_pkl.pkl')
import base64
import io
from imageio import imread
import numpy as np
from flask import Flask,request,jsonify

app = Flask(__name__)

@app.route("/", methods=['GET', 'POST'])
def api_test():
    if request.method == 'POST':
        content_type = request.headers.get('Content-Type')
        if (content_type == 'application/json'):
            json = request.json
            spo2_array=[]
            
            image_rgb = (json['images'])
            # for rgb in image_rgb:
            #     spo2_array.append()
            # print(spo2_array)
            # x=np.average(spo2_array)
            spo2 = loaded_model.predict([image_rgb])
            #if(x[0]<200):
            #     data={
            #         "message":"false"
            #     }
            #     return jsonify(data)
            # values = [x]

            #spo2 = loaded_model.predict([x])
            #print(spo2)
            data={
                "message":"success",
                "spo2": spo2[0]
            }
            return jsonify(data)
    else:
        return "HELLO THERE"


@app.route("/save", methods=['POST'])
def save_vitals():
    content_type = request.headers.get('Content-Type')
    if (content_type == 'application/json'):
        json_data = request.json
        print(f"Saving vitals: {json_data}")
        # Here you could save to a database or file
        with open('vitals_log.txt', 'a') as f:
            f.write(str(json_data) + '\n')
        return jsonify({"message": "success", "status": "saved locally"})
    return jsonify({"message": "error", "reason": "Invalid Content-Type"})


@app.route("/test", methods=['GET', 'POST'])
def test():
    if request.method == 'POST':
        content_type = request.headers.get('Content-Type')
        if (content_type == 'application/json'):
            json = request.json
            print(json)
            return json
        else:
            return "DIFF CONTENT"
    else:
        return "HELLO THERE"