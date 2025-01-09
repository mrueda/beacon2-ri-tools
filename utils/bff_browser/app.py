from flask import Flask, render_template, request, redirect, url_for, abort
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
            # Format each dictionary item as key: value pairs
            properties = "; ".join(f"<strong>{k}:</strong> {v}" for k, v in item.items())
            html += f"<li>{properties}</li>"
        else:
            html += f"<li>{item}</li>"
    html += "</ul>"
    return html

@app.route('/')
def home():
    return render_template("home.html")

@app.route('/help')
def help_page():
    return render_template("help.html")

@app.route("/example")
def example():
    # Redirect directly to static file for Genomic Variations example
    return redirect(url_for('static', filename='jobs/cineca_uk1_173625581783940/browser/173625581783940.html'))

@app.route('/enter_path', methods=['GET', 'POST'])
def view_by_path():
    if request.method == 'POST':
        filepath = request.form['filepath'].strip()

        # Basic validation: ensure path starts with "./static/"
        if not filepath.startswith("./static/"):
            abort(403, description="Access to this file is not allowed.")

        abs_path = os.path.abspath(filepath)
        if not os.path.isfile(abs_path) or not abs_path.lower().endswith(('.html', '.htm')):
            abort(404, description="File not found or not an HTML file.")

        # Create a URL path by removing the leading "." from the file path
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

    # Convert entire DataFrame to string to preserve HTML content in cells
    df = df.astype(str)
    table_html = df.to_html(classes='table table-striped', index=False, border=0, escape=False)
    return render_template('individuals_example.html', table_html=table_html)

@app.route('/individuals/view_by_path', methods=['GET', 'POST'])
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

        # Convert entire DataFrame to string to preserve HTML content in cells
        df = df.astype(str)
        table_html = df.to_html(classes='table table-striped', index=False, border=0, escape=False)
        return render_template('individuals_example.html', table_html=table_html)

    return render_template('individuals_path_input.html')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000, debug=True)
