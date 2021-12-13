#!/soft/XCI-Usage-Viz/python/bin/python3
import argparse
import csv
from datetime import datetime
import fnmatch
import gzip
import json
import logging
import logging.handlers
import os
import psycopg2
import psycopg2.extras
import pwd
import signal
import sys
import uuid
import pdb

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class DBLoad():
    def __init__(self):
        # Variales that must be defined
        self.IN_FD = None
        self.ROWS_AFTER = 0

        parser = argparse.ArgumentParser()
        parser.add_argument('file', type=str, nargs='?')
        parser.add_argument('-c', '--config', action='store', default='./batch_dbload.conf', \
                            help='Configuration file default=./batch_dbload.conf')
        parser.add_argument('-b', '--batch', action='store', required=True, \
                            help='Batch tag')
        parser.add_argument('-l', '--log', action='store',
                            help='Logging level (default=warning)')
        parser.add_argument('--deleteonly', action='store_true', \
                            help='Delete batch and exit without loading')
        parser.add_argument('--reload', action='store_true', \
                            help='Delete batch before loading')
        parser.add_argument('--verbose', action='store_true', \
                            help='Verbose output')
        parser.add_argument('--pdb', action='store_true', \
                            help='Run with Python debugger')
        self.args = parser.parse_args()

        if self.args.pdb:
            pdb.set_trace()

        config_path = os.path.abspath(self.args.config)
        try:
            with open(config_path, 'r') as cf:
                self.config = json.load(cf)
        except ValueError as e:
            eprint('ERROR "{}" parsing config={}'.format(e, config_path))
            self.exit(1)

    def Setup(self):
        # Initialize logging from arguments or config file, with WARNING level as default
        numeric_log = None
        if self.args.log is not None:
            numeric_log = getattr(logging, self.args.log.upper(), None)
        if numeric_log is None and self.config.get('LOG_LEVEL'):
            numeric_log = getattr(logging, self.config['LOG_LEVEL'].upper(), None)
        if numeric_log is None:
            numeric_log = getattr(logging, 'WARNING', None)
        if not isinstance(numeric_log, int):
            raise ValueError('Invalid log level: {}'.format(numeric_log))
        self.logger = logging.getLogger('DaemonLog')
        self.logger.setLevel(numeric_log)
        program = os.path.basename(__file__)
        self.formatter = logging.Formatter(fmt='%(asctime)s.%(msecs)03d %(levelname)s {} %(message)s'.format(program),
                                           datefmt='%Y/%m/%d %H:%M:%S')
        
        LOGFILE = self.config.get('LOG_FILE', 'stdout')
        if LOGFILE.lower() == 'stdout':
            self.handler = logging.StreamHandler(sys.stdout)
        else:
            self.handler = logging.FileHandler(self.config['LOG_FILE'])
        self.handler.setFormatter(self.formatter)
        self.logger.addHandler(self.handler)

        signal.signal(signal.SIGINT, self.exit_signal)
        signal.signal(signal.SIGTERM, self.exit_signal)

        mode = ('deleteonly' if self.args.deleteonly else 'reload' if self.args.reload else 'load')
        self.logger.debug('Starting mode=({}), pid={}, uid={}({})'.format(mode, os.getpid(), os.geteuid(), pwd.getpwuid(os.geteuid()).pw_name))

        self.BATCH_UUID = uuid.UUID(self.args.batch)

        for c in ['DB_URL', 'DB_USER', 'DB_PASS', 'DB_TABLE']:
            if not self.config.get(c):
                self.logger.error('Missing config "{}"'.format(c))
                self.exit(1)

        self.DB_CURSOR = self.db_connect(self.config['DB_URL'], self.config['DB_USER'], self.config['DB_PASS'])
        self.DB_CURSOR.execute('SELECT oid, typname FROM pg_catalog.pg_type where typname in (\'char\', \'varchar\')')
        # Column types that we will truncate to the defined length
        self.DB_MAXTYPES = { int(oid): typename for oid, typename in self.DB_CURSOR.fetchall() }
        self.DB_CURSOR.execute('SELECT * FROM {} LIMIT 0'.format(self.config['DB_TABLE']))
        self.DB_COLS = [desc[0] for desc in self.DB_CURSOR.description]
        # Columns names and the length we will truncate to
        self.DB_COLMAX = {}
        for col in self.DB_CURSOR.description:
            if col.type_code in self.DB_MAXTYPES:
                self.DB_COLMAX[col.name] = col.internal_size

        if self.args.reload or self.args.deleteonly:
            self.DB_CURSOR.execute('DELETE FROM {} WHERE batch_uuid = \'{}\''.format(self.config['DB_TABLE'], str(self.BATCH_UUID)))
            self.logger.info('Deleted batch={} rows={}'.format(str(self.BATCH_UUID), self.DB_CURSOR.rowcount))
            self.ROWS_BEFORE = 0
        else:
            self.DB_CURSOR.execute('SELECT count(*) FROM {} WHERE batch_uuid = \'{}\''.format(self.config['DB_TABLE'], str(self.BATCH_UUID)))
            self.ROWS_BEFORE = self.DB_CURSOR.fetchone()[0]

        if self.args.deleteonly:
            self.exit(0)
            
        if self.args.verbose:
            self.logger.debug('Before load batch={} has rows={}'.format(str(self.BATCH_UUID), self.ROWS_BEFORE))

        if self.args.file:
            if self.args.file[-3:] == '.gz':
                self.IN_FD = gzip.open(self.args.file, mode='rt')
            else:
                self.IN_FD = open(self.args.file, mode='r')
        else:
            self.IN_FD = sys.stdin
       
        self.IN_READER = csv.DictReader(self.IN_FD, delimiter=',', quotechar='|')
        if not self.IN_READER.fieldnames:
            if self.IN_READER.line_num == 0:
                self.logger.info('Input file empty')
                self.exit(0)
            else:
                self.logger.error('Input file is missing CSV fields in first row')
                self.exit(1)

        # Minimum required fields
        for field in ['USED_COMPONENT', 'USE_TIMESTAMP', 'USE_CLIENT']:
            if field not in self.IN_READER.fieldnames:
                self.logger.error('Input file is missing CSV field: {}'.format(field))
                self.exit(1)
 
        self.CSV_TO_DB_COLMAP = {}  # CSV columns that go in normal fields
        self.CSV_TO_DB_OTHMAP = {}  # CSV columns that go in other_fields_json
        for infld in self.IN_READER.fieldnames:
            for outfld in self.DB_COLS:
                if infld.lower() == outfld.lower():
                    self.CSV_TO_DB_COLMAP[infld] = outfld
                    break
            else:                   # Column isn't in the DB, will be in other with lower fieldname
                self.CSV_TO_DB_OTHMAP[infld] = outfld.lower()
        self.logger.debug('Columns mapped={}, other={}'.format(len(self.CSV_TO_DB_COLMAP), len(self.CSV_TO_DB_OTHMAP)))
        
        self.USER_ANONYMOUS_EQUIV = ['local:anonymous']         # Values that represent 'anonymous user'
        self.USER_ANONYMOUS_VALUE = 'n/a'                       # Value that null/none/empty and the above EQUIV are replaced with

    def db_connect(self, url, username, password):
        idx = url.find(':')
        if idx <= 0:
            self.logger.error('Database URL is not valid')
            self.exit(1)

        (type, obj) = (url[0:idx], url[idx+1:])
        if type not in ['postgresql']:
            self.logger.error('Database URL is not valid')
            self.exit(1)

        if obj[0:2] != '//':
            self.logger.error('Database URL is not valid')
            self.exit(1)

        obj = obj[2:]
        idx = obj.find('/')
        if idx <= 0:
            self.logger.error('Database URL is not valid')
            self.exit(1)
        (host, path) = (obj[0:idx], obj[idx+1:])
        idx = host.find(':')
        if idx > 0:
            port = host[idx+1:]
            host = host[:idx]
        elif type == 'postgresql':
            port = '5432'
        else:
            port = '5432'

        # Define our connection string
        conn_string = "host='{}' port='{}' dbname='{}' user='{}' password='{}'".format(host, port, path, username, password)

        # get a connection, if a connect cannot be made an exception will be raised here
        conn = psycopg2.connect(conn_string)
        conn.set_session(autocommit=True)

        # conn.cursor will return a cursor object, you can use this cursor to perform queries
        cursor = conn.cursor()

        # call this once before working with UUID objects in PostgreSQL
        psycopg2.extras.register_uuid()

        self.logger.debug('Connected to PostgreSQL database={} as user={}'.format(path, self.config['DB_USER']))
        return(cursor)

    def Load(self):
        self.start_ts = datetime.utcnow()
        INPUT = self.IN_READER
        OUTPUT = self.DB_CURSOR
        cols = list(self.CSV_TO_DB_COLMAP.values())             # The columns we are writing to the database
        cols.append('batch_uuid')                               # A column we are adding that doesn't exist in the input
        if 'use_user' not in cols:
            cols.append('use_user')                             # A column we are adding if it's not in the input
        if self.CSV_TO_DB_OTHMAP:                               # We have other fields in the CSV
            cols.append('other_fields_json')
        cols_string = ','.join(cols)
        ssss_string = ','.join( ['%s' for i in range(len(cols))] )
        SQL = 'INSERT INTO {} ({}) values ({});'.format(self.config['DB_TABLE'], cols_string, ssss_string)
        out_list = list()
        for row in INPUT:
            write_dict = {'batch_uuid': self.BATCH_UUID,            # Add to all rows
                        'use_user': self.USER_ANONYMOUS_VALUE}      # Set in case input doesn't have it
            for csvfield, dbfield in self.CSV_TO_DB_COLMAP.items():
                if dbfield in self.DB_COLMAX and len(row.get(csvfield)) > self.DB_COLMAX[dbfield]:
                    write_dict[dbfield] = row.get(csvfield)[:self.DB_COLMAX[dbfield]]
                    self.logger.info('Truncated field={}'.format(csvfield))
                # Null/none/empty or in EQUIV list
                elif dbfield == 'use_user' and (not row.get(csvfield) or \
                        row.get(csvfield, '') in self.USER_ANONYMOUS_EQUIV):
                    write_dict[dbfield] = self.USER_ANONYMOUS_VALUE
                else:
                    write_dict[dbfield] = row.get(csvfield)
            if self.CSV_TO_DB_OTHMAP:
                other_dict = {}
                for field in self.CSV_TO_DB_OTHMAP:
                    other_dict[self.CSV_TO_DB_OTHMAP[field]] = row.get(field)
                write_dict['other_fields_json'] = json.dumps(other_dict)

            vals = tuple( write_dict[field] for field in cols )
            out_list.append(vals)
            if len(out_list) >= 99:
                psycopg2.extras.execute_batch(OUTPUT, SQL, out_list)
                self.ROWS_AFTER += len(out_list)
                out_list = list()

        # What's left after the last input
        if len(out_list) > 0:
            psycopg2.extras.execute_batch(OUTPUT, SQL, out_list)
            self.ROWS_AFTER += len(out_list)
            out_list = list()

        self.end_ts = datetime.utcnow()
        seconds = (self.end_ts - self.start_ts).total_seconds()
        rate = self.ROWS_AFTER / seconds
        self.logger.info('Loaded batch={} rows={} seconds={} rate={} rows/second'.format(
            str(self.BATCH_UUID), self.ROWS_AFTER, round(seconds, 2), round(rate, 0) ))

    def exit_signal(self, signum, frame):
        self.logger.critical('Caught signal={}({}), exiting with rc={}'.format(signum, signal.Signals(signum).name, signum))
        self.exit(signum)

    def exit(self, rc = 0):
        if self.IN_FD:
            self.IN_FD.close()
        print('ROWS: {}'.format(self.ROWS_AFTER))
        print('STATUS: {}'.format(rc))
        sys.exit(rc)

if __name__ == '__main__':
    me = DBLoad()
    me.Setup()
    me.Load()
    me.exit(0)
