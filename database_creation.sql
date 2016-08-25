CREATE DATABASE IF NOT EXISTS innopoints DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

# CREATE USER IF NOT EXISTS 'innopoints_user'@'localhost' IDENTIFIED BY 'innopoints2.0';

GRANT ALL ON innopoints.* TO 'innopoints_user'@'%' IDENTIFIED BY 'innopoints2.0';

USE innopoints;

CREATE TABLE IF NOT EXISTS Accounts (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner INT NOT NULL UNIQUE,
  type ENUM('student', 'admin'),
  points_amount INT,
  creation_date TIMESTAMP NOT NULL
);
CREATE TABLE IF NOT EXISTS Transactions (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id INT,
  amount INT NOT NULL,
  amount_to_spend INT NOT NULL ,
  receiving_date TIMESTAMP NOT NULL,
  expiration_date TIMESTAMP NOT NULL ,
  status ENUM('active', 'expired', 'spent'),
  FOREIGN KEY (account_id) REFERENCES Accounts(id)
);
CREATE TABLE IF NOT EXISTS  Categories (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS  Activities (
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

CREATE TABLE IF NOT EXISTS  MainPointsOptions ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  points_option TEXT
);

CREATE TABLE IF NOT EXISTS  MainPointsValues ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  option_id int,
  activity_id int not NULL,
  value INT NOT NULL,
  comment TEXT,
  FOREIGN KEY (option_id) REFERENCES MainPointsOptions(id),
  FOREIGN KEY (activity_id) REFERENCES Activities(id)
);

CREATE TABLE IF NOT EXISTS AdditionalPointsOptions ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  points_option TEXT
);

CREATE TABLE IF NOT EXISTS AdditionalPointsValues ( # for version 2.0
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  option_id int ,
  activity_id int NOT NULL ,
  value INT NOT NULL ,
  comment TEXT,
  FOREIGN KEY (option_id) REFERENCES AdditionalPointsOptions(id),
  FOREIGN KEY (activity_id) REFERENCES Activities(id)
);

CREATE TABLE IF NOT EXISTS Applications (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  author INT NOT NULL ,
  type ENUM('personal', 'group'),
  comment TEXT,
  status ENUM('rejected', 'approved', 'in_process', 'rework'),
  creation_date TIMESTAMP NOT NULL,
  FOREIGN KEY (author) REFERENCES Accounts(id)
);
CREATE TABLE IF NOT EXISTS Works (
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
CREATE TABLE IF NOT EXISTS Files (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  filename TEXT NOT NULL ,
  type TEXT NOT NULL ,
  download_link TEXT NOT NULL,
  application_id INT,
  FOREIGN KEY (application_id) REFERENCES Applications(id)
);

CREATE TABLE IF NOT EXISTS ItemCategories (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  title VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Items (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  title VARCHAR(255) NOT NULL ,
  option1 VARCHAR(255),
  value1 VARCHAR(255),
  option2 VARCHAR(255),
  value2 VARCHAR(255),
  option3 VARCHAR(255),
  value3 VARCHAR(255),
  quantity int,
  price int NOT NULL,
  category_id INT NOT NULL,
  possible_joint_purchase BOOLEAN,
  max_buyers INT,
  parent INT,
  FOREIGN KEY (category_id) REFERENCES ItemCategories(id)
);

CREATE TABLE IF NOT EXISTS Orders (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  status ENUM('in_process', 'approved', 'rejected', 'waiting_to_process'),
  creation_date TIMESTAMP NOT NULL ,
  is_joint_purchase BOOLEAN NOT NULL ,
  account_id int NOT NULL ,
  total_price int NOT NULL ,
  FOREIGN KEY (account_id) REFERENCES Accounts(id)
);

CREATE TABLE IF NOT EXISTS ItemsInOrder (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  order_id int NOT NULL ,
  item_id int NOT NULL ,
  amount int,
  FOREIGN KEY (order_id) REFERENCES Orders(id),
  FOREIGN KEY (item_id) REFERENCES Items(id)
);

CREATE TABLE IF NOT EXISTS  OrderContributors (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  order_id int NOT NULL ,
  account_id int NOT NULL ,
  points_amount int NOT NULL ,
  is_agreed BOOLEAN NOT NULL,
  FOREIGN KEY (order_id) REFERENCES Orders(id),
  FOREIGN KEY (account_id) REFERENCES Accounts(id)
);

CREATE TABLE IF NOT EXISTS  ReservedPointsToOrder (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
  order_id INT NOT NULL ,
  account_id INT NOT NULL ,
  points_amount INT NOT NULL ,
  FOREIGN KEY (order_id) REFERENCES Orders(id),
  FOREIGN KEY (account_id) REFERENCES Accounts(id)
)




# DROP TABLE Items, ItemCategories, Files, Works, Applications, AdditionalPointsValues, AdditionalPointsOptions, MainPointsValues, MainPointsOptions, Activities, Categories, Transactions, Accounts;
# drop DATABASE innopoints;
# CREATE DATABASE innopoints;