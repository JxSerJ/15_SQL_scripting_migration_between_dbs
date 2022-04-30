
from flask import Flask, jsonify, render_template
from utils import DBHandler

from colorama import Fore

application = Flask(__name__)
application.config.from_pyfile('config.py')

DB_obj = DBHandler(application.config.get('DB_PATH_ORIGIN'), application.config.get('DB_PATH_NEW'))


@application.route("/")
def main_page():
    return render_template("index.html",
                           old_bd=application.config.get('DB_PATH_ORIGIN'),
                           new_bd=application.config.get('DB_PATH_NEW'),
                           sript_path=application.config.get('NORMALIZE_SCRIPT'))


@application.route("/all")
def all_data():
    data, msg = DB_obj.get_all_data_from_new_db()
    if msg:
        print(f"{Fore.YELLOW}ERRORS OCCURRED: {Fore.RED}{msg}{Fore.RESET}")
        return render_template("result.html", error=True, msg=msg)
    return jsonify(data)


@application.route("/<int:item_id>")
def item_data(item_id: int):
    data, msg = DB_obj.get_all_data_of_item_id_from_new_db(item_id)
    if msg:
        print(f"{Fore.YELLOW}ERRORS OCCURRED: {Fore.RED}{msg}{Fore.RESET}")
        return render_template("result.html", error=True, msg=msg)
    return jsonify(data)


@application.route("/convert_db")
def normalize_db():
    result, msg = DB_obj.normalize_db(application.config.get('NORMALIZE_SCRIPT'))
    if msg:
        print(f"{Fore.YELLOW}ERRORS OCCURRED: {Fore.RED}{msg}{Fore.RESET}")
        return render_template("result.html", error=True, msg=msg)
    return render_template("result.html", error=False, msg=msg)


if __name__ == '__main__':
    application.run(port=5005)
