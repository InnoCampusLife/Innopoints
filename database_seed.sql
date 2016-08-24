USE innopoints;

INSERT INTO Categories (id, title) VALUES (DEFAULT , 'Категория 1');
INSERT INTO Categories (id, title) VALUES (DEFAULT , 'Категория 2');

INSERT INTO Activities (id, title, comment, for_approval, type, category_id, main_option_exists, additional_exists, price) VALUES (DEFAULT , 'Активность 1', 'Комментарий 1', null, 'hourly', 1, 0, 0, 100);
INSERT INTO Activities (id, title, comment, for_approval, type, category_id, main_option_exists, additional_exists, price) VALUES (DEFAULT , 'Активность 2', 'Комментарий 2', null, 'permanent',  2, 0,0,200);


