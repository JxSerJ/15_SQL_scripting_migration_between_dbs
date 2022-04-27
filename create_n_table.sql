DROP TABLE IF EXISTS animals;
DROP TABLE IF EXISTS breeds;
DROP TABLE IF EXISTS animal_types;
DROP TABLE IF EXISTS colors1;
DROP TABLE IF EXISTS colors2;
DROP TABLE IF EXISTS age_upon_outcome_types;
DROP TABLE IF EXISTS ages_upon_outcome;
DROP TABLE IF EXISTS outcome_subtypes;
DROP TABLE IF EXISTS outcome_types;
DROP TABLE IF EXISTS outcome_months;
DROP TABLE IF EXISTS outcome_dates;


CREATE TABLE breeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    breed varchar(100) NOT NULL
);

CREATE TABLE animal_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    animal_type varchar(50) NOT NULL CONSTRAINT df_animal_type DEFAULT 'Cat',
    breed_id INTEGER,
    FOREIGN KEY (breed_id) REFERENCES breeds(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE colors1 (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    color1 varchar(50) NOT NULL
);

CREATE TABLE colors2 (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    color2 varchar(50)
);

CREATE TABLE age_upon_outcome_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    age_upon_outcome_type varchar(50) NOT NULL
);

CREATE TABLE ages_upon_outcome (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    age_upon_outcome INTEGER NOT NULL,
    age_upon_outcome_type_id INTEGER NOT NULL,
    FOREIGN KEY (age_upon_outcome_type_id) REFERENCES age_upon_outcome_types(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE outcome_subtypes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_subtype varchar(50)
);

CREATE TABLE outcome_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_type varchar(50),
    outcome_subtype_id INTEGER,
    FOREIGN KEY (outcome_subtype_id) REFERENCES outcome_subtypes(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE outcome_months (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_month INTEGER NOT NULL
);

CREATE TABLE outcome_dates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_month_id INTEGER,
    outcome_year INTEGER NOT NULL,
    FOREIGN KEY (outcome_month_id) REFERENCES outcome_months(id) ON DELETE RESTRICT
);

CREATE TABLE animals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    animal_id varchar(10) NOT NULL,
    name varchar(100) NOT NULL CONSTRAINT df_name DEFAULT 'Unnamed',
    animal_type_id INTEGER,
    color1_id INTEGER,
    color2_id INTEGER,
    date_of_birth datetime NOT NULL,
    age_upon_outcome_id INTEGER,
    outcome_type_id INTEGER,
    outcome_date_id INTEGER,

    FOREIGN KEY (animal_type_id) REFERENCES animal_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (color1_id) REFERENCES colors1(id) ON DELETE RESTRICT,
    FOREIGN KEY (color2_id) REFERENCES colors2(id) ON DELETE RESTRICT,
    FOREIGN KEY (age_upon_outcome_id) REFERENCES ages_upon_outcome(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (outcome_type_id) REFERENCES outcome_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (outcome_date_id) REFERENCES outcome_dates(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX ix_animals_id ON animals (animal_id);
