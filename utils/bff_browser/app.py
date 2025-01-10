from flask import Flask, render_template, request, redirect, url_for, abort
from collections import defaultdict
import os
import json
import pandas as pd

app = Flask(__name__)
app.secret_key = 'replace-with-a-secure-key'

# Define allowed base directory for file validation (adjust as needed)
ALLOWED_BASE_DIR = os.path.join(app.root_path, 'static', 'jobs')

def list_to_cell_text(lst):
    """Convert list of dicts or values into an HTML unordered list without hyperlinks."""
    if not isinstance(lst, list) or len(lst) == 0:
        return ""
    html = "<ul style='padding-left: 1rem; margin:0;'>"
    for item in lst:
        if isinstance(item, dict):
            properties = "; ".join(f"<strong>{k}:</strong> {v}" for k, v in item.items())
            html += f"<li>{properties}</li>"
        else:
            html += f"<li>{item}</li>"
    html += "</ul>"
    return html

def merge_individuals_variants(individuals_data, genomic_data, limit=None):
    """
    Merges individuals and genomic variants into a combined data structure.
    Optionally limits the number of individuals processed.
    """
    sample_variants_map = defaultdict(list)
    for variant in genomic_data:
        # Handle multiple caseLevelData entries per variant
        for case_item in variant.get("caseLevelData", []):
            bs_id = case_item.get("biosampleId")
            if bs_id:
                variant_id = variant.get("variantInternalId", "unknown_variant")
                sample_variants_map[bs_id].append(variant_id)

    individuals_map = {}
    for ind in individuals_data:
        bs_id = ind.get("id")
        if bs_id:
            individuals_map[bs_id] = ind

    combined_data = []
    count = 0
    for bs_id, ind_obj in individuals_map.items():
        if limit and count >= limit:
            break
        variant_list = sample_variants_map.get(bs_id, [])
        variant_csv = ", ".join(variant_list)
        combined_data.append({
            "biosampleId": bs_id,
            "individualInfo": str(ind_obj),
            "allVariantsCsv": variant_csv
        })
        count += 1

    return combined_data

@app.route('/')
def home():
    return render_template("home.html")

@app.route('/help')
def help_page():
    return render_template("help.html")

@app.route("/example")
def example():
    return redirect(url_for('static', filename='jobs/cineca_uk1_173625581783940/browser/173625581783940.html'))

@app.route('/enter_path', methods=['GET', 'POST'])
def view_by_path():
    if request.method == 'POST':
        filepath = request.form['filepath'].strip()
        if not filepath.startswith("./static/"):
            abort(403, description="Access to this file is not allowed.")
        abs_path = os.path.abspath(filepath)
        if not os.path.isfile(abs_path) or not abs_path.lower().endswith(('.html', '.htm')):
            abort(404, description="File not found or not an HTML file.")
        url_path = filepath.lstrip(".")
        return redirect(url_path)
    return render_template('path_input.html')

@app.route('/individuals/example')
def individuals_example():
    json_path = os.path.join(app.root_path, 'static', 'jobs', 'cineca_uk1_individuals', 'individuals.json')
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        abort(404, description="Example JSON file not found.")
    df = pd.json_normalize(data, max_level=1)
    nested_cols = ['interventionsOrProcedures', 'measures', 'phenotypicFeatures', 'diseases']
    for col in nested_cols:
        if col in df.columns:
            df[col] = df[col].apply(lambda x: list_to_cell_text(x) if isinstance(x, list) else x)
    df = df.astype(str)
    table_html = df.to_html(classes='table table-striped', index=False, border=0, escape=False)
    return render_template('individuals_example.html', table_html=table_html)

@app.route('/individuals_view_by_path', methods=['GET', 'POST'])
def individuals_view_by_path():
    nested_cols = ['interventionsOrProcedures', 'measures', 'phenotypicFeatures', 'diseases']
    if request.method == 'POST':
        filepath = request.form['filepath'].strip()
        if not filepath.startswith("./static/"):
            abort(403, description="Access to this file is not allowed.")
        abs_path = os.path.abspath(filepath)
        if not os.path.isfile(abs_path) or not abs_path.lower().endswith('.json'):
            abort(404, description="File not found or not a JSON file.")
        try:
            with open(abs_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            abort(500, description=f"Error reading JSON: {e}")
        df = pd.json_normalize(data, max_level=1)
        for col in nested_cols:
            if col in df.columns:
                df[col] = df[col].apply(lambda x: list_to_cell_text(x) if isinstance(x, list) else x)
        df = df.astype(str)
        table_html = df.to_html(classes='table table-striped', index=False, border=0, escape=False)
        return render_template('individuals_example.html', table_html=table_html)
    return render_template('individuals_path_input.html')

@app.route('/combined_view_by_path', methods=['GET', 'POST'])
def combined_view_by_path():
    if request.method == 'POST':
        genomic_path = request.form.get('genomicPath', '').strip()
        individuals_path = request.form.get('individualsPath', '').strip()
        if not genomic_path or not individuals_path:
            abort(400, "Please provide both paths.")
        try:
            with open(genomic_path, 'r', encoding='utf-8') as gf:
                genomic_data = json.load(gf)
        except Exception as e:
            abort(500, description=f"Error reading genomic JSON: {e}")
        try:
            with open(individuals_path, 'r', encoding='utf-8') as inf:
                individuals_data = json.load(inf)
        except Exception as e:
            abort(500, description=f"Error reading individuals JSON: {e}")
        combined_data = merge_individuals_variants(individuals_data, genomic_data)
        return render_template("combined_bff.html", data_rows=combined_data)
    return render_template('combined_path_input.html')

@app.route('/combined_example')
def combined_example():
    individuals_path = os.path.join(app.root_path, 'static', 'jobs', 'cineca_uk1_individuals', 'individuals.json')
    genomic_path = os.path.join(app.root_path, 'static', 'jobs', 'cineca_uk1_173625581783940', 'browser', 'exome.json')

    with open(individuals_path, 'r', encoding='utf-8') as f:
        individuals_data = json.load(f)
    with open(genomic_path, 'r', encoding='utf-8') as f:
        genomic_data = json.load(f)

    # Limit to first 50 individuals as needed
    combined_data = merge_individuals_variants(individuals_data, genomic_data, limit=50)
    return render_template("combined_bff.html", data_rows=combined_data)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000, debug=True)
