from flask import Flask, request, jsonify
from flask_cors import CORS
from mindee import Client, product
import tempfile
import os

app = Flask(__name__)
CORS(app)  # Permite llamadas desde Flutter Web

mindee_client = Client(api_key="e151df3d4c503c1b4680c9edacb68f65")
my_endpoint = mindee_client.create_endpoint(
    account_name="lacastrilp",
    endpoint_name="api_docs",
    version="1"
)

@app.route("/analizar", methods=["POST"])
def analizar_documento():
    if 'file' not in request.files:
        return jsonify({"error": "No se envió archivo"}), 400

    file = request.files['file']

    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        file.save(tmp.name)
        input_doc = mindee_client.source_from_path(tmp.name)

        result = mindee_client.enqueue_and_parse(
            product.GeneratedV1,
            input_doc,
            endpoint=my_endpoint
        )

        campos = {}
        for field_name, field_value in result.document.inference.prediction.fields.items():
            campos[field_name] = field_value.value if hasattr(field_value, "value") else str(field_value)

        os.remove(tmp.name)
        return jsonify({"campos_extraidos": campos})

if __name__ == "__main__":
    app.run(debug=True)
