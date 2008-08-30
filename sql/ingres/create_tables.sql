/*
 Copyright (C) 2006 DBMail.EU Paul J Stevens

 This program is free software; you can redistribute it and/or 
 modify it under the terms of the GNU General Public License 
 as published by the Free Software Foundation; either 
 version 2 of the License, or (at your option) any later 
 version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
/* $Id: create_tables.sql 2376 2006-11-17 12:33:12Z paul $
*/

BEGIN TRANSACTION;

CREATE SEQUENCE dbmail_alias_idnr_seq;
CREATE TABLE dbmail_aliases (
    alias_idnr INT8 NOT NULL,
    alias VARCHAR(100) NOT NULL, 
    deliver_to VARCHAR(250) NOT NULL,
    client_idnr INT8 DEFAULT 0 NOT NULL,
    PRIMARY KEY (alias_idnr)
);
CREATE INDEX dbmail_aliases_alias_idx ON dbmail_aliases(alias);

CREATE SEQUENCE dbmail_user_idnr_seq;
CREATE TABLE dbmail_users (
   user_idnr INT8 NOT NULL,
   userid VARCHAR(100) NOT NULL,
   passwd VARCHAR(34) NOT NULL,
   client_idnr INT8 DEFAULT 0 NOT NULL,
   maxmail_size INT8 DEFAULT 0 NOT NULL,
   curmail_size INT8 DEFAULT 0 NOT NULL,
   maxsieve_size INT8 DEFAULT 0 NOT NULL,
   cursieve_size INT8 DEFAULT 0 NOT NULL,
   encryption_type VARCHAR(20) DEFAULT '' NOT NULL,
   last_login date NOT NULL,
   PRIMARY KEY (user_idnr)
);

CREATE UNIQUE INDEX dbmail_users_name_idx ON dbmail_users(userid);

CREATE TABLE dbmail_usermap (
  login VARCHAR(100) NOT NULL,
  sock_allow varchar(100) NOT NULL,
  sock_deny varchar(100) NOT NULL,
  userid varchar(100) NOT NULL
);
CREATE UNIQUE INDEX usermap_idx_1 ON dbmail_usermap(login, sock_allow, userid);

CREATE SEQUENCE dbmail_mailbox_idnr_seq;
CREATE TABLE dbmail_mailboxes (
   mailbox_idnr INT8 NOT NULL,
   owner_idnr INT8 REFERENCES dbmail_users(user_idnr) ON DELETE CASCADE ON UPDATE CASCADE,
   name VARCHAR(100) NOT NULL,
   seen_flag INT2 DEFAULT 0 NOT NULL,
   answered_flag INT2 DEFAULT 0 NOT NULL,
   deleted_flag INT2 DEFAULT 0 NOT NULL,
   flagged_flag INT2 DEFAULT 0 NOT NULL,
   recent_flag INT2 DEFAULT 0 NOT NULL,
   draft_flag INT2 DEFAULT 0 NOT NULL,
   no_inferiors INT2 DEFAULT 0 NOT NULL,
   no_select INT2 DEFAULT 0 NOT NULL,
   permission INT2 DEFAULT 2 NOT NULL,
   PRIMARY KEY (mailbox_idnr)
);
CREATE INDEX dbmail_mailboxes_owner_idx ON dbmail_mailboxes(owner_idnr);
CREATE INDEX dbmail_mailboxes_name_idx ON dbmail_mailboxes(name);
CREATE UNIQUE INDEX dbmail_mailboxes_owner_name_idx 
	ON dbmail_mailboxes(owner_idnr, name);

CREATE TABLE dbmail_subscription (
   user_id INT8 NOT NULL REFERENCES dbmail_users(user_idnr) ON DELETE CASCADE ON UPDATE CASCADE,
   mailbox_id INT8 NOT NULL REFERENCES dbmail_mailboxes(mailbox_idnr)
	ON DELETE CASCADE ON UPDATE CASCADE,
   PRIMARY KEY (user_id, mailbox_id)
);

CREATE TABLE dbmail_acl (
    user_id INT8 NOT NULL REFERENCES dbmail_users(user_idnr) ON DELETE CASCADE ON UPDATE CASCADE,
    mailbox_id INT8 NOT NULL REFERENCES dbmail_mailboxes(mailbox_idnr)
	ON DELETE CASCADE ON UPDATE CASCADE,
    lookup_flag INT2 DEFAULT 0 NOT NULL,
    read_flag INT2 DEFAULT 0 NOT NULL,
    seen_flag INT2 DEFAULT 0 NOT NULL,
    write_flag INT2 DEFAULT 0 NOT NULL,
    insert_flag INT2 DEFAULT 0 NOT NULL,
    post_flag INT2 DEFAULT 0 NOT NULL,
    create_flag INT2 DEFAULT 0 NOT NULL,
    delete_flag INT2 DEFAULT 0 NOT NULL,
    administer_flag INT2 DEFAULT 0 NOT NULL,
    PRIMARY KEY (user_id, mailbox_id)
);

CREATE SEQUENCE dbmail_physmessage_id_seq;
CREATE TABLE dbmail_physmessage (
   id INT8 NOT NULL,
   messagesize INT8 DEFAULT 0 NOT NULL,   
   rfcsize INT8 DEFAULT 0 NOT NULL,
   internal_date date not null,
   PRIMARY KEY(id)
);

CREATE SEQUENCE dbmail_message_idnr_seq;
CREATE TABLE dbmail_messages (
   message_idnr INT8 NOT NULL,
   mailbox_idnr INT8 NOT NULL REFERENCES dbmail_mailboxes(mailbox_idnr)
	ON DELETE CASCADE ON UPDATE CASCADE,
   physmessage_id INT8 NOT NULL REFERENCES dbmail_physmessage(id)
	ON DELETE CASCADE ON UPDATE CASCADE,
   seen_flag INT2 DEFAULT 0 NOT NULL,
   answered_flag INT2 DEFAULT 0 NOT NULL,
   deleted_flag INT2 DEFAULT 0 NOT NULL,
   flagged_flag INT2 DEFAULT 0 NOT NULL,
   recent_flag INT2 DEFAULT 0 NOT NULL,
   draft_flag INT2 DEFAULT 0 NOT NULL,
   unique_id varchar(70) NOT NULL,
   status INT2 DEFAULT 0 NOT NULL,
   PRIMARY KEY (message_idnr)
);
CREATE INDEX dbmail_messages_1 ON dbmail_messages(mailbox_idnr);
CREATE INDEX dbmail_messages_2 ON dbmail_messages(physmessage_id);
CREATE INDEX dbmail_messages_3 ON dbmail_messages(seen_flag);
CREATE INDEX dbmail_messages_4 ON dbmail_messages(unique_id);
CREATE INDEX dbmail_messages_5 ON dbmail_messages(status);
/* CREATE INDEX dbmail_messages_6 ON dbmail_messages(status) WITH range=(0,0),(2,2)); */
CREATE INDEX dbmail_messages_7 ON dbmail_messages(mailbox_idnr,status,seen_flag);
CREATE INDEX dbmail_messages_8 ON dbmail_messages(mailbox_idnr,status,recent_flag);

CREATE SEQUENCE dbmail_messageblk_idnr_seq;
CREATE TABLE dbmail_messageblks (
   messageblk_idnr INT8 NOT NULL,
   physmessage_id INT8 NOT NULL REFERENCES dbmail_physmessage(id)
	ON DELETE CASCADE ON UPDATE CASCADE,
   messageblk LONG BYTE NOT NULL,
   blocksize INT8 DEFAULT 0 NOT NULL,
   is_header INT2 DEFAULT 0 NOT NULL,
   PRIMARY KEY (messageblk_idnr)
);
CREATE INDEX dbmail_mblks_p_idx 
	ON dbmail_messageblks(physmessage_id);
CREATE INDEX dbmail_mblks_p_ishdr_idx 
	ON dbmail_messageblks(physmessage_id, is_header);

CREATE TABLE dbmail_auto_notifications (
   user_idnr INT8 NOT NULL REFERENCES dbmail_users(user_idnr) ON DELETE CASCADE ON UPDATE CASCADE,
   notify_address VARCHAR(100),
   PRIMARY KEY (user_idnr)
);

CREATE TABLE dbmail_auto_replies (
   user_idnr INT8 NOT NULL REFERENCES dbmail_users (user_idnr) ON DELETE CASCADE ON UPDATE CASCADE,
   start_date date not null,
   stop_date date not null,
   reply_body TEXT,
   PRIMARY KEY (user_idnr)
);

CREATE SEQUENCE dbmail_seq_pbsp_id;
CREATE TABLE dbmail_pbsp (
  idnr INT8 NOT NULL,
  since date not null,
  ipnumber char(32) NOT NULL DEFAULT '0.0.0.0',
  PRIMARY KEY (idnr)
);
CREATE UNIQUE INDEX dbmail_idx_ipnumber ON dbmail_pbsp (ipnumber);
CREATE INDEX dbmail_idx_since ON dbmail_pbsp (since);

--- Create the user for the delivery chain:
INSERT INTO dbmail_users (user_idnr,userid, passwd, encryption_type) 
	VALUES (dbmail_users_idnr_seq.nextval,'__@!internal_delivery_user!@__', '', 'md5');
--- Create the 'anyone' user which is used for ACLs.
INSERT INTO dbmail_users (user_idnr,userid, passwd, encryption_type) 
	VALUES (dbmail_users_idnr_seq.nextval,'anyone', '', 'md5');
--- Create the user to own #Public mailboxes
INSERT INTO dbmail_users (user_idnr,userid, passwd, encryption_type) 
	VALUES (dbmail_users_idnr_seq.nextval,'__public__', '', 'md5');

 


CREATE SEQUENCE dbmail_headername_idnr_seq;
CREATE TABLE dbmail_headername (
	id		INT8 NOT NULL,
	headername	VARCHAR(100) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_headername_1 on dbmail_headername(headername);


CREATE SEQUENCE dbmail_headervalue_idnr_seq;
CREATE TABLE dbmail_headervalue (
	headername_id	INT8 NOT NULL
		REFERENCES dbmail_headername(id)
		ON UPDATE CASCADE ON DELETE CASCADE,
        physmessage_id	INT8 NOT NULL
		REFERENCES dbmail_physmessage(id)
		ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	headervalue	TEXT NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_headervalue_1 ON dbmail_headervalue(physmessage_id, id);


CREATE SEQUENCE dbmail_subjectfield_idnr_seq;
CREATE TABLE dbmail_subjectfield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	subjectfield	VARCHAR(255) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_subjectfield_1 ON dbmail_subjectfield(physmessage_id, id);


CREATE SEQUENCE dbmail_datefield_idnr_seq;
CREATE TABLE dbmail_datefield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	datefield	DATE NOT NULL,
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_datefield_1 ON dbmail_datefield(physmessage_id, id);

CREATE SEQUENCE dbmail_referencesfield_idnr_seq;
CREATE TABLE dbmail_referencesfield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id) 
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	referencesfield	VARCHAR(255) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_referencesfield_1 ON dbmail_referencesfield(physmessage_id, referencesfield);


CREATE SEQUENCE dbmail_fromfield_idnr_seq;
CREATE TABLE dbmail_fromfield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	fromname	VARCHAR(100) NOT NULL DEFAULT '',
	fromaddr	VARCHAR(100) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_fromfield_1 ON dbmail_fromfield(physmessage_id, id);

CREATE SEQUENCE dbmail_tofield_idnr_seq;
CREATE TABLE dbmail_tofield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	toname		VARCHAR(100) NOT NULL DEFAULT '',
	toaddr		VARCHAR(100) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_tofield_1 ON dbmail_tofield(physmessage_id, id);

CREATE SEQUENCE dbmail_replytofield_idnr_seq;
CREATE TABLE dbmail_replytofield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	replytoname	VARCHAR(100) NOT NULL DEFAULT '',
	replytoaddr	VARCHAR(100) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_replytofield_1 ON dbmail_replytofield(physmessage_id, id);

CREATE SEQUENCE dbmail_ccfield_idnr_seq;
CREATE TABLE dbmail_ccfield (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	ccname		VARCHAR(100) NOT NULL DEFAULT '',
	ccaddr		VARCHAR(100) NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_ccfield_1 ON dbmail_ccfield(physmessage_id, id);

CREATE TABLE dbmail_replycache (
    to_addr varchar(100) DEFAULT '' NOT NULL,
    from_addr varchar(100) DEFAULT '' NOT NULL,
    handle    varchar(100) DEFAULT '',
    lastseen date NOT NULL
);
CREATE UNIQUE INDEX replycache_1 ON dbmail_replycache (to_addr, from_addr, handle) with structure= btree ;

CREATE SEQUENCE dbmail_sievescripts_idnr_seq;
CREATE TABLE dbmail_sievescripts (
	id		INT8 NOT NULL,
        owner_idnr	INT8 NOT NULL
			REFERENCES dbmail_users(user_idnr)
			ON UPDATE CASCADE ON DELETE CASCADE,
	active		INT2 DEFAULT 0 NOT NULL,
	name		VARCHAR(100) NOT NULL DEFAULT '',
	script		TEXT NOT NULL DEFAULT '',
	PRIMARY KEY	(id)
);

CREATE INDEX dbmail_sievescripts_1 on dbmail_sievescripts(owner_idnr,name);
CREATE INDEX dbmail_sievescripts_2 on dbmail_sievescripts(owner_idnr,active);

CREATE SEQUENCE dbmail_envelope_idnr_seq;
CREATE TABLE dbmail_envelope (
        physmessage_id  INT8 NOT NULL
			REFERENCES dbmail_physmessage(id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	id		INT8 NOT NULL,
	envelope	TEXT NOT NULL DEFAULT '',
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX dbmail_envelope_1 ON dbmail_envelope(physmessage_id, id);


COMMIT;


