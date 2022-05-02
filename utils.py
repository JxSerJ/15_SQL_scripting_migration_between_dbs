import sqlite3
from sqlite3 import OperationalError, Cursor
from typing import Iterable, Any

from colorama import Fore


class DBHandler:

    def __init__(self, old_db_path: str, new_db_path: str):
        self.old_db_path = old_db_path
        self.new_db_path = new_db_path
        print(f'Class {Fore.LIGHTBLUE_EX}DBHandler{Fore.RESET} initialized\n'
              f'Old DB: {Fore.YELLOW}{old_db_path}{Fore.RESET}\n'
              f'New DB: {Fore.YELLOW}{new_db_path}{Fore.RESET}')

    def db_connector(self, db_path: str, query: str, values: Iterable[Any] | None = None, script: bool = False) \
            -> tuple[bool, None] | tuple[bool, str] | tuple[list[Any], bool] | tuple[list[Any], str]:

        with sqlite3.connect(db_path) as connection:
            cursor = connection.cursor()

            if script:
                try:
                    cursor.executescript(query)
                    return True, None
                except OperationalError as message:
                    msg = str(message)
                    return False, msg
                except:
                    msg = 'unknown error'
                    return False, msg

            elif values:
                try:
                    result = cursor.execute(query, values).fetchall()
                    return result, False
                except OperationalError as message:
                    msg = str(message)
                    return result, msg

            else:
                try:
                    result = cursor.execute(query).fetchall()
                    return result, False
                except OperationalError as message:
                    result = []
                    msg = str(message)
                    return result, msg

    def normalize_db(self, script_path: str | None) -> list[Any] | tuple[list[Any], str]:

        if script_path:
            with open(script_path, 'r') as sql_cript_file:
                query = sql_cript_file.read()

        else:
            print("Enter script manually (input blank line to submit): \n")
            lines = []
            while True:
                line = input()
                if line:
                    lines.append(line)
                else:
                    q = input("Submit? (y/n) ")
                    if q == 'y':
                        break
                    else:
                        continue
            query = '\n'.join(lines)
        data = self.db_connector(self.new_db_path, query, script=True)
        return data

    def get_all_data_from_new_db(self) -> tuple[list[dict[str]], None]:

        query = ("SELECT "
                 "outcomes.id AS outcome_id, "
                 "outcome_month, "
                 "outcome_year, "
                 "age_upon_outcome, "
                 "age_upon_outcome_types.age_upon_outcome_type, "
                 "outcome_types.outcome_type AS outcome_type, "
                 "outcome_subtypes.outcome_subtype AS outcome_subtype, "
                 "outcomes.animal_id, "
                 "animals.name, "
                 "animal_type, "
                 "breed AS animal_breed, "
                 "color, "
                 "date_of_birth "
                 "FROM outcomes "
                 "LEFT JOIN outcome_types ON outcomes.outcome_type_id = outcome_types.id "
                 "LEFT JOIN outcome_subtypes ON outcome_types.outcome_subtype_id = outcome_subtypes.id "
                 "LEFT JOIN age_upon_outcome_types ON outcomes.age_upon_outcome_type_id = age_upon_outcome_types.id "
                 "LEFT JOIN animals ON outcomes.animal_id = animals.animal_id "
                 "LEFT JOIN animal_types ON animals.animal_type_id = animal_types.id "
                 "LEFT JOIN breeds ON animal_types.breed_id = breeds.id "
                 "JOIN animals_colors ON animals.animal_id = animals_colors.animal_id "
                 "INNER JOIN colors on colors.id = animals_colors.colors_id "
                 "LIMIT 100 ")
        db_fetched_data = self.db_connector(self.new_db_path, query)
        data = []
        print(db_fetched_data)

        for entry in db_fetched_data[0]:
            data.append(
                {
                    "outcome_id": entry[0],
                    "outcome_month": entry[1],
                    "outcome_year": entry[2],
                    "age_upon_outcome": entry[3],
                    "age_upon_outcome_type": entry[4],
                    "outcome_type": entry[5],
                    "outcome_subtype": entry[6],
                    "animal_id": entry[7],
                    "name": entry[8],
                    "animal_type": entry[9],
                    "animal_breed": entry[10],
                    "color": entry[11],
                    "date_of_birth": entry[12]
                },
            )

        return data, None

    def get_all_data_of_item_id_from_new_db(self, item_id: int) -> tuple[list[dict[str | Any, Any]], None]:

        query = ("SELECT "
                 "outcomes.id AS outcome_id, "
                 "outcome_month, "
                 "outcome_year, "
                 "age_upon_outcome, "
                 "age_upon_outcome_types.age_upon_outcome_type, "
                 "outcome_types.outcome_type AS outcome_type, "
                 "outcome_subtypes.outcome_subtype AS outcome_subtype, "
                 "outcomes.animal_id, "
                 "animals.name, "
                 "animal_type, "
                 "breed AS animal_breed, "
                 "color, "
                 "date_of_birth "
                 "FROM outcomes "
                 "LEFT JOIN outcome_types ON outcomes.outcome_type_id = outcome_types.id "
                 "LEFT JOIN outcome_subtypes ON outcome_types.outcome_subtype_id = outcome_subtypes.id "
                 "LEFT JOIN age_upon_outcome_types ON outcomes.age_upon_outcome_type_id = age_upon_outcome_types.id "
                 "LEFT JOIN animals ON outcomes.animal_id = animals.animal_id "
                 "LEFT JOIN animal_types ON animals.animal_type_id = animal_types.id "
                 "LEFT JOIN breeds ON animal_types.breed_id = breeds.id "
                 "JOIN animals_colors ON animals.animal_id = animals_colors.animal_id "
                 "INNER JOIN colors on colors.id = animals_colors.colors_id "
                 "WHERE outcomes.id == ? ")

        values = (item_id,)

        db_fetched_data = self.db_connector(self.new_db_path, query, values)

        data = []

        for entry in db_fetched_data[0]:
            data.append(
                {
                    "outcome_id": entry[0],
                    "outcome_month": entry[1],
                    "outcome_year": entry[2],
                    "age_upon_outcome": entry[3],
                    "age_upon_outcome_type": entry[4],
                    "outcome_type": entry[5],
                    "outcome_subtype": entry[6],
                    "animal_id": entry[7],
                    "name": entry[8],
                    "animal_type": entry[9],
                    "animal_breed": entry[10],
                    "color": entry[11],
                    "date_of_birth": entry[12]
                },
            )

        return data, None
