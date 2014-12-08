/**
 * @signature d7480e1c31a1f20d6954ecbb342722d3
 * @version v1.9.5
 * @title Make editable content translatable
 *
 * This patch adds support for translatable administratively editable
 * content, such as help topic names, department and group names, site page
 * and faq content, etc.
 *
 * This patch also transitions from the timezone table to the Olson timezone
 * database available in PHP 5.3.
 */

ALTER TABLE `%TABLE_PREFIX%attachment`
    ADD `lang` varchar(16) AFTER `inline`;

ALTER TABLE `%TABLE_PREFIX%faq`
    ADD `views` int(10) unsigned NOT NULL default '0' AFTER `notes`,
    ADD `score` int(10) NOT NULL default '0' AFTER `views`;

ALTER TABLE `%TABLE_PREFIX%staff`
    ADD `lang` varchar(16) DEFAULT NULL AFTER `signature`,
    ADD `timezone` varchar(64) default NULL AFTER `lang`,
    ADD `locale` varchar(16) DEFAULT NULL AFTER `locale`,
    ADD `extra` text AFTER `default_paper_size`;

ALTER TABLE `%TABLE_PREFIX%user_account`
    ADD `timezone` varchar(64) DEFAULT NULL AFTER `status`,
    ADD `extra` text AFTER `backend`;

DROP TABLE IF EXISTS `%TABLE_PREFIX%translation`;
CREATE TABLE `%TABLE_PREFIX%translation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `object_hash` char(16) CHARACTER SET ascii DEFAULT NULL,
  `type` enum('phrase','article','override') DEFAULT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT '0',
  `revision` int(11) unsigned DEFAULT NULL,
  `agent_id` int(10) unsigned NOT NULL DEFAULT '0',
  `lang` varchar(16) NOT NULL DEFAULT '',
  `text` mediumtext NOT NULL,
  `source_text` text,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `type` (`type`,`lang`),
  KEY `object_hash` (`object_hash`)
) DEFAULT CHARSET=utf8;

-- Transition the current Timezone configuration to Olsen database

CREATE TABLE `%TABLE_PREFIX%_timezones` (
    `offset` int,
    `dst` tinyint(1) unsigned,
    `south` tinyint(1) unsigned default 0,
    `olson_name` varchar(32) 
) DEFAULT CHARSET=utf8;

INSERT INTO `%TABLE_PREFIX%_timezones` (`offset`, `dst`, `olson_name`) VALUES
    -- source borrowed from the jstz project
    (-720, 0, 'Pacific/Majuro'),
    (-660, 0, 'Pacific/Pago_Pago'),
    (-600, 1, 'America/Adak'),
    (-600, 0, 'Pacific/Honolulu'),
    (-570, 0, 'Pacific/Marquesas'),
    (-540, 0, 'Pacific/Gambier'),
    (-540, 1, 'America/Anchorage'),
    (-480, 1, 'America/Los_Angeles'),
    (-480, 0, 'Pacific/Pitcairn'),
    (-420, 0, 'America/Phoenix'),
    (-420, 1, 'America/Denver'),
    (-360, 0, 'America/Guatemala'),
    (-360, 1, 'America/Chicago'),
    (-300, 0, 'America/Bogota'),
    (-300, 1, 'America/New_York'),
    (-270, 0, 'America/Caracas'),
    (-240, 1, 'America/Halifax'),
    (-240, 0, 'America/Santo_Domingo'),
    (-240, 1, 'America/Santiago'),
    (-210, 1, 'America/St_Johns'),
    (-180, 1, 'America/Godthab'),
    (-180, 0, 'America/Argentina/Buenos_Aires'),
    (-180, 1, 'America/Montevideo'),
    (-120, 0, 'America/Noronha'),
    (-120, 1, 'America/Noronha'),
    (-60,  1, 'Atlantic/Azores'),
    (-60,  0, 'Atlantic/Cape_Verde'),
    (0,    0, 'UTC'),
    (0,    1, 'Europe/London'),
    (60,   1, 'Europe/Berlin'),
    (60,   0, 'Africa/Lagos'),
    (120,  1, 'Asia/Beirut'),
    (120,  0, 'Africa/Johannesburg'),
    (180,  0, 'Asia/Baghdad'),
    (180,  1, 'Europe/Moscow'),
    (210,  1, 'Asia/Tehran'),
    (240,  0, 'Asia/Dubai'),
    (240,  1, 'Asia/Baku'),
    (270,  0, 'Asia/Kabul'),
    (300,  1, 'Asia/Yekaterinburg'),
    (300,  0, 'Asia/Karachi'),
    (330,  0, 'Asia/Kolkata'),
    (345,  0, 'Asia/Kathmandu'),
    (360,  0, 'Asia/Dhaka'),
    (360,  1, 'Asia/Omsk'),
    (390,  0, 'Asia/Rangoon'),
    (420,  1, 'Asia/Krasnoyarsk'),
    (420,  0, 'Asia/Jakarta'),
    (480,  0, 'Asia/Shanghai'),
    (480,  1, 'Asia/Irkutsk'),
    (525,  0, 'Australia/Eucla'),
    (525,  1, 'Australia/Eucla'),
    (540,  1, 'Asia/Yakutsk'),
    (540,  0, 'Asia/Tokyo'),
    (570,  0, 'Australia/Darwin'),
    (570,  1, 'Australia/Adelaide'),
    (600,  0, 'Australia/Brisbane'),
    (600,  1, 'Asia/Vladivostok'),
    (630,  1, 'Australia/Lord_Howe'),
    (660,  1, 'Asia/Kamchatka'),
    (660,  0, 'Pacific/Noumea'),
    (690,  0, 'Pacific/Norfolk'),
    (720,  1, 'Pacific/Auckland'),
    (720,  0, 'Pacific/Tarawa'),
    (765,  1, 'Pacific/Chatham'),
    (780,  0, 'Pacific/Tongatapu'),
    (780,  1, 'Pacific/Apia'),
    (840,  0, 'Pacific/Kiritimati');

-- XXX:
-- These zone have opposite DST interpretations and also have norther
-- hemisphere counterparts
INSERT INTO `%TABLE_PREFIX%_timezones` (`offset`, `dst`, `south`, `olson_name`) VALUES
    (-360, 1, 1, 'Pacific/Easter'),
    (60,   1, 1, 'Africa/Windhoek'),
    (600,  1, 1, 'Australia/Sydney');

UPDATE `%TABLE_PREFIX%staff` A1
    JOIN `%TABLE_PREFIX%timezone` A2 ON (A1.`timezone_id` = A2.`id`)
    JOIN `%TABLE_PREFIX%_timezones` A3 ON (A2.`offset` * 60 = A3.`offset`
        AND A1.`daylight_saving` = A3.`dst`
        AND A3.`south` = 0)
    SET A1.`timezone` = A3.`olson_name`;

UPDATE `%TABLE_PREFIX%user_account` A1
    JOIN `%TABLE_PREFIX%timezone` A2 ON (A1.`timezone_id` = A2.`id`)
    JOIN `%TABLE_PREFIX%_timezones` A3 ON (A2.`offset` * 60 = A3.`offset`
        AND A1.`dst` = A3.`dst`
        AND A3.`south` = 0)
    SET A1.`timezone` = A3.`olson_name`;

DROP TABLE %TABLE_PREFIX%_timezones;

-- Finished with patch
UPDATE `%TABLE_PREFIX%config`
    SET `value` = 'd7480e1c31a1f20d6954ecbb342722d3'
    WHERE `key` = 'schema_signature' AND `namespace` = 'core';