-- ATTENTION! --
-- Execute this script ONLY connected to a NEW database file! --
-- If you execute script connected to original database your data can be corrupted or erased! --


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
DROP TABLE IF EXISTS outcomes_temp;
DROP TABLE IF EXISTS animals_temp;
DROP TABLE IF EXISTS animal_types_breeds;

VACUUM;

-- Create new normalized database --

CREATE TABLE IF NOT EXISTS breeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    breed varchar(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS animal_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    animal_type varchar(50) NOT NULL CONSTRAINT df_animal_type DEFAULT 'Cat'
);

CREATE TABLE IF NOT EXISTS animal_types_breeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    animal_type_id INTEGER,
    breed_id INTEGER,
    FOREIGN KEY (breed_id) REFERENCES breeds(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (animal_type_id) REFERENCES animal_types(id)
);

CREATE TABLE IF NOT EXISTS colors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    color varchar(50)
);

CREATE TABLE IF NOT EXISTS age_upon_outcome_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    age_upon_outcome_type varchar(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS outcome_subtypes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_subtype varchar(50) NOT NULL CONSTRAINT df_subtype DEFAULT 'no_data'
);

CREATE TABLE IF NOT EXISTS outcome_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_type varchar(50) NOT NULL CONSTRAINT df_type DEFAULT 'no_data',
    outcome_subtype_id INTEGER,
    FOREIGN KEY (outcome_subtype_id) REFERENCES outcome_subtypes(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS animals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    animal_id varchar(10) NOT NULL,
    name varchar(100) CONSTRAINT df_name DEFAULT 'Unnamed',
    animal_type_breed_id INTEGER,
    date_of_birth datetime NOT NULL,
    color1_id INTEGER,
    color2_id INTEGER,

    FOREIGN KEY (animal_type_breed_id) REFERENCES animal_types_breeds(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (color1_id) REFERENCES colors(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (color2_id) REFERENCES colors(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS outcomes (
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


-- Temporarily copying original database data from original file --

ATTACH DATABASE 'animal.db' AS orig_bd;

CREATE TABLE IF NOT EXISTS orig_table(
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

DETACH orig_bd;



-- Eliminating NULL-data in important columns --
UPDATE orig_table SET outcome_subtype = 'no_data' WHERE outcome_subtype IS NULL;
UPDATE orig_table SET outcome_type = 'no_data' WHERE outcome_type IS NULL;
UPDATE orig_table SET color2 = 'no_data' WHERE color2 IS NULL;
UPDATE orig_table SET name = 'no_data' WHERE name IS NULL;

-- Prep orig_table data for script enormous speed optimization --
UPDATE orig_table SET "index" = "index"+1;
CREATE INDEX ix_animals_index ON orig_table ("index");

-- diversifying data a little bit for testing and learning purposes --
UPDATE orig_table SET animal_type = 'Dog', name = 'Rex', breed = 'German Dog', color2 = 'brown' WHERE "index" = 12 AND animal_id = 'A681039' AND rowid = 12;
UPDATE orig_table SET animal_type = 'Turtle', breed = 'Solid' WHERE "index" = 25 AND animal_id = 'A691708' AND rowid = 25;
UPDATE orig_table SET animal_type = 'Dog', breed = 'Mops' WHERE "index" = 23 AND animal_id = 'A662912' AND rowid = 23;
UPDATE orig_table SET animal_type = 'Dog', breed = 'Biggle' WHERE "index" = 22 AND animal_id = 'A680225' AND rowid = 22;
-- Original data ready --



-- Convert and write original database data to new format --


-- Filling secondary tables --

INSERT INTO breeds (breed) SELECT DISTINCT TRIM(breed) FROM orig_table;
INSERT INTO animal_types (animal_type) SELECT DISTINCT TRIM(animal_type) FROM orig_table;

INSERT INTO animal_types_breeds (animal_type_id, breed_id)
SELECT DISTINCT animal_types.id, breeds.id FROM animal_types
    JOIN orig_table ON animal_types.animal_type = orig_table.animal_type
    JOIN breeds ON orig_table.breed = breeds.breed;

INSERT INTO colors (color) SELECT DISTINCT TRIM(color1) FROM orig_table;
INSERT INTO colors (color) SELECT DISTINCT TRIM(color2) FROM orig_table WHERE TRIM(color2) NOT IN (SELECT color FROM colors);

-- UNION variant of color table compilation (NULL data included if UNION used) --
-- INSERT INTO colors (color) SELECT DISTINCT TRIM(color1) FROM orig_table UNION ALL SELECT DISTINCT TRIM(color2) FROM orig_table;

INSERT INTO age_upon_outcome_types (age_upon_outcome_type) VALUES ('days'), ('weeks'), ('months'), ('years');

INSERT INTO outcome_subtypes (outcome_subtype) SELECT DISTINCT TRIM(outcome_subtype) FROM orig_table;
INSERT INTO outcome_types (outcome_type, outcome_subtype_id)
SELECT DISTINCT TRIM(outcome_type), (SELECT id FROM outcome_subtypes WHERE outcome_subtype = orig_table.outcome_subtype) FROM orig_table;


-- Filling outcomes table --

-- creating temp table (outcomes) --
CREATE TABLE IF NOT EXISTS outcomes_temp (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    outcome_year INTEGER NOT NULL,
    outcome_month INTEGER NOT NULL,
    outcome_type_id INTEGER,
    age_upon_outcome INTEGER, -- this data separation and structure are unnecessary but were added, because in theory, automatic age calculation can be implemented as feature in future
    age_upon_outcome_type_id INTEGER, -- this data separation and structure are unnecessary but were added, because in theory, automatic age calculation can be implemented as feature in future
    animal_id varchar(10) NOT NULL,
    orig_outcome_type VARCHAR(50),
    orig_outcome_subtype VARCHAR(50),
    orig_outcome_type_id INTEGER,
    orig_outcome_subtype_id INTEGER,
    orig_age_upon_outcome_types VARCHAR(50),

    FOREIGN KEY (age_upon_outcome_type_id) REFERENCES age_upon_outcome_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (outcome_type_id) REFERENCES outcome_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (animal_id) REFERENCES animals(animal_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

INSERT INTO outcomes_temp (outcome_year, outcome_month, animal_id, age_upon_outcome) SELECT outcome_year, outcome_month, animal_id, TRIM(substr(age_upon_outcome, 0, instr(age_upon_outcome, ' '))) FROM orig_table;

UPDATE outcomes_temp SET orig_age_upon_outcome_types = (SELECT age_upon_outcome FROM orig_table WHERE outcomes_temp.id = orig_table."index");
UPDATE outcomes_temp SET age_upon_outcome_type_id = (SELECT id FROM age_upon_outcome_types WHERE age_upon_outcome_types.age_upon_outcome_type = TRIM(RTRIM(substr(orig_age_upon_outcome_types, instr(orig_age_upon_outcome_types, ' '), length(orig_age_upon_outcome_types)), 's')) || 's');


UPDATE outcomes_temp SET orig_outcome_type = (SELECT outcome_type FROM orig_table WHERE outcomes_temp.id = orig_table."index");
UPDATE outcomes_temp SET orig_outcome_subtype = (SELECT outcome_subtype FROM orig_table WHERE outcomes_temp.id = orig_table."index");
UPDATE outcomes_temp SET orig_outcome_subtype_id = (SELECT id FROM outcome_subtypes WHERE outcomes_temp.orig_outcome_subtype = outcome_subtypes.outcome_subtype);
UPDATE outcomes_temp SET outcome_type_id =
    (SELECT outcome_types.id
     FROM outcome_types
         LEFT OUTER JOIN outcome_subtypes ON outcome_subtypes.id = outcome_types.outcome_subtype_id
     WHERE outcomes_temp.orig_outcome_type = outcome_type
       AND outcomes_temp.orig_outcome_subtype_id = outcome_subtype_id);
-- temp table (outcomes) created --

INSERT INTO outcomes (outcome_year, outcome_month, outcome_type_id, age_upon_outcome, age_upon_outcome_type_id, animal_id)
SELECT outcome_year, outcome_month, outcome_type_id, age_upon_outcome, age_upon_outcome_type_id, animal_id
FROM outcomes_temp;
-- Outcomes table completed --


-- Filling animals table --

INSERT INTO animals (animal_id, name, date_of_birth) SELECT DISTINCT animal_id, name, date_of_birth FROM orig_table;

-- creating temp table (animals) --
CREATE TABLE IF NOT EXISTS animals_temp (
    "index" INTEGER,
    animal_id varchar(10) NOT NULL,
    name varchar(100) CONSTRAINT df_name DEFAULT 'Unnamed',
    animal_type_breed_id INTEGER,
    date_of_birth datetime NOT NULL,
    color1 VARCHAR(50),
    color2 VARCHAR(50),
    color1_id INTEGER,
    color2_id INTEGER,
    orig_animal_type VARCHAR(50),
    orig_breed VARCHAR(50),
    orig_animal_type_id INTEGER,
    orig_breed_id INTEGER,

    FOREIGN KEY (animal_type_breed_id) REFERENCES animal_types_breeds(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (color1_id) REFERENCES colors(id),
    FOREIGN KEY (color2_id) REFERENCES colors(id)
);

INSERT INTO animals_temp ("index", animal_id, name, animal_type_breed_id, date_of_birth, color1, color2, color1_id, color2_id, orig_animal_type, orig_breed, orig_animal_type_id, orig_breed_id)
SELECT DISTINCT orig_table."index",
                animals.animal_id,
                animals.name,
                animal_types_breeds.id,
                animals.date_of_birth,
                TRIM(orig_table.color1),
                TRIM(orig_table.color2),
                c1.id,
                c2.id,
                orig_table.animal_type,
                orig_table.breed,
                animal_types.id,
                breeds.id
FROM animals
    JOIN orig_table ON animals.animal_id = orig_table.animal_id
    JOIN animal_types ON orig_table.animal_type = animal_types.animal_type
    JOIN breeds ON orig_table.breed = breeds.breed
    JOIN animal_types_breeds ON animal_types.id = animal_types_breeds.animal_type_id AND breeds.id = animal_types_breeds.breed_id
    JOIN colors as c1 ON TRIM(orig_table.color1) = c1.color
    LEFT OUTER JOIN colors as c2 ON TRIM(orig_table.color2) = c2.color
WHERE animals.animal_id == orig_table.animal_id
ORDER BY orig_table."index";

UPDATE animals_temp SET name = NULL WHERE name == 'no_data';
-- temp table (animals) generated --


UPDATE animals SET (animal_type_breed_id, color1_id, color2_id) =
    (SELECT animals_temp.animal_type_breed_id,
            animals_temp.color1_id,
            animals_temp.color2_id
     FROM animals_temp
     WHERE animals.animal_id == animals_temp.animal_id); -- optimization required, maybe "index" column comparison --
-- Animals table completed --

CREATE INDEX ix_outcome_id ON outcomes (id);
CREATE INDEX ix_animal_id ON animals (id);

-- Cleanup and Delete original and temp databases data from new file --

DROP TABLE IF EXISTS orig_table;
DROP TABLE IF EXISTS outcomes_temp;
DROP TABLE IF EXISTS animals_temp;
VACUUM;


-- Example of many to many normalization --

-- CREATE TABLE IF NOT EXISTS animals_colors (
--     animal_id varchar(10),
--     colors_id INTEGER,
--
--     FOREIGN KEY (animal_id) REFERENCES animals(animal_id),
--     FOREIGN KEY (colors_id) REFERENCES colors(id)
-- );

-- INSERT INTO animals_colors (animal_id, colors_id)
-- SELECT DISTINCT animals_temp.animal_id, colors.id FROM animals_temp
-- JOIN colors ON animals_temp.color1 = colors.color
-- UNION ALL
-- SELECT DISTINCT animals_temp.animal_id, colors.id FROM animals_temp
-- JOIN colors ON animals_temp.color2 = colors.color;
