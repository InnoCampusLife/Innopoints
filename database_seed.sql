USE innopoints;
DELETE FROM Activities;
DELETE FROM Categories;
DELETE FROM Items;
DELETE FROM ItemCategories;
ALTER TABLE Categories AUTO_INCREMENT = 1;
ALTER TABLE ItemCategories AUTO_INCREMENT = 1;
ALTER TABLE Items AUTO_INCREMENT = 1;

INSERT INTO Categories (id, title) VALUES (DEFAULT , 'Категория 1');
INSERT INTO Categories (id, title) VALUES (DEFAULT , 'Категория 2');

INSERT INTO Activities (id, title, comment, for_approval, type, category_id, main_option_exists, additional_exists, price) VALUES (DEFAULT , 'Активность 1', 'Комментарий 1', null, 'hourly', 1, 0, 0, 100);
INSERT INTO Activities (id, title, comment, for_approval, type, category_id, main_option_exists, additional_exists, price) VALUES (DEFAULT , 'Активность 2', 'Комментарий 2', null, 'permanent',  2, 0,0,200);

INSERT INTO ItemCategories (id, title) VALUES (DEFAULT , 'Одежда');

INSERT INTO Items (id, title, option1, value1, option2,
                   value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Рубашка поло', 'Размер', 'S', 'Цвет', 'Черный', NULL, NULL, 2, 900, 1, 0, NULL, NULL );
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Рубашка поло', 'Размер', 'M', 'Цвет', 'Черный', NULL, NULL, 2, 900, 1, 0, NULL, 1);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Рубашка поло', 'Размер', 'S', 'Цвет', 'Желтый', NULL, NULL, 2, 900, 1, 0, NULL, 1);
INSERT INTO Items (id, title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent)
VALUES (DEFAULT, 'Рубашка поло', 'Размер', 'M', 'Цвет', 'Желтый', NULL, NULL, 2, 900, 1, 0, NULL, 1);
