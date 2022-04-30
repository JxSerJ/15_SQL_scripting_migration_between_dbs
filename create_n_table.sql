-- ATTENTION!
-- Execute this script ONLY connected to a NEW database file!
-- If you execute script connected to original database your data can be corrupted or erased!


-- Cleanup new database file from previous attempt --

DROP TABLE IF EXISTS animals;
DROP TABLE IF EXISTS outcomes;
DROP TABLE IF EXISTS breeds;
DROP TABLE IF EXISTS animal_types;
DROP TABLE IF EXISTS colors;
DROP TABLE IF EXISTS age_upon_outcome_types;
DROP TABLE IF EXISTS outcome_subtypes;
DROP TABLE IF EXISTS outcome_types;
DROP TABLE IF EXISTS orig_table;

VACUUM;

-- Create new normalized database --

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

CREATE TABLE colors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    color varchar(50)
);

CREATE TABLE age_upon_outcome_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    age_upon_outcome_type varchar(50) NOT NULL
);

CREATE TABLE outcome_subtypes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_subtype varchar(50) NOT NULL CONSTRAINT df_subtype DEFAULT 'no_data'
);

CREATE TABLE outcome_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_type varchar(50) NOT NULL CONSTRAINT df_type DEFAULT 'no_data',
    outcome_subtype_id INTEGER,
    FOREIGN KEY (outcome_subtype_id) REFERENCES outcome_subtypes(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE animals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    animal_id varchar(10) NOT NULL,
    name varchar(100) CONSTRAINT df_name DEFAULT 'Unnamed',
    animal_type_id INTEGER,
    date_of_birth datetime NOT NULL,
    color1_id INTEGER NOT NULL CONSTRAINT df_color DEFAULT 'no_data',
    color2_id INTEGER,

    FOREIGN KEY (animal_type_id) REFERENCES animal_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (color1_id) REFERENCES colors(id) ON DELETE RESTRICT,
    FOREIGN KEY (color2_id) REFERENCES colors(id) ON DELETE RESTRICT
);

CREATE TABLE outcomes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_year INTEGER NOT NULL,
    outcome_month INTEGER NOT NULL,
    outcome_type_id INTEGER,
    age_upon_outcome INTEGER, -- this data separation and structure are unnecessary but were added, because in theory, automatic age calculation can be implemented as feature in future
    age_upon_outcome_type_id INTEGER, -- this data separation and structure are unnecessary but were added, because in theory, automatic age calculation can be implemented as feature in future
    animal_id varchar(10) NOT NULL,

    FOREIGN KEY (age_upon_outcome_type_id) REFERENCES age_upon_outcome_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (outcome_type_id) REFERENCES outcome_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (animal_id) REFERENCES animals(animal_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX ix_outcome_id ON outcomes (id);
CREATE INDEX ix_animal_id ON animals (id);


-- Temporarily copying original database data from original file --

ATTACH DATABASE 'animal.db' AS orig_bd;

CREATE TABLE orig_table(
    "index" INTEGER,
    age_upon_outcome TEXT,
    animal_id TEXT,
    animal_type TEXT,
    name TEXT,
    breed TEXT,
    color1 TEXT, color2 TEXT,
    date_of_birth TEXT,
    outcome_subtype TEXT, outcome_type TEXT,
    outcome_month INTEGER, outcome_year INTEGER);

INSERT INTO orig_table SELECT * FROM orig_bd.animals;

CREATE INDEX ix_animals_index ON orig_table ("index");

DETACH orig_bd;

-- Eliminating NULL-data in important columns --
UPDATE orig_table SET outcome_subtype = 'no_data' WHERE outcome_subtype IS NULL;
UPDATE orig_table SET outcome_type = 'no_data' WHERE outcome_type IS NULL;
UPDATE orig_table SET color2 = 'no_data' WHERE color2 IS NULL;
UPDATE orig_table SET name = 'no_data' WHERE name IS NULL;

-- Prep orig_table data for script enormous speed optimization --
UPDATE orig_table SET "index" = "index"+1;

-- Original data ready --



-- Convert and write original database data to new format --


-- Filling additional tables --

INSERT INTO breeds (breed) SELECT DISTINCT TRIM(breed) FROM orig_table;
INSERT INTO animal_types (animal_type, breed_id) SELECT DISTINCT TRIM(animal_type), (SELECT id FROM breeds WHERE breed = TRIM(orig_table.breed)) FROM orig_table;

INSERT INTO colors (color) SELECT DISTINCT TRIM(color1) FROM orig_table;
INSERT INTO colors (color) SELECT DISTINCT TRIM(color2) FROM orig_table WHERE TRIM(color2) NOT IN (SELECT color FROM colors);

-- UNION variant of color table compilation (NULL data included if UNION used) --
-- INSERT INTO colors (color) SELECT DISTINCT TRIM(color1) FROM orig_table UNION SELECT DISTINCT TRIM(color2) FROM orig_table;

INSERT INTO age_upon_outcome_types (age_upon_outcome_type) VALUES ('days'), ('weeks'), ('months'), ('years');

INSERT INTO outcome_subtypes (outcome_subtype) SELECT DISTINCT TRIM(outcome_subtype) FROM orig_table;
INSERT INTO outcome_types (outcome_type, outcome_subtype_id) SELECT DISTINCT TRIM(outcome_type), (SELECT id FROM outcome_subtypes WHERE outcome_subtype = orig_table.outcome_subtype) FROM orig_table;


-- Filling outcomes table --

INSERT INTO outcomes (outcome_year, outcome_month, animal_id, age_upon_outcome) SELECT outcome_year, outcome_month, animal_id, TRIM(substr(age_upon_outcome, 0, instr(age_upon_outcome, ' '))) FROM orig_table;

ALTER TABLE outcomes ADD orig_age_upon_outcome_types VARCHAR(50);
UPDATE outcomes SET orig_age_upon_outcome_types = (SELECT age_upon_outcome FROM orig_table WHERE outcomes.id = orig_table."index");
UPDATE outcomes SET age_upon_outcome_type_id = (SELECT id FROM age_upon_outcome_types WHERE age_upon_outcome_types.age_upon_outcome_type = TRIM(RTRIM(substr(orig_age_upon_outcome_types, instr(orig_age_upon_outcome_types, ' '), length(orig_age_upon_outcome_types)), 's')) || 's');


ALTER TABLE outcomes ADD orig_outcome_type VARCHAR(50);
ALTER TABLE outcomes ADD orig_outcome_subtype VARCHAR(50);
ALTER TABLE outcomes ADD orig_outcome_type_id INTEGER;
ALTER TABLE outcomes ADD orig_outcome_subtype_id INTEGER;
UPDATE outcomes SET orig_outcome_type = (SELECT outcome_type FROM orig_table WHERE outcomes.id = orig_table."index");
UPDATE outcomes SET orig_outcome_subtype = (SELECT outcome_subtype FROM orig_table WHERE outcomes.id = orig_table."index");
UPDATE outcomes SET orig_outcome_subtype_id = (SELECT id FROM outcome_subtypes WHERE outcomes.orig_outcome_subtype = outcome_subtypes.outcome_subtype);
UPDATE outcomes SET outcome_type_id = (SELECT outcome_types.id FROM outcome_types
    LEFT OUTER JOIN outcome_subtypes ON outcome_subtypes.id = outcome_types.outcome_subtype_id
                                                WHERE outcomes.orig_outcome_type = outcome_type AND outcomes.orig_outcome_subtype_id = outcome_subtype_id);

ALTER TABLE outcomes DROP COLUMN orig_age_upon_outcome_types;
ALTER TABLE outcomes DROP COLUMN orig_outcome_type;
ALTER TABLE outcomes DROP COLUMN orig_outcome_subtype;
ALTER TABLE outcomes DROP COLUMN orig_outcome_type_id;
ALTER TABLE outcomes DROP COLUMN orig_outcome_subtype_id;
-- Outcomes table completed --


-- Filling animals table --

INSERT INTO animals (animal_id, name, date_of_birth) SELECT DISTINCT animal_id, name, date_of_birth FROM orig_table;

ALTER TABLE animals ADD color1 VARCHAR(50);
ALTER TABLE animals ADD color2 VARCHAR(50);
UPDATE animals SET (color1, color2) = (SELECT TRIM(color1), TRIM(color2) FROM orig_table WHERE orig_table.animal_id = animals.animal_id);
UPDATE animals SET color1_id = (SELECT id FROM colors WHERE colors.color = animals.color1);
UPDATE animals SET color2_id = (SELECT id FROM colors WHERE colors.color = animals.color2);

ALTER TABLE animals ADD orig_animal_type VARCHAR(50);
ALTER TABLE animals ADD orig_breed VARCHAR(50);
ALTER TABLE animals ADD orig_animal_type_id INTEGER;
ALTER TABLE animals ADD orig_breed_id INTEGER;
UPDATE animals SET orig_animal_type = (SELECT animal_type FROM orig_table WHERE animals.animal_id = orig_table.animal_id);
UPDATE animals SET orig_breed = (SELECT breed FROM orig_table WHERE animals.animal_id = orig_table.animal_id);
UPDATE animals SET orig_breed_id = (SELECT id FROM breeds WHERE animals.orig_breed = breeds.breed);
UPDATE animals SET animal_type_id = (SELECT animal_types.id FROM animal_types
    LEFT OUTER JOIN breeds ON breeds.id = animal_types.breed_id
                                                WHERE animals.orig_animal_type = animal_type AND animals.orig_breed_id = breed_id);

ALTER TABLE animals DROP COLUMN color1;
ALTER TABLE animals DROP COLUMN color2;
ALTER TABLE animals DROP COLUMN orig_animal_type;
ALTER TABLE animals DROP COLUMN orig_breed;
ALTER TABLE animals DROP COLUMN orig_animal_type_id;
ALTER TABLE animals DROP COLUMN orig_breed_id;
-- Animals table completed --


-- Cleanup and Delete original and temp databases data from new file --

UPDATE animals SET name = NULL WHERE name == 'no_data';

DROP TABLE IF EXISTS orig_table;
VACUUM;
