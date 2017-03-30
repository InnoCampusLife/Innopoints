USE innopoints;

DELETE FROM OrderContributors;
ALTER TABLE OrderContributors AUTO_INCREMENT = 1;
DELETE FROM ItemsInOrder;
ALTER TABLE ItemsInOrder AUTO_INCREMENT = 1;
DELETE FROM Orders;
ALTER TABLE Orders AUTO_INCREMENT = 1;
DELETE FROM Items;
ALTER TABLE Items AUTO_INCREMENT = 1;
DELETE FROM ItemCategories;
ALTER TABLE ItemCategories AUTO_INCREMENT = 1;
DELETE FROM Files;
ALTER TABLE Files AUTO_INCREMENT = 1;
DELETE FROM Works;
ALTER TABLE Works AUTO_INCREMENT = 1;
DELETE FROM ReworkComments;
ALTER TABLE ReworkComments AUTO_INCREMENT = 1;
DELETE FROM Applications;
ALTER TABLE Applications AUTO_INCREMENT = 1;
DELETE FROM Activities;
ALTER TABLE Activities AUTO_INCREMENT = 1;
DELETE FROM Categories;
ALTER TABLE Categories AUTO_INCREMENT = 1;
DELETE FROM Transactions;
ALTER TABLE Transactions AUTO_INCREMENT = 1;

INSERT INTO Categories (id, title) VALUES (DEFAULT , 'Category 1');
INSERT INTO Categories (id, title) VALUES (DEFAULT , 'Category 2');

INSERT INTO Activities (id, title, comment, for_approval, type, category_id, main_option_exists, additional_exists, price) VALUES (DEFAULT , 'Activity 1', 'Comment 1', null, 'hourly', 1, 0, 0, 100);
INSERT INTO Activities (id, title, comment, for_approval, type, category_id, main_option_exists, additional_exists, price) VALUES (DEFAULT , 'Activity 2', 'Comment 2', null, 'permanent',  2, 0,0,200);

INSERT INTO ItemCategories (id, title) VALUES (DEFAULT , 'Clothes');
INSERT INTO ItemCategories (id, title) VALUES (DEFAULT , 'Food');
INSERT INTO ItemCategories (id, title) VALUES (DEFAULT , 'Other');

INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Polo shirt', 'Size', 'S', 'Colour', 'Black', NULL, NULL, 10000, 900, 1, 0, NULL, NULL );
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Polo shirt', 'Size', 'M', 'Colour', 'Black', NULL, NULL, 10000, 900, 1, 0, NULL, 1);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Polo shirt', 'Size', 'S', 'Colour', 'Yellow', NULL, NULL, 10000, 900, 1, 0, NULL, 1);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Polo shirt', 'Size', 'M', 'Colour', 'Yellow', NULL, NULL, 10000, 900, 1, 0, NULL, 1);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Pizza', null, null, null, null, null, null, 10000, 500, 2, 1, 2, null);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Pasta', null, null, null, null, null, null, 10000, 300, 2, 1, 2, null);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Wok', null, null, null, null, null, null, 10000, 600, 2, 1, 2, null);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Canvas bag', 'Colour', 'Brown', NULL, NULL, NULL, NULL, 10000, 250, 3, 0, NULL, NULL );
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Canvas bag', 'Colour', 'Red', NULL, NULL, NULL, NULL, 10000, 250, 3, 0, NULL, 8 );
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Canvas bag', 'Colour', 'Brown', NULL, NULL, NULL, NULL, 10000, 250, 3, 0, NULL, 8 );
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Notebook', 'Colour', 'Brown', NULL, NULL, NULL, NULL, 10000, 250, 3, 0, NULL, NULL );
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Notebook', 'Colour', 'Grey', NULL, NULL, NULL, NULL, 10000, 250, 3, 0, NULL, 11);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Notebook', 'Colour', 'Green', NULL, NULL, NULL, NULL, 10000, 250, 3, 0, NULL, 11);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Thermal mug', NULL, NULL, NULL, NULL, NULL, NULL, 10000, 450, 3, 0, NULL, NULL );