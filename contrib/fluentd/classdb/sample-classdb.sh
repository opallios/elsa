
#!/bin/sh

echo "starting db changes..."

# Settings for json logs
mysql -uroot syslog -e 'INSERT INTO classes (id, class) VALUES (10006, "JSON_LOGS")';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="srcip"), 5)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="srcport"), 6)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="dstip"), 7)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="dstport"), 8)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="conn_bytes"), 9)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="country"), 11)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="latitude"), 12)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="JSON_LOGS"), (SELECT id FROM fields WHERE field="longitude"), 13)';

echo "db changes done for json..."

#Settings for Apachelogs
mysql -uroot syslog -e 'INSERT INTO classes (id, class) VALUES (10005, "APACHE_LOGS")';

mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="srcip"), 5)';

mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="status_code"), 6)';

mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="content_length"), 7)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="user"), 11)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="method"), 12)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="path"), 13)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="referer"), 14)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="APACHE_LOGS"), (SELECT id FROM fields WHERE field="user_agent"), 15)';
echo "db changes done for Apache..."

#Settings for custom logs 
mysql -uroot syslog -e 'INSERT INTO classes (id, class) VALUES (10001, "ODELOGS")';
mysql -uroot syslog -e 'INSERT INTO fields (field, field_type, pattern_type) VALUES ("sname", "string", "QSTRING")';
mysql -uroot syslog -e 'INSERT INTO fields (field, field_type, pattern_type) VALUES ("sseverity","string", "QSTRING")';
mysql -uroot syslog -e 'INSERT INTO fields (field, field_type, pattern_type) VALUES ("eventid","int", "NUMBER")';   
#this may give duplicate error, ignore it.
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES ((SELECT id FROM classes WHERE class="ODELOGS"), (SELECT id FROM fields WHERE field="sname"), 11)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES  ((SELECT id FROM classes WHERE class="ODELOGS"), (SELECT id FROM fields WHERE field="sseverity"), 12)';
mysql -uroot syslog -e 'INSERT INTO fields_classes_map (class_id, field_id, field_order)
VALUES  ((SELECT id FROM classes WHERE class="ODELOGS"), (SELECT id FROM fields WHERE field="eventid"), 5)';

echo "db changes done for Custom Messages..."