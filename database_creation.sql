CREATE DATABASE innopoints DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

CREATE USER 'innopoints_user'@'localhost' IDENTIFIED BY 'innopoints2.0';

GRANT ALL ON innopoints.* TO 'innopoints_user'@'localhost';

USE innopoints;

CREATE TABLE Accounts (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner INT NOT NULL UNIQUE,
  points_amount INT,
  creation_date TIMESTAMP NOT NULL
);
CREATE TABLE Transactions (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id INT,
  amount INT NOT NULL,
  amount_to_spend INT NOT NULL ,
  receiving_date TIMESTAMP NOT NULL,
  expiration_date TIMESTAMP NOT NULL ,
  status ENUM('active', 'expired', 'spent'),
  FOREIGN KEY (account_id) REFERENCES Accounts(id)
);
CREATE TABLE Categories (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL UNIQUE
);
CREATE TABLE Activities (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  title TEXT NOT NULL,
  comment TEXT,
  for_approval TEXT,
  type ENUM('hourly', 'permanent', 'quantity'),
  category_id INT,
  main_option_exists BOOLEAN, # for version 2.0
  additional_exists BOOLEAN, # for version 2.0
  price int, #for version 1.0
  FOREIGN KEY (category_id) REFERENCES Categories(id)
);

CREATE TABLE MainPointsOptions ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  points_option TEXT
);

CREATE TABLE MainPointsValues ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  option_id int,
  activity_id int not NULL,
  value INT NOT NULL,
  comment TEXT,
  FOREIGN KEY (option_id) REFERENCES MainPointsOptions(id),
  FOREIGN KEY (activity_id) REFERENCES Activities(id)
);

CREATE TABLE AdditionalPointsOptions ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  points_option TEXT
);

CREATE TABLE AdditionalPointsValues ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  option_id int ,
  activity_id int NOT NULL ,
  value INT NOT NULL ,
  comment TEXT,
  FOREIGN KEY (option_id) REFERENCES AdditionalPointsOptions(id),
  FOREIGN KEY (activity_id) REFERENCES Activities(id)
);

CREATE TABLE Applications (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  author INT NOT NULL ,
  type ENUM('personal', 'group'),
  comment TEXT,
  status ENUM('rejected', 'approved', 'in_process', 'rework'),
  creation_date TIMESTAMP NOT NULL,
  FOREIGN KEY (author) REFERENCES Accounts(id)
);
CREATE TABLE Works (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  actor INT NOT NULL ,
  activity_id INT,
  main_points_value_id int, # for version  2.0
  additional_points_value_id int, # for version 2.0
  amount INT,
  application_id INT,
  FOREIGN KEY (actor) REFERENCES Accounts(id),
  FOREIGN KEY (activity_id) REFERENCES Activities(id),
  FOREIGN KEY (application_id) REFERENCES Applications(id)
);
CREATE TABLE Files (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  filename TEXT NOT NULL ,
  type TEXT NOT NULL ,
  download_link TEXT NOT NULL,
  application_id INT,
  FOREIGN KEY (application_id) REFERENCES Applications(id)
);

CREATE TABLE ItemCategories (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Items (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  name VARCHAR(255) NOT NULL ,
  option1 VARCHAR(255),
  value1 VARCHAR(255),
  option2 VARCHAR(255),
  value2 VARCHAR(255),
  option3 VARCHAR(255),
  value3 VARCHAR(255),
  quantity int,
  price int NOT NULL
);

# DROP TABLE Items, ItemCategories, Files, Works, Applications, AdditionalPointsValues, AdditionalPointsOptions, MainPointsValues, MainPointsOptions, Activities, Categories, Transactions, Accounts;
# drop DATABASE innopoints;
# CREATE DATABASE innopoints;